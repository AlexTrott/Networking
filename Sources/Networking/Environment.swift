import Foundation

public enum Environment: String, CaseIterable, Sendable {
    case development
    case staging
    case production
    
    public var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "https://dev-api.example.com")!
        case .staging:
            return URL(string: "https://staging-api.example.com")!
        case .production:
            return URL(string: "https://api.example.com")!
        }
    }
    
    public var certificatePins: [String: [String]] {
        switch self {
        case .development:
            return [
                "dev-api.example.com": [
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                    "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
                ]
            ]
        case .staging:
            return [
                "staging-api.example.com": [
                    "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=",
                    "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="
                ]
            ]
        case .production:
            return [
                "api.example.com": [
                    "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE=",
                    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF="
                ]
            ]
        }
    }
    
    public var allowsInsecureConnections: Bool {
        switch self {
        case .development:
            return true
        case .staging, .production:
            return false
        }
    }
}