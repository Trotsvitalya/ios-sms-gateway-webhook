import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case ukrainian = "uk"

    public var id: String { self.rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .ukrainian: return "Українська"
        }
    }
}

public class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()

    @AppStorage("selected_app_language") public var currentLanguage: String = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.starts(with: "uk") ? "uk" : "en"
    }()

    private init() {}

    public func localized(_ key: LocalizedKey) -> String {
        let isUk = currentLanguage == "uk"
        switch key {
        // Tabs
        case .tabRules: return isUk ? "Правила" : "Rules"
        case .tabLogs: return isUk ? "Журнал" : "Logs"
        case .tabInfo: return isUk ? "Інфо" : "Info"

        // Status
        case .serviceActive: return isUk ? "Сервіс активний" : "Service Active"
        case .serviceStopped: return isUk ? "Сервіс зупинено" : "Service Stopped"
        case .serviceRunningSubtitle: return isUk ? "Відстежує вхідні SMS у фоні" : "Monitoring incoming SMS in background"
        case .serviceTapToStart: return isUk ? "Натисніть для запуску" : "Tap switch to start"
        case .dbUnavailableTitle: return isUk ? "База SMS недоступна" : "SMS Database Unavailable"
        case .dbUnavailableMessage: return isUk ? "Переконайтеся, що додаток встановлено через TrollStore з дозволом no-sandbox." : "Make sure the app is installed via TrollStore with no-sandbox entitlement."

        // Rules Section
        case .forwardingRulesHeader: return isUk ? "Правила пересилання" : "Forwarding Rules"
        case .noRules: return isUk ? "Немає налаштованих правил. Натисніть +, щоб додати." : "No forwarding rules configured. Tap + to add."
        case .allSenders: return isUk ? "Всі відправники (*)" : "All Senders (*)"

        // Rule Edit
        case .ruleNewTitle: return isUk ? "Нове правило" : "New Rule"
        case .ruleEditTitle: return isUk ? "Редагування правила" : "Edit Rule"
        case .senderSection: return isUk ? "Відправник" : "Sender"
        case .senderPlaceholder: return isUk ? "Номер або * для всіх" : "Phone number or * for all"
        case .regexToggle: return isUk ? "Регулярний вираз (RegEx)" : "Regular Expression (RegEx)"
        case .smsFilterSection: return isUk ? "Фільтр тексту SMS (необов'язково)" : "SMS Text Filter (optional)"
        case .smsFilterPlaceholder: return isUk ? "Фільтр підрядка в SMS" : "Substring match in SMS"
        case .webhookUrlSection: return isUk ? "Webhook URL" : "Webhook URL"
        case .jsonTemplateSection: return isUk ? "JSON Шаблон" : "JSON Template"
        case .variablesHint: return isUk ? "Змінні: %from%, %text%, %sentStamp%, %receivedStamp%, %sim%" : "Variables: %from%, %text%, %sentStamp%, %receivedStamp%, %sim%"
        case .headersSection: return isUk ? "HTTP Заголовки (JSON)" : "HTTP Headers (JSON)"
        case .sendTestButton: return isUk ? "Надіслати тестове SMS на цей URL" : "Send Test SMS to this URL"
        case .cancel: return isUk ? "Скасувати" : "Cancel"
        case .save: return isUk ? "Зберегти" : "Save"

        // Logs
        case .logsTitle: return isUk ? "Журнал" : "Logs"
        case .logsEmpty: return isUk ? "Журнал порожній" : "Logs are empty"
        case .clearLogs: return isUk ? "Очистити" : "Clear"

        // Info
        case .infoAboutHeader: return isUk ? "Про програму" : "About App"
        case .appNameLabel: return isUk ? "Назва" : "App Name"
        case .appNameValue: return "SMS Gateway iOS"
        case .compatLabel: return isUk ? "Сумісність" : "Compatibility"
        case .compatValue: return "iOS 15 – 16 (TrollStore)"
        case .dbStatusLabel: return isUk ? "База даних" : "Database"
        case .dbConnected: return isUk ? "Підключено" : "Connected"
        case .dbDisconnected: return isUk ? "Недоступно" : "Disconnected"
        case .howItWorksHeader: return isUk ? "Як це працює" : "How It Works"
        case .howItWorksDescription: return isUk ? 
            "Додаток працює у фоновому режимі та зчитує нові SMS напряму з бази даних iOS /var/mobile/Library/SMS/sms.db, після чого миттєво відправляє їх на вказаний Webhook URL." : 
            "The app runs in the background 24/7, monitors incoming messages directly from /var/mobile/Library/SMS/sms.db, and instantly forwards them to your configured Webhook URL."
        case .languageHeader: return isUk ? "Мова інтерфейсу" : "Interface Language"
        }
    }
}

public enum LocalizedKey {
    case tabRules, tabLogs, tabInfo
    case serviceActive, serviceStopped, serviceRunningSubtitle, serviceTapToStart
    case dbUnavailableTitle, dbUnavailableMessage
    case forwardingRulesHeader, noRules, allSenders
    case ruleNewTitle, ruleEditTitle, senderSection, senderPlaceholder, regexToggle
    case smsFilterSection, smsFilterPlaceholder, webhookUrlSection, jsonTemplateSection, variablesHint, headersSection, sendTestButton, cancel, save
    case logsTitle, logsEmpty, clearLogs
    case infoAboutHeader, appNameLabel, appNameValue, compatLabel, compatValue, dbStatusLabel, dbConnected, dbDisconnected, howItWorksHeader, howItWorksDescription, languageHeader
}
