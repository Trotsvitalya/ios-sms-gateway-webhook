import Foundation

public struct ForwardingRule: Identifiable, Codable, Equatable {
    public var id: UUID
    public var sender: String
    public var isSenderRegex: Bool
    public var smsFilter: String
    public var url: String
    public var template: String
    public var headers: String
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        sender: String = "",
        isSenderRegex: Bool = false,
        smsFilter: String = "",
        url: String = "",
        template: String = ForwardingRule.defaultTemplate,
        headers: String = ForwardingRule.defaultHeaders,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.sender = sender
        self.isSenderRegex = isSenderRegex
        self.smsFilter = smsFilter
        self.url = url
        self.template = template
        self.headers = headers
        self.isEnabled = isEnabled
    }

    public static let defaultTemplate = """
    {
      "from": "%from%",
      "text": "%text%",
      "sentStamp": %sentStamp%,
      "receivedStamp": %receivedStamp%,
      "sim": "%sim%"
    }
    """

    public static let defaultHeaders = """
    {"User-agent": "SMS Forwarder iOS App"}
    """

    public func matches(sender incomingSender: String, text incomingText: String) -> Bool {
        guard isEnabled else { return false }

        // Перевірка відправника
        let trimmedSender = sender.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSender.isEmpty && trimmedSender != "*" {
            if isSenderRegex {
                if let regex = try? NSRegularExpression(pattern: trimmedSender, options: [.caseInsensitive]) {
                    let range = NSRange(location: 0, length: incomingSender.utf16.count)
                    if regex.firstMatch(in: incomingSender, options: [], range: range) == nil {
                        return false
                    }
                } else {
                    return false
                }
            } else {
                if !incomingSender.localizedCaseInsensitiveContains(trimmedSender) {
                    return false
                }
            }
        }

        // Перевірка фільтру тексту SMS
        let trimmedFilter = smsFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFilter.isEmpty {
            if !incomingText.localizedCaseInsensitiveContains(trimmedFilter) {
                return false
            }
        }

        return true
    }
}
