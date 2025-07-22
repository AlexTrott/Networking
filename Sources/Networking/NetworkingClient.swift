import Foundation
import NetworkingInterface

public final class NetworkingClient: NetworkingClientProtocol {
    private let environment: NetworkingEnvironment
    private let sessionManager: NetworkingSessionManagerProtocol
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let decoder: JSONDecoder
    
    public init(
        environment: NetworkingEnvironment,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        decoder: JSONDecoder = JSONDecoder(),
        sessionManager: NetworkingSessionManagerProtocol? = nil,
        certificatePinningEnabled: Bool = true,
        trustKit: TrustKitProtocol? = nil
    ) {
        self.environment = environment
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.decoder = decoder
        
        if let sessionManager = sessionManager {
            self.sessionManager = sessionManager
        } else {
            let certificatePinning: CertificatePinningProtocol
            if let trustKit = trustKit {
                certificatePinning = CertificatePinning(environment: environment, trustKit: trustKit)
            } else {
                certificatePinning = CertificatePinning(environment: environment)
            }
            
            self.sessionManager = NetworkingSessionManager(
                certificatePinning: certificatePinning,
                certificatePinningEnabled: certificatePinningEnabled
            )
        }
    }

    public func get<T: Decodable>(_ type: T.Type, path: String, headers: [String: String] = [:]) async throws -> T {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await get(type, from: url, headers: headers)
    }

    public func post<T: Decodable>(_ type: T.Type, path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await post(type, to: url, body: body, headers: headers)
    }

    public func put<T: Decodable>(_ type: T.Type, path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await put(type, to: url, body: body, headers: headers)
    }

    public func delete(path: String, headers: [String: String] = [:]) async throws -> NetworkResponse {
        let url = environment.baseURL.appendingPathComponent(path)
        return try await delete(from: url, headers: headers)
    }
}

private extension NetworkingClient {
    func get<T: Decodable>(
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

    func post<T: Decodable>(
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

    func put<T: Decodable>(
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

    func delete(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> NetworkResponse {
        let request = NetworkRequest.delete(url: url, headers: headers)
        return try await perform(request)
    }

    func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
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
}
