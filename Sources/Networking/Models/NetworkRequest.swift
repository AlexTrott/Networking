import Foundation

public struct NetworkRequest: Sendable {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    public let timeoutInterval: TimeInterval
    
    public init(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutInterval: TimeInterval = 60.0
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
    }
    
    public func toURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = body
        return request
    }
}

public extension NetworkRequest {
    static func get(
        url: URL,
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = 60.0
    ) -> NetworkRequest {
        return NetworkRequest(
            url: url,
            method: .GET,
            headers: headers,
            timeoutInterval: timeoutInterval
        )
    }
    
    static func post(
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutInterval: TimeInterval = 60.0
    ) -> NetworkRequest {
        return NetworkRequest(
            url: url,
            method: .POST,
            headers: headers,
            body: body,
            timeoutInterval: timeoutInterval
        )
    }
    
    static func put(
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutInterval: TimeInterval = 60.0
    ) -> NetworkRequest {
        return NetworkRequest(
            url: url,
            method: .PUT,
            headers: headers,
            body: body,
            timeoutInterval: timeoutInterval
        )
    }
    
    static func delete(
        url: URL,
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = 60.0
    ) -> NetworkRequest {
        return NetworkRequest(
            url: url,
            method: .DELETE,
            headers: headers,
            timeoutInterval: timeoutInterval
        )
    }
}