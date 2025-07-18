import Foundation

public struct NetworkResponse: Sendable {
    public let data: Data
    public let statusCode: Int
    public let headers: [String: String]
    public let url: URL?
    
    public init(data: Data, statusCode: Int, headers: [String: String], url: URL?) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.url = url
    }
    
    public var isSuccessful: Bool {
        return (200...299).contains(statusCode)
    }
    
    public var isClientError: Bool {
        return (400...499).contains(statusCode)
    }
    
    public var isServerError: Bool {
        return (500...599).contains(statusCode)
    }
    
    public func decode<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(type, from: data)
    }
    
    public var string: String? {
        return String(data: data, encoding: .utf8)
    }
    
    public var json: Any? {
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
}

extension NetworkResponse {
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.statusCode = response.statusCode
        
        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            if let keyString = key as? String, let valueString = value as? String {
                headers[keyString] = valueString
            }
        }
        self.headers = headers
        self.url = response.url
    }
}