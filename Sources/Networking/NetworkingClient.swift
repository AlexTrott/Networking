import Foundation

public protocol NetworkingClientProtocol: Sendable {
    func perform(_ request: NetworkRequest) async throws -> NetworkResponse
    func get<T: Decodable>(_ type: T.Type, from url: URL, headers: [String: String]) async throws -> T
    func post<T: Decodable>(_ type: T.Type, to url: URL, body: Data?, headers: [String: String]) async throws -> T
    func put<T: Decodable>(_ type: T.Type, to url: URL, body: Data?, headers: [String: String]) async throws -> T
    func delete(from url: URL, headers: [String: String]) async throws -> NetworkResponse
}

public final class NetworkingClient: NetworkingClientProtocol {
    private let environment: Environment
    private let sessionManager: URLSessionManager
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let decoder: JSONDecoder
    
    public init(
        environment: Environment,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        decoder: JSONDecoder = JSONDecoder(),
        certificatePinningEnabled: Bool = true
    ) {
        self.environment = environment
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.decoder = decoder
        
        let certificatePinning = CertificatePinning(environment: environment)
        self.sessionManager = URLSessionManager(
            certificatePinning: certificatePinning,
            certificatePinningEnabled: certificatePinningEnabled
        )
    }
    
    public func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
        var interceptedRequest = request
        
        for interceptor in requestInterceptors {
            interceptedRequest = try await interceptor.intercept(request: interceptedRequest)
        }
        
        var response = try await sessionManager.perform(interceptedRequest)
        
        for interceptor in responseInterceptors {
            response = try await interceptor.intercept(response: response, for: interceptedRequest)
        }
        
        return response
    }
    
    public func get<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> T {
        let request = NetworkRequest.get(url: url, headers: headers)
        let response = try await perform(request)
        
        do {
            return try response.decode(type, using: decoder)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    public func post<T: Decodable>(
        _ type: T.Type,
        to url: URL,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        var postHeaders = headers
        if body != nil && postHeaders["Content-Type"] == nil {
            postHeaders["Content-Type"] = "application/json"
        }
        
        let request = NetworkRequest.post(url: url, headers: postHeaders, body: body)
        let response = try await perform(request)
        
        do {
            return try response.decode(type, using: decoder)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    public func put<T: Decodable>(
        _ type: T.Type,
        to url: URL,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        var putHeaders = headers
        if body != nil && putHeaders["Content-Type"] == nil {
            putHeaders["Content-Type"] = "application/json"
        }
        
        let request = NetworkRequest.put(url: url, headers: putHeaders, body: body)
        let response = try await perform(request)
        
        do {
            return try response.decode(type, using: decoder)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    public func delete(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> NetworkResponse {
        let request = NetworkRequest.delete(url: url, headers: headers)
        return try await perform(request)
    }
}

public extension NetworkingClient {
    func get<T: Decodable>(_ type: T.Type, path: String, headers: [String: String] = [:]) async throws -> T {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await get(type, from: url, headers: headers)
    }
    
    func post<T: Decodable>(_ type: T.Type, path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await post(type, to: url, body: body, headers: headers)
    }
    
    func put<T: Decodable>(_ type: T.Type, path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await put(type, to: url, body: body, headers: headers)
    }
    
    func delete(path: String, headers: [String: String] = [:]) async throws -> NetworkResponse {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await delete(from: url, headers: headers)
    }
}