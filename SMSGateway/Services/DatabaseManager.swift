import Foundation
import SQLite3

public struct SMSMessage {
    public let rowId: Int64
    public let sender: String
    public let text: String
    public let dateTimestamp: Int64 // Unix timestamp in milliseconds
    public let service: String
}

public class DatabaseManager {
    public static let shared = DatabaseManager()
    private let dbPath = "/var/mobile/Library/SMS/sms.db"

    private init() {}

    /// Перевіряє чи доступна системна база даних SMS
    public func isDatabaseAccessible() -> Bool {
        return FileManager.default.isReadableFile(atPath: dbPath)
    }

    /// Отримує максимальний існуючий ROWID
    public func fetchLatestRowId() -> Int64 {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }

        var statement: OpaquePointer?
        let query = "SELECT MAX(ROWID) FROM message"
        var maxId: Int64 = 0

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                maxId = sqlite3_column_int64(statement, 0)
            }
        }
        sqlite3_finalize(statement)
        return maxId
    }

    /// Вибирає нові вхідні повідомлення з ROWID > afterRowId
    public func fetchNewMessages(afterRowId: Int64) -> [SMSMessage] {
        var messages: [SMSMessage] = []
        var db: OpaquePointer?

        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_close(db) }

        let query = """
        SELECT 
            message.ROWID, 
            handle.id, 
            message.text, 
            message.date, 
            message.service, 
            message.attributedBody 
        FROM message 
        LEFT JOIN handle ON message.handle_id = handle.ROWID 
        WHERE message.is_from_me = 0 AND message.ROWID > ? 
        ORDER BY message.ROWID ASC
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, afterRowId)

        while sqlite3_step(statement) == SQLITE_ROW {
            let rowId = sqlite3_column_int64(statement, 0)

            // Відправник
            var sender = "Unknown"
            if let cSender = sqlite3_column_text(statement, 1) {
                sender = String(cString: cSender)
            }

            // Текст повідомлення
            var messageText = ""
            if let cText = sqlite3_column_text(statement, 2) {
                messageText = String(cString: cText)
            }

            // Дата (в iOS зберігається в наносекундах відносно 2001-01-01 Cocoa epoch)
            let rawDate = sqlite3_column_int64(statement, 3)
            let unixTimestampMs: Int64
            if rawDate > 1_000_000_000_000_000 {
                // Наносекунди (iOS 11+)
                let seconds = Double(rawDate) / 1_000_000_000.0
                let unixSeconds = seconds + 978307200.0 // 2001-01-01 offset
                unixTimestampMs = Int64(unixSeconds * 1000.0)
            } else if rawDate > 0 {
                let unixSeconds = Double(rawDate) + 978307200.0
                unixTimestampMs = Int64(unixSeconds * 1000.0)
            } else {
                unixTimestampMs = Int64(Date().timeIntervalSince1970 * 1000.0)
            }

            // Сервіс (SMS або iMessage)
            var service = "SMS"
            if let cService = sqlite3_column_text(statement, 4) {
                service = String(cString: cService)
            }

            // Обробка iOS 16 attributedBody, якщо text порожній
            if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let blob = sqlite3_column_blob(statement, 5) {
                    let length = sqlite3_column_bytes(statement, 5)
                    let data = Data(bytes: blob, count: Int(length))
                    if let parsed = extractTextFromAttributedBody(data) {
                        messageText = parsed
                    }
                }
            }

            messages.append(SMSMessage(
                rowId: rowId,
                sender: sender,
                text: messageText,
                dateTimestamp: unixTimestampMs,
                service: service
            ))
        }

        return messages
    }

    /// Розпакування тексту з attributedBody (для iOS 16)
    private func extractTextFromAttributedBody(_ data: Data) -> String? {
        // Спроба розпакувати через NSKeyedUnarchiver
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSAttributedString.self, NSString.self], from: data) as? NSAttributedString {
            return unarchived.string
        }

        // Евристичний fallback: пошук підрядка NSString у бінарному блобі
        if let raw = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
            if let range = raw.range(of: "NSString") {
                let suffix = raw[range.upperBound...]
                // Знаходимо фрагмент читабельного тексту
                let parts = suffix.components(separatedBy: CharacterSet.controlCharacters)
                for part in parts {
                    let cleaned = part.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned.count >= 2 && !cleaned.contains("NSDictionary") {
                        return cleaned
                    }
                }
            }
        }
        return nil
    }
}
