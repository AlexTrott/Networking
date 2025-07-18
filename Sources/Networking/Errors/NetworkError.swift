import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case invalidRequest
    case noData
    case decodingFailed(Error)
    case encodingFailed(Error)
    case httpError(HTTPError)
    case connectionError(URLError)
    case certificatePinningFailed
    case timeout
    case cancelled
    case unknown(Error)
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidRequest, .invalidRequest),
             (.noData, .noData),
             (.certificatePinningFailed, .certificatePinningFailed),
             (.timeout, .timeout),
             (.cancelled, .cancelled):
            return true
        case let (.decodingFailed(lhsError), .decodingFailed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case let (.encodingFailed(lhsError), .encodingFailed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case let (.httpError(lhsError), .httpError(rhsError)):
            return lhsError == rhsError
        case let (.connectionError(lhsError), .connectionError(rhsError)):
            return lhsError == rhsError
        case let (.unknown(lhsError), .unknown(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

public struct HTTPError: Error, Equatable, Sendable {
    public let statusCode: Int
    public let data: Data?
    public let response: HTTPURLResponse?
    
    public init(statusCode: Int, data: Data? = nil, response: HTTPURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.response = response
    }
    
    public var isClientError: Bool {
        return (400...499).contains(statusCode)
    }
    
    public var isServerError: Bool {
        return (500...599).contains(statusCode)
    }
    
    public var isUnauthorized: Bool {
        return statusCode == 401
    }
    
    public var isForbidden: Bool {
        return statusCode == 403
    }
    
    public var isNotFound: Bool {
        return statusCode == 404
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .invalidRequest:
            return "The request is invalid"
        case .noData:
            return "No data received"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .httpError(let httpError):
            return "HTTP error with status code: \(httpError.statusCode)"
        case .connectionError(let urlError):
            return "Connection error: \(urlError.localizedDescription)"
        case .certificatePinningFailed:
            return "Certificate pinning validation failed"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}