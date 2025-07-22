import Foundation
import NetworkingInterface



public final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor {
    private let logger: NetworkLogger
    
    public init(logger: NetworkLogger = DefaultNetworkLogger()) {
        self.logger = logger
    }
    
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        logger.logRequest(request)
        return request
    }
    
    public func intercept(response: NetworkResponse, for request: NetworkRequest) async throws -> NetworkResponse {
        logger.logResponse(response, for: request)
        return response
    }
}

public final class AuthenticationInterceptor: RequestInterceptor {
    private let tokenProvider: @Sendable () async -> String?
    
    public init(tokenProvider: @escaping @Sendable () async -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        guard let token = await tokenProvider() else {
            return request
        }
        
        var headers = request.headers
        headers["Authorization"] = "Bearer \(token)"
        
        return NetworkRequest(
            url: request.url,
            method: request.method,
            headers: headers,
            body: request.body,
            timeoutInterval: request.timeoutInterval
        )
    }
}

public final class UserAgentInterceptor: RequestInterceptor {
    private let userAgent: String
    
    public init(userAgent: String) {
        self.userAgent = userAgent
    }
    
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        var headers = request.headers
        headers["User-Agent"] = userAgent
        
        return NetworkRequest(
            url: request.url,
            method: request.method,
            headers: headers,
            body: request.body,
            timeoutInterval: request.timeoutInterval
        )
    }
}
