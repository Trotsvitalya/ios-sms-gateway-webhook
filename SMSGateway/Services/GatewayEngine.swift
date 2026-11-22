import Foundation
import Combine
import SwiftUI

public class GatewayEngine: ObservableObject {
    public static let shared = GatewayEngine()

    @Published public var isRunning: Bool = false
    @Published public var rules: [ForwardingRule] = []
    @Published public var logs: [LogEntry] = []
    @Published public var isDbAvailable: Bool = false

    private var timer: AnyCancellable?
    private let rulesStorageKey = "saved_forwarding_rules"
    private let lastRowIdKey = "last_processed_row_id"
    private let logsStorageKey = "saved_gateway_logs"

    private init() {
        loadRules()
        loadLogs()
        checkDatabaseStatus()

        // Якщо в UserDefaults ще немає збереженого ID, ініціалізуємо поточним максимумом
        if UserDefaults.standard.object(forKey: lastRowIdKey) == nil {
            let maxId = DatabaseManager.shared.fetchLatestRowId()
            UserDefaults.standard.set(maxId, forKey: lastRowIdKey)
        }
    }

    public func checkDatabaseStatus() {
        self.isDbAvailable = DatabaseManager.shared.isDatabaseAccessible()
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        BackgroundKeeper.shared.start()

        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pollDatabase()
            }

        appendLog(
            sender: "System",
            message: "Сервіс шлюзу активовано",
            targetUrl: "-",
            status: "Running",
            isSuccess: true
        )
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false

        timer?.cancel()
        timer = nil

        BackgroundKeeper.shared.stop()

        appendLog(
            sender: "System",
            message: "Сервіс шлюзу зупинено",
            targetUrl: "-",
            status: "Stopped",
            isSuccess: false
        )
    }

    private func pollDatabase() {
        let lastId = Int64(UserDefaults.standard.integer(forKey: lastRowIdKey))
        let newMessages = DatabaseManager.shared.fetchNewMessages(afterRowId: lastId)

        guard !newMessages.isEmpty else { return }

        var currentMaxId = lastId

        for msg in newMessages {
            if msg.rowId > currentMaxId {
                currentMaxId = msg.rowId
            }

            // Перевіряємо всі активні правила
            for rule in rules where rule.isEnabled {
                if rule.matches(sender: msg.sender, text: msg.text) {
                    forwardMessage(msg, rule: rule)
                }
            }
        }

        UserDefaults.standard.set(currentMaxId, forKey: lastRowIdKey)
    }

    private func forwardMessage(_ msg: SMSMessage, rule: ForwardingRule) {
        guard let url = URL(string: rule.url), !rule.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appendLog(
                sender: msg.sender,
                message: msg.text,
                targetUrl: rule.url,
                status: "Невірний URL",
                isSuccess: false
            )
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15

        // Парсинг кастомних заголовків
        var appliedHeaders = ["Content-Type": "application/json; charset=utf-8"]
        if let headersData = rule.headers.data(using: .utf8),
           let jsonHeaders = try? JSONSerialization.jsonObject(with: headersData) as? [String: String] {
            for (key, val) in jsonHeaders {
                appliedHeaders[key] = val
            }
        }
        for (key, val) in appliedHeaders {
            request.setValue(val, forHTTPHeaderField: key)
        }

        // Формування JSON тіла
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)
        let escapedFrom = escapeJsonString(msg.sender)
        let escapedText = escapeJsonString(msg.text)
        let simSlot = msg.service

        // Читабельні дата та час
        let dateObj = Date(timeIntervalSince1970: Double(msg.dateTimestamp) / 1000.0)
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        let readableDate = df.string(from: dateObj)

        let tf = DateFormatter()
        tf.dateFormat = "HH:mm:ss"
        let readableTime = tf.string(from: dateObj)

        let dtf = DateFormatter()
        dtf.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let readableDateTime = dtf.string(from: dateObj)

        var bodyString = rule.template
        bodyString = bodyString.replacingOccurrences(of: "%from%", with: escapedFrom)
        bodyString = bodyString.replacingOccurrences(of: "%text%", with: escapedText)
        bodyString = bodyString.replacingOccurrences(of: "%time%", with: readableTime)
        bodyString = bodyString.replacingOccurrences(of: "%date%", with: readableDate)
        bodyString = bodyString.replacingOccurrences(of: "%datetime%", with: readableDateTime)
        bodyString = bodyString.replacingOccurrences(of: "%sentStamp%", with: String(msg.dateTimestamp))
        bodyString = bodyString.replacingOccurrences(of: "%receivedStamp%", with: String(nowMs))
        bodyString = bodyString.replacingOccurrences(of: "%sim%", with: simSlot)

        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    let success = (200...299).contains(httpResponse.statusCode)
                    self?.appendLog(
                        sender: msg.sender,
                        message: msg.text,
                        targetUrl: rule.url,
                        status: "HTTP \(httpResponse.statusCode)",
                        isSuccess: success
                    )
                } else if let error = error {
                    self?.appendLog(
                        sender: msg.sender,
                        message: msg.text,
                        targetUrl: rule.url,
                        status: error.localizedDescription,
                        isSuccess: false
                    )
                }
            }
        }.resume()
    }

    public func sendTest(rule: ForwardingRule) {
        let testMessage = SMSMessage(
            rowId: 0,
            sender: "TestSender",
            text: "Це тестове повідомлення з iOS SMS Gateway!",
            dateTimestamp: Int64(Date().timeIntervalSince1970 * 1000.0),
            service: "SMS"
        )
        forwardMessage(testMessage, rule: rule)
    }

    public func appendLog(sender: String, message: String, targetUrl: String, status: String, isSuccess: Bool) {
        let entry = LogEntry(
            sender: sender,
            message: message,
            targetUrl: targetUrl,
            status: status,
            isSuccess: isSuccess
        )
        logs.insert(entry, at: 0)
        if logs.count > 100 {
            logs.removeLast()
        }
        saveLogs()
    }

    public func clearLogs() {
        logs.removeAll()
        saveLogs()
    }

    // MARK: - Persistence
    public func saveRules() {
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: rulesStorageKey)
        }
    }

    private func loadRules() {
        if let data = UserDefaults.standard.data(forKey: rulesStorageKey),
           let decoded = try? JSONDecoder().decode([ForwardingRule].self, from: data) {
            self.rules = decoded
        } else {
            // Створюємо дефолтне правило
            self.rules = [
                ForwardingRule(
                    sender: "*",
                    isSenderRegex: false,
                    smsFilter: "",
                    url: "https://your-webhook-service.com/api/sms",
                    isEnabled: true
                )
            ]
        }
    }

    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: logsStorageKey)
        }
    }

    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: logsStorageKey),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            self.logs = decoded
        }
    }

    private func escapeJsonString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
