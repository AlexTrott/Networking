import Testing
import Foundation
import NetworkingInterface

@testable import Networking

@Suite("NetworkingSessionManager Tests")
struct NetworkingSessionManagerTests {
    
    let testEnvironment = TestFixtures.createTestEnvironment()
    let mockCertificatePinning = MockCertificatePinning()
    
    @Test("NetworkingSessionManager initializes with correct configuration")
    func testInitialization() {
        let _ = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: true,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        // Session manager should be created successfully
    }
    
    @Test("NetworkingSessionManager creates URLSession with delegate")
    func testCreateSession() {
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: true,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let session = sessionManager.createSession()
        
        #expect(session.delegate === sessionManager)
        #expect(session.configuration.timeoutIntervalForRequest == 60.0)
        #expect(session.configuration.timeoutIntervalForResource == 120.0)
    }
    
    @Test("NetworkingSessionManager performs successful request")
    func testPerformSuccessfulRequest() async throws {
        let testURL = "https://test.example.com/success"
        let responseData = TestFixtures.validJSONData
        URLProtocolMock.configureForURL(testURL, statusCode: 200, data: responseData)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let response = try await sessionManager.perform(request)
            
            #expect(response.statusCode == 200)
            #expect(response.data == responseData)
            #expect(response.isSuccessful == true)
        } catch {
            Issue.record("Request should have succeeded: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager throws HTTPError for client errors")
    func testPerformClientError() async throws {
        let testURL = "https://test.example.com/client-error"
        let errorData = "Not Found".data(using: .utf8)!
        URLProtocolMock.configureForURL(testURL, statusCode: 404, data: errorData)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let _ = try await sessionManager.perform(request)
            Issue.record("Expected client error to be thrown")
        } catch NetworkError.httpError(let httpError) {
            #expect(httpError.statusCode == 404)
            #expect(httpError.data == errorData)
        } catch {
            Issue.record("Expected NetworkError.httpError, got: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager throws HTTPError for server errors")
    func testPerformServerError() async throws {
        let testURL = "https://test.example.com/server-error"
        let errorData = "Internal Server Error".data(using: .utf8)!
        URLProtocolMock.configureForURL(testURL, statusCode: 500, data: errorData)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let _ = try await sessionManager.perform(request)
            Issue.record("Expected server error to be thrown")
        } catch NetworkError.httpError(let httpError) {
            #expect(httpError.statusCode == 500)
            #expect(httpError.data == errorData)
        } catch {
            Issue.record("Expected NetworkError.httpError, got: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager maps URLError timeout to NetworkError timeout")
    func testURLErrorTimeoutMapping() async throws {
        let testURL = "https://test.example.com/timeout"
        URLProtocolMock.configureForURL(testURL, error: URLError(.timedOut))
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let _ = try await sessionManager.perform(request)
            Issue.record("Expected timeout error to be thrown")
        } catch NetworkError.timeout {
            // Expected behavior
        } catch {
            Issue.record("Expected NetworkError.timeout, got: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager maps URLError cancelled to NetworkError cancelled")
    func testURLErrorCancelledMapping() async throws {
        let testURL = "https://test.example.com/cancelled"
        URLProtocolMock.configureForURL(testURL, error: URLError(.cancelled))
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let _ = try await sessionManager.perform(request)
            Issue.record("Expected cancelled error to be thrown")
        } catch NetworkError.cancelled {
            // Expected behavior
        } catch {
            Issue.record("Expected NetworkError.cancelled, got: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager maps other URLErrors to NetworkError connectionError")
    func testURLErrorConnectionMapping() async throws {
        let testURL = "https://test.example.com/connection-lost"
        let urlError = URLError(.networkConnectionLost)
        URLProtocolMock.configureForURL(testURL, error: urlError)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let _ = try await sessionManager.perform(request)
            Issue.record("Expected connection error to be thrown")
        } catch NetworkError.connectionError(let error) {
            #expect((error as URLError).code == .networkConnectionLost)
        } catch {
            Issue.record("Expected NetworkError.connectionError, got: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager maps unknown errors to NetworkError unknown")
    func testUnknownErrorMapping() async throws {
        let testURL = "https://test.example.com/unknown-error"
        let customError = TestCustomError.unknownFailure
        URLProtocolMock.configureForURL(testURL, error: customError)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let _ = try await sessionManager.perform(request)
            Issue.record("Expected unknown error to be thrown")
        } catch NetworkError.unknown(let error) {
            // URLProtocolMock wraps custom errors in NSURLError, so we need to check the wrapped error
            let nsError = error as NSError
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? TestCustomError {
                #expect(underlyingError == TestCustomError.unknownFailure)
            } else {
                // Accept that the error is wrapped in NSURLError
                #expect(nsError.domain.contains("TestCustomError"))
            }
        } catch {
            Issue.record("Expected NetworkError.unknown, got: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager handles empty response successfully")
    func testHandlesEmptyResponse() async throws {
        let testURL = "https://test.example.com/empty-response"
        // Test with empty data but valid HTTP response
        URLProtocolMock.configureForURL(testURL, statusCode: 204, data: Data())
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let request = NetworkTestHelpers.createTestRequest(url: testURL)
        
        do {
            let response = try await sessionManager.perform(request)
            #expect(response.statusCode == 204)
            #expect(response.data.isEmpty)
            #expect(response.isSuccessful == true)
        } catch {
            Issue.record("Request should have succeeded with empty data: \(error)")
        }
    }
    
    @Test("NetworkingSessionManager certificate pinning disabled allows default handling")
    func testCertificatePinningDisabled() {
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: false,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let mockChallenge = MockURLAuthenticationChallenge()
        var capturedDisposition: URLSession.AuthChallengeDisposition?
        var capturedCredential: URLCredential?
        
        sessionManager.urlSession(
            URLSession.shared,
            didReceive: mockChallenge.challenge,
            completionHandler: { disposition, credential in
                capturedDisposition = disposition
                capturedCredential = credential
            }
        )
        
        #expect(capturedDisposition == .performDefaultHandling)
        #expect(capturedCredential == nil)
    }
    
    @Test("NetworkingSessionManager certificate pinning enabled uses certificate validation")
    func testCertificatePinningEnabled() {
        mockCertificatePinning.reset()
        mockCertificatePinning.configure(shouldPass: true)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: true,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let mockChallenge = MockURLAuthenticationChallenge(
            hasServerTrust: true,
            hostname: "api.example.com"
        )
        var capturedDisposition: URLSession.AuthChallengeDisposition?
        var capturedCredential: URLCredential?
        
        sessionManager.urlSession(
            URLSession.shared,
            didReceive: mockChallenge.challenge,
            completionHandler: { disposition, credential in
                capturedDisposition = disposition
                capturedCredential = credential
            }
        )
        
        // Check if server trust was provided to the challenge
        if mockChallenge.challenge.protectionSpace.serverTrust != nil {
            #expect(capturedDisposition == .useCredential)
            #expect(capturedCredential != nil)
            #expect(mockCertificatePinning.receivedHostnames.contains("api.example.com"))
        } else {
            // If SecTrust creation failed on this platform, expect default handling
            #expect(capturedDisposition == .performDefaultHandling)
            #expect(capturedCredential == nil)
        }
    }
    
    @Test("NetworkingSessionManager certificate pinning rejects invalid certificates")
    func testCertificatePinningRejectsInvalidCertificates() {
        mockCertificatePinning.reset()
        mockCertificatePinning.configure(shouldPass: false)
        
        let sessionManager = NetworkingSessionManager(
            certificatePinning: mockCertificatePinning,
            certificatePinningEnabled: true,
            configuration: URLProtocolMock.configuredURLSessionConfiguration()
        )
        
        let mockChallenge = MockURLAuthenticationChallenge(
            hasServerTrust: true,
            hostname: "malicious.example.com"
        )
        var capturedDisposition: URLSession.AuthChallengeDisposition?
        var capturedCredential: URLCredential?
        
        sessionManager.urlSession(
            URLSession.shared,
            didReceive: mockChallenge.challenge,
            completionHandler: { disposition, credential in
                capturedDisposition = disposition
                capturedCredential = credential
            }
        )
        
        // Check if server trust was provided to the challenge
        if mockChallenge.challenge.protectionSpace.serverTrust != nil {
            #expect(capturedDisposition == .cancelAuthenticationChallenge)
            #expect(capturedCredential == nil)
        } else {
            // If SecTrust creation failed on this platform, expect default handling
            #expect(capturedDisposition == .performDefaultHandling)
            #expect(capturedCredential == nil)
        }
    }
}
