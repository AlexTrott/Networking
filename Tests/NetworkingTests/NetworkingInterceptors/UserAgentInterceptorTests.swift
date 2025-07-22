import Testing
import Foundation
import NetworkingInterface

@testable import NetworkingInterceptors

@Suite("UserAgentInterceptor Tests")
struct UserAgentInterceptorTests {
    
    @Test("UserAgentInterceptor adds User-Agent header to request")
    func testAddsUserAgentHeader() async throws {
        let expectedUserAgent = "MyApp/1.0 iOS/15.0"
        let interceptor = UserAgentInterceptor(userAgent: expectedUserAgent)
        
        let request = NetworkTestHelpers.createTestRequest(
            headers: ["Content-Type": "application/json"]
        )
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == expectedUserAgent)
        #expect(result.headers["Content-Type"] == "application/json")
        #expect(result.url == request.url)
        #expect(result.method == request.method)
        #expect(result.body == request.body)
    }
    
    @Test("UserAgentInterceptor overwrites existing User-Agent header")
    func testOverwritesExistingUserAgentHeader() async throws {
        let newUserAgent = "NewApp/2.0 macOS/12.0"
        let interceptor = UserAgentInterceptor(userAgent: newUserAgent)
        
        let request = NetworkTestHelpers.createTestRequest(
            headers: ["User-Agent": "OldApp/1.0"]
        )
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == newUserAgent)
    }
    
    @Test("UserAgentInterceptor handles request with nil headers")
    func testHandlesRequestWithNilHeaders() async throws {
        let expectedUserAgent = "TestApp/1.0"
        let interceptor = UserAgentInterceptor(userAgent: expectedUserAgent)
        
        let request = NetworkTestHelpers.createTestRequest(headers: [:])
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == expectedUserAgent)
        #expect(result.headers.keys.count == 1)
    }
    
    @Test("UserAgentInterceptor preserves all other request properties")
    func testPreservesAllRequestProperties() async throws {
        let userAgent = "PreserveApp/3.0"
        let interceptor = UserAgentInterceptor(userAgent: userAgent)
        
        let originalURL = URL(string: "https://api.example.com/data")!
        let originalMethod = HTTPMethod.PUT
        let originalBody = "{\"key\": \"value\"}".data(using: .utf8)!
        let originalHeaders = [
            "Authorization": "Bearer token",
            "Content-Type": "application/json",
            "Accept": "application/json"
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
        #expect(result.headers["Authorization"] == "Bearer token")
        #expect(result.headers["Content-Type"] == "application/json")
        #expect(result.headers["Accept"] == "application/json")
        #expect(result.headers["User-Agent"] == userAgent)
    }
    
    @Test("UserAgentInterceptor works with empty user agent string")
    func testEmptyUserAgentString() async throws {
        let interceptor = UserAgentInterceptor(userAgent: "")
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == "")
    }
    
    @Test("UserAgentInterceptor works with complex user agent string")
    func testComplexUserAgentString() async throws {
        let complexUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) MyApp/1.2.3 Mobile/15A372 Safari/604.1"
        let interceptor = UserAgentInterceptor(userAgent: complexUserAgent)
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == complexUserAgent)
    }
    
    @Test("UserAgentInterceptor works with special characters in user agent")
    func testUserAgentWithSpecialCharacters() async throws {
        let specialUserAgent = "MyApp/1.0 (Device: iPhone 13 Pro; OS: iOS 15.0; Build: 19A344)"
        let interceptor = UserAgentInterceptor(userAgent: specialUserAgent)
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == specialUserAgent)
    }
    
    @Test("UserAgentInterceptor preserves header case sensitivity")
    func testPreservesExistingHeaderCases() async throws {
        let interceptor = UserAgentInterceptor(userAgent: "TestApp/1.0")
        
        let request = NetworkTestHelpers.createTestRequest(
            headers: [
                "Content-TYPE": "application/json", // Intentional case variation
                "x-custom-header": "value"           // lowercase
            ]
        )
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["Content-TYPE"] == "application/json")
        #expect(result.headers["x-custom-header"] == "value")
        #expect(result.headers["User-Agent"] == "TestApp/1.0")
        #expect(result.headers.keys.count == 3)
    }
    
    @Test("UserAgentInterceptor works with whitespace-only user agent")
    func testWhitespaceOnlyUserAgent() async throws {
        let interceptor = UserAgentInterceptor(userAgent: "   ")
        
        let request = NetworkTestHelpers.createTestRequest()
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers["User-Agent"] == "   ")
    }
}

@Suite("UserAgentInterceptor Integration Tests")
struct UserAgentInterceptorIntegrationTests {
    
    @Test("UserAgentInterceptor works in interceptor chain")
    func testInInterceptorChain() async throws {
        let userAgentInterceptor = UserAgentInterceptor(userAgent: "ChainApp/1.0")
        let authInterceptor = AuthenticationInterceptor(tokenProvider: { "test-token" })
        
        let request = NetworkTestHelpers.createTestRequest()
        
        // First apply UserAgent interceptor
        let userAgentResult = try await userAgentInterceptor.intercept(request: request)
        
        // Then apply Authentication interceptor
        let finalResult = try await authInterceptor.intercept(request: userAgentResult)
        
        #expect(finalResult.headers["User-Agent"] == "ChainApp/1.0")
        #expect(finalResult.headers["Authorization"] == "Bearer test-token")
    }
    
    @Test("UserAgentInterceptor with multiple header modifications")
    func testMultipleHeaderModifications() async throws {
        let interceptor = UserAgentInterceptor(userAgent: "MultiApp/1.0")
        
        var request = NetworkTestHelpers.createTestRequest(headers: [:])
        
        // Apply interceptor multiple times to simulate chain behavior
        request = try await interceptor.intercept(request: request)
        request = try await interceptor.intercept(request: request)
        request = try await interceptor.intercept(request: request)
        
        #expect(request.headers["User-Agent"] == "MultiApp/1.0")
        #expect(request.headers.keys.count == 1)
    }
}
