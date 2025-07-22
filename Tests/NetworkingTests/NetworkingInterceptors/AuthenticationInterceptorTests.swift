import Testing
import Foundation
import NetworkingInterface

@testable import NetworkingInterceptors

@Suite("AuthenticationInterceptor Tests")
struct AuthenticationInterceptorTests {
    
    @Test("AuthenticationInterceptor adds Bearer token to request headers")
    func testAddsAuthorizationHeader() async throws {
        let expectedToken = "test-jwt-token"
        let tokenProvider: @Sendable () async -> String? = { expectedToken }
        
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest(
            headers: ["Content-Type": "application/json"]
        )
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Authorization"] == "Bearer \(expectedToken)")
        #expect(result.headers["Content-Type"] == "application/json")
        #expect(result.url == request.url)
        #expect(result.method == request.method)
        #expect(result.body == request.body)
    }
    
    @Test("AuthenticationInterceptor returns unmodified request when token is nil")
    func testReturnsUnmodifiedRequestWhenTokenIsNil() async throws {
        let tokenProvider: @Sendable () async -> String? = { nil }
        
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let originalHeaders = ["Content-Type": "application/json"]
        let request = NetworkTestHelpers.createTestRequest(headers: originalHeaders)
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers == originalHeaders)
        #expect(result.headers["Authorization"] == nil)
        #expect(result.url == request.url)
        #expect(result.method == request.method)
        #expect(result.body == request.body)
    }
    
    @Test("AuthenticationInterceptor overwrites existing Authorization header")
    func testOverwritesExistingAuthorizationHeader() async throws {
        let newToken = "new-jwt-token"
        let tokenProvider: @Sendable () async -> String? = { newToken }
        
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest(
            headers: ["Authorization": "Bearer old-token"]
        )
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Authorization"] == "Bearer \(newToken)")
    }
    
    @Test("AuthenticationInterceptor handles request with nil headers")
    func testHandlesRequestWithNilHeaders() async throws {
        let expectedToken = "test-token"
        let tokenProvider: @Sendable () async -> String? = { expectedToken }
        
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest(headers: [:])
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Authorization"] == "Bearer \(expectedToken)")
        #expect(result.headers.keys.count == 1)
    }
    
    @Test("AuthenticationInterceptor works with async token provider")
    func testAsyncTokenProvider() async throws {
        let expectedToken = "async-token"
        let tokenProvider: @Sendable () async -> String? = { () async -> String? in
            // Simulate async token retrieval
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return expectedToken
        }
        
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Authorization"] == "Bearer \(expectedToken)")
    }
    
    @Test("AuthenticationInterceptor handles slow token provider")
    func testSlowTokenProvider() async throws {
        let expectedToken = "slow-token"
        let tokenProvider: @Sendable () async -> String? = { () async -> String? in
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return expectedToken
        }
        
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let start = Date()
        let result = try await interceptor.intercept(request: request)
        let duration = Date().timeIntervalSince(start)
        
        #expect(result.headers["Authorization"] == "Bearer \(expectedToken)")
        #expect(duration >= 0.1) // Should have taken at least 100ms
    }
    
    @Test("AuthenticationInterceptor preserves all other request properties")
    func testPreservesAllRequestProperties() async throws {
        let tokenProvider: @Sendable () async -> String? = { "token" }
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let originalURL = URL(string: "https://api.example.com/users/123")!
        let originalMethod = HTTPMethod.POST
        let originalBody = "test body".data(using: .utf8)!
        let originalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Custom": "value"
        ]
        
        let request = NetworkRequest(
            url: originalURL,
            method: originalMethod,
            headers: originalHeaders,
            body: originalBody
        )
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.url == originalURL)
        #expect(result.method == originalMethod)
        #expect(result.body == originalBody)
        #expect(result.headers["Content-Type"] == "application/json")
        #expect(result.headers["Accept"] == "application/json")
        #expect(result.headers["X-Custom"] == "value")
        #expect(result.headers["Authorization"] == "Bearer token")
    }
    
    @Test("AuthenticationInterceptor works with empty string token")
    func testEmptyStringToken() async throws {
        let tokenProvider: @Sendable () async -> String? = { "" }
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Authorization"] == "Bearer ")
    }
    
    @Test("AuthenticationInterceptor works with whitespace token")
    func testWhitespaceToken() async throws {
        let tokenProvider: @Sendable () async -> String? = { "  token-with-spaces  " }
        let interceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Authorization"] == "Bearer   token-with-spaces  ")
    }
}
