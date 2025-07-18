import Testing
import Foundation
@testable import Networking

@Test("LoggingInterceptor request interception")
func testLoggingInterceptorRequestInterception() async throws {
    let logger = NoOpNetworkLogger()
    let interceptor = LoggingInterceptor(logger: logger)
    
    let url = URL(string: "https://api.example.com/test")!
    let originalRequest = NetworkRequest.get(url: url)
    
    let interceptedRequest = try await interceptor.intercept(request: originalRequest)
    
    #expect(interceptedRequest.url == originalRequest.url)
    #expect(interceptedRequest.method == originalRequest.method)
    #expect(interceptedRequest.headers == originalRequest.headers)
}

@Test("LoggingInterceptor response interception")
func testLoggingInterceptorResponseInterception() async throws {
    let logger = NoOpNetworkLogger()
    let interceptor = LoggingInterceptor(logger: logger)
    
    let url = URL(string: "https://api.example.com/test")!
    let request = NetworkRequest.get(url: url)
    let response = NetworkResponse(
        data: Data(),
        statusCode: 200,
        headers: [:],
        url: url
    )
    
    let interceptedResponse = try await interceptor.intercept(response: response, for: request)
    
    #expect(interceptedResponse.statusCode == response.statusCode)
    #expect(interceptedResponse.data == response.data)
    #expect(interceptedResponse.headers == response.headers)
}

@Test("AuthenticationInterceptor with token")
func testAuthenticationInterceptorWithToken() async throws {
    let tokenProvider = { @Sendable () async -> String? in
        return "test-token"
    }
    
    let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
    
    let url = URL(string: "https://api.example.com/test")!
    let originalRequest = NetworkRequest.get(url: url)
    
    let interceptedRequest = try await interceptor.intercept(request: originalRequest)
    
    #expect(interceptedRequest.headers["Authorization"] == "Bearer test-token")
}

@Test("AuthenticationInterceptor without token")
func testAuthenticationInterceptorWithoutToken() async throws {
    let tokenProvider = { @Sendable () async -> String? in
        return nil
    }
    
    let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
    
    let url = URL(string: "https://api.example.com/test")!
    let originalRequest = NetworkRequest.get(url: url)
    
    let interceptedRequest = try await interceptor.intercept(request: originalRequest)
    
    #expect(interceptedRequest.headers["Authorization"] == nil)
    #expect(interceptedRequest.url == originalRequest.url)
    #expect(interceptedRequest.method == originalRequest.method)
}

@Test("UserAgentInterceptor")
func testUserAgentInterceptor() async throws {
    let userAgent = "MyApp/1.0"
    let interceptor = UserAgentInterceptor(userAgent: userAgent)
    
    let url = URL(string: "https://api.example.com/test")!
    let originalRequest = NetworkRequest.get(url: url)
    
    let interceptedRequest = try await interceptor.intercept(request: originalRequest)
    
    #expect(interceptedRequest.headers["User-Agent"] == userAgent)
}

@Test("Multiple interceptors")
func testMultipleInterceptors() async throws {
    let tokenProvider = { @Sendable () async -> String? in
        return "test-token"
    }
    
    let authInterceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
    let userAgentInterceptor = UserAgentInterceptor(userAgent: "MyApp/1.0")
    
    let url = URL(string: "https://api.example.com/test")!
    let originalRequest = NetworkRequest.get(url: url)
    
    let authInterceptedRequest = try await authInterceptor.intercept(request: originalRequest)
    let finalRequest = try await userAgentInterceptor.intercept(request: authInterceptedRequest)
    
    #expect(finalRequest.headers["Authorization"] == "Bearer test-token")
    #expect(finalRequest.headers["User-Agent"] == "MyApp/1.0")
}