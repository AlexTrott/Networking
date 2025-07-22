import Testing
import Foundation
import NetworkingInterface

@testable import NetworkingInterceptors

@Suite("LoggingInterceptor Tests")
struct LoggingInterceptorTests {
    
    @Test("LoggingInterceptor logs request and returns unmodified request")
    func testLogRequest() async throws {
        let mockLogger = MockNetworkLogger()
        let interceptor = LoggingInterceptor(logger: mockLogger)
        
        let request = NetworkTestHelpers.createTestRequest(
            url: "https://api.example.com/users",
            method: .GET,
            headers: ["Authorization": "Bearer token"]
        )
        
        let result = try await interceptor.intercept(request: request)
        
        // Verify the request is returned unmodified
        #expect(result.url == request.url)
        #expect(result.method == request.method)
        #expect(result.headers == request.headers)
        #expect(result.body == request.body)
        
        // Verify the logger was called
        #expect(mockLogger.loggedRequests.count == 1)
        #expect(mockLogger.loggedRequests[0].url == request.url)
    }
    
    @Test("LoggingInterceptor logs response and returns unmodified response")
    func testLogResponse() async throws {
        let mockLogger = MockNetworkLogger()
        let interceptor = LoggingInterceptor(logger: mockLogger)
        
        let request = NetworkTestHelpers.createTestRequest()
        let response = NetworkTestHelpers.createTestResponse(
            request: request,
            statusCode: 200,
            data: TestFixtures.validJSONData
        )
        
        let result = try await interceptor.intercept(response: response, for: request)
        
        // Verify the response is returned unmodified
        #expect(result.statusCode == response.statusCode)
        #expect(result.data == response.data)
        #expect(result.headers == response.headers)
        
        // Verify the logger was called
        #expect(mockLogger.loggedResponses.count == 1)
        #expect(mockLogger.loggedResponses[0].0.statusCode == response.statusCode)
        #expect(mockLogger.loggedResponses[0].1.url == request.url)
    }
    
    @Test("LoggingInterceptor works with NoOpNetworkLogger")
    func testWithNoOpLogger() async throws {
        let interceptor = LoggingInterceptor(logger: NoOpNetworkLogger())
        
        let request = NetworkTestHelpers.createTestRequest()
        let response = NetworkTestHelpers.createTestResponse()
        
        // Should not throw and should return unmodified data
        let resultRequest = try await interceptor.intercept(request: request)
        let resultResponse = try await interceptor.intercept(response: response, for: request)
        
        #expect(resultRequest.url == request.url)
        #expect(resultResponse.statusCode == response.statusCode)
    }
    
    @Test("LoggingInterceptor initializes with DefaultNetworkLogger by default")
    func testDefaultInitialization() {
        let _ = LoggingInterceptor()
        
        // We can't easily test the internal logger type, but we can verify it doesn't crash
        // Interceptor instance should be created successfully
    }
    
    @Test("LoggingInterceptor handles requests with nil headers")
    func testRequestWithNilHeaders() async throws {
        let mockLogger = MockNetworkLogger()
        let interceptor = LoggingInterceptor(logger: mockLogger)
        
        let request = NetworkTestHelpers.createTestRequest(headers: [:])
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.headers == [:])
        #expect(mockLogger.loggedRequests.count == 1)
    }
    
    @Test("LoggingInterceptor handles requests with nil body")
    func testRequestWithNilBody() async throws {
        let mockLogger = MockNetworkLogger()
        let interceptor = LoggingInterceptor(logger: mockLogger)
        
        let request = NetworkTestHelpers.createTestRequest(body: nil)
        
        let result = try await interceptor.intercept(request: request)
        
        #expect(result.body == nil)
        #expect(mockLogger.loggedRequests.count == 1)
    }
    
    @Test("LoggingInterceptor handles empty response data")
    func testResponseWithEmptyData() async throws {
        let mockLogger = MockNetworkLogger()
        let interceptor = LoggingInterceptor(logger: mockLogger)
        
        let request = NetworkTestHelpers.createTestRequest()
        let response = NetworkTestHelpers.createTestResponse(data: Data())
        
        let result = try await interceptor.intercept(response: response, for: request)
        
        #expect(result.data == Data())
        #expect(mockLogger.loggedResponses.count == 1)
    }
}

// MARK: - Enhanced MockNetworkLogger for Testing

final class EnhancedMockNetworkLogger: NetworkLogger, @unchecked Sendable {
    private var _loggedRequests: [NetworkRequest] = []
    private var _loggedResponses: [(NetworkResponse, NetworkRequest)] = []
    private let lock = NSLock()
    
    var loggedRequests: [NetworkRequest] {
        lock.withLock { _loggedRequests }
    }
    
    var loggedResponses: [(NetworkResponse, NetworkRequest)] {
        lock.withLock { _loggedResponses }
    }
    
    func logRequest(_ request: NetworkRequest) {
        lock.withLock {
            _loggedRequests.append(request)
        }
    }
    
    func logResponse(_ response: NetworkResponse, for request: NetworkRequest) {
        lock.withLock {
            _loggedResponses.append((response, request))
        }
    }
    
    func reset() {
        lock.withLock {
            _loggedRequests.removeAll()
            _loggedResponses.removeAll()
        }
    }
}
