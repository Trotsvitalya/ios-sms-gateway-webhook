import Foundation

public struct LogEntry: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let sender: String
    public let message: String
    public let targetUrl: String
    public let status: String
    public let isSuccess: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sender: String,
        message: String,
        targetUrl: String,
        status: String,
        isSuccess: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sender = sender
        self.message = message
        self.targetUrl = targetUrl
        self.status = status
        self.isSuccess = isSuccess
    }
}
