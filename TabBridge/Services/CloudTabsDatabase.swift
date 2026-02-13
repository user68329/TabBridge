import Foundation
import SQLite3

final class CloudTabsDatabase {
    static let defaultPath: String = {
        let containerPath = NSHomeDirectory() + "/Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db"
        if FileManager.default.fileExists(atPath: containerPath) {
            return containerPath
        }
        return NSHomeDirectory() + "/Library/Safari/CloudTabs.db"
    }()

    private let path: String

    init(path: String = CloudTabsDatabase.defaultPath) {
        self.path = path
    }

    // MARK: - Access Check

    func isAccessible() -> Bool {
        FileManager.default.isReadableFile(atPath: path)
    }

    // MARK: - Reading

    func fetchDevicesAndTabs() throws -> ([Device], [Tab]) {
        var db: OpaquePointer?
        let uri = "file:\(path)?mode=ro"
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
        guard sqlite3_open_v2(uri, &db, flags, nil) == SQLITE_OK else {
            let err = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(db)
            throw TabBridgeError.databaseOpen(err)
        }
        defer { sqlite3_close(db) }

        let devices = try queryDevices(db: db!)
        let tabs = try queryTabs(db: db!)
        return (devices, tabs)
    }

    private func queryDevices(db: OpaquePointer) throws -> [Device] {
        let sql = "SELECT device_uuid, device_name, last_modified FROM cloud_tab_devices ORDER BY last_modified DESC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw TabBridgeError.query(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        var devices: [Device] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let uuid = String(cString: sqlite3_column_text(stmt, 0))
            let name = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? "Unknown Device"
            let timestamp = sqlite3_column_double(stmt, 2)
            let date = Date(timeIntervalSinceReferenceDate: timestamp)
            devices.append(Device(id: uuid, name: name, lastModified: date))
        }
        return devices
    }

    private func queryTabs(db: OpaquePointer) throws -> [Tab] {
        let sql = """
            SELECT t.tab_uuid, t.device_uuid, t.title, t.url, t.is_pinned, t.last_viewed_time, t.position
            FROM cloud_tabs t
            JOIN cloud_tab_devices d ON t.device_uuid = d.device_uuid
            ORDER BY d.last_modified DESC
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw TabBridgeError.query(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        var tabs: [Tab] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let uuid = String(cString: sqlite3_column_text(stmt, 0))
            let deviceUUID = String(cString: sqlite3_column_text(stmt, 1))
            let title = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
            let urlString = String(cString: sqlite3_column_text(stmt, 3))
            let isPinned = sqlite3_column_int(stmt, 4) != 0
            let lastViewedTime: Date? = sqlite3_column_type(stmt, 5) != SQLITE_NULL
                ? Date(timeIntervalSinceReferenceDate: sqlite3_column_double(stmt, 5))
                : nil

            var positionSortValue: Int? = nil
            if sqlite3_column_type(stmt, 6) == SQLITE_BLOB,
               let blobPtr = sqlite3_column_blob(stmt, 6) {
                let blobSize = Int(sqlite3_column_bytes(stmt, 6))
                let data = Data(bytes: blobPtr, count: blobSize)
                positionSortValue = Self.extractSortValue(from: data)
            }

            guard let url = URL(string: urlString) else { continue }
            tabs.append(Tab(id: uuid, deviceID: deviceUUID, title: title, url: url, isPinned: isPinned, positionSortValue: positionSortValue, lastViewedTime: lastViewedTime))
        }
        return tabs
    }

    private static func extractSortValue(from data: Data) -> Int? {
        guard let decompressed = try? (data as NSData).decompressed(using: .zlib) as Data else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: decompressed) as? [String: Any],
              let sortValues = json["sortValues"] as? [[String: Any]],
              let first = sortValues.first,
              let sortValue = first["sortValue"] as? Int else {
            return nil
        }
        return sortValue
    }

    // MARK: - Close Tab (Experimental)

    func requestCloseTab(_ tab: Tab) throws {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
            let err = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(db)
            throw TabBridgeError.databaseOpen(err)
        }
        defer { sqlite3_close(db) }

        // Read a system_fields blob from an existing tab to use as a template
        let systemFields = try readTemplateSystemFields(db: db!)

        let sql = """
            INSERT INTO cloud_tab_close_requests
            (close_request_uuid, system_fields, destination_device_uuid, url, tab_uuid)
            VALUES (?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw TabBridgeError.query(String(cString: sqlite3_errmsg(db!)))
        }
        defer { sqlite3_finalize(stmt) }

        let closeUUID = UUID().uuidString
        sqlite3_bind_text(stmt, 1, (closeUUID as NSString).utf8String, -1, nil)
        sqlite3_bind_blob(stmt, 2, (systemFields as NSData).bytes, Int32(systemFields.count), nil)
        sqlite3_bind_text(stmt, 3, (tab.deviceID as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (tab.url.absoluteString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (tab.id as NSString).utf8String, -1, nil)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw TabBridgeError.query(String(cString: sqlite3_errmsg(db!)))
        }
    }

    private func readTemplateSystemFields(db: OpaquePointer) throws -> Data {
        let sql = "SELECT system_fields FROM cloud_tabs LIMIT 1"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw TabBridgeError.query(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw TabBridgeError.noTemplateBlob
        }

        let blobPtr = sqlite3_column_blob(stmt, 0)
        let blobSize = sqlite3_column_bytes(stmt, 0)
        guard let blobPtr, blobSize > 0 else {
            throw TabBridgeError.noTemplateBlob
        }
        return Data(bytes: blobPtr, count: Int(blobSize))
    }
}

enum TabBridgeError: LocalizedError {
    case databaseOpen(String)
    case query(String)
    case noTemplateBlob

    var errorDescription: String? {
        switch self {
        case .databaseOpen(let msg): return "Cannot open database: \(msg)"
        case .query(let msg): return "Query failed: \(msg)"
        case .noTemplateBlob: return "No template system_fields blob found"
        }
    }
}
