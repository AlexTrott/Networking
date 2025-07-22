import Testing
import Foundation
import NetworkingInterface

@testable import Networking

@Suite("NetworkingClient Tests")
struct NetworkingClientTests {
    
    let testEnvironment = TestFixtures.createTestEnvironment()
    
    @Test("NetworkingClient initializes with correct environment")
    func testInitialization() {
        let _ = NetworkingClient(environment: testEnvironment, trustKit: MockTrustKit())

        // We can't directly access private properties, but we can test behavior
        // This test validates that the client was initialized without throwing
    }
    
    @Test("NetworkingClient initializes with interceptors")
    func testInitializationWithInterceptors() {
        let mockRequestInterceptor = MockRequestInterceptor()
        let mockResponseInterceptor = MockResponseInterceptor()
        
        let _ = NetworkingClient(
            environment: testEnvironment,
            requestInterceptors: [mockRequestInterceptor],
            responseInterceptors: [mockResponseInterceptor],
            trustKit: MockTrustKit()
        )
        
        // Client should be initialized successfully with interceptors
    }
    
    @Test("NetworkingClient GET path method constructs correct URL")
    func testGetPathMethod() async throws {
        let responseData = TestFixtures.testModelJSONData
        let mockSessionManager = MockNetworkingSessionManager()
        mockSessionManager.configureSuccess(data: responseData)
        
        let client = NetworkingClient(
            environment: testEnvironment,
            sessionManager: mockSessionManager
        )
        
        do {
            let result: TestModel = try await client.get(TestModel.self, path: "users/123")
            #expect(result == TestFixtures.testModel)
            #expect(mockSessionManager.callCount == 1)
            #expect(mockSessionManager.didReceiveRequest(withPath: "/users/123"))
            #expect(mockSessionManager.didReceiveRequest(withMethod: .GET))
        } catch {
            Issue.record("GET request failed: \(error)")
        }
    }
    
    @Test("NetworkingClient POST method adds Content-Type header when body is present")
    func testPostAddsContentTypeHeader() async throws {
        let mockRequestInterceptor = MockRequestInterceptor()
        let responseData = TestFixtures.testModelJSONData
        let mockSessionManager = MockNetworkingSessionManager()
        mockSessionManager.configureSuccess(data: responseData, statusCode: 201)
        
        let client = NetworkingClient(
            environment: testEnvironment,
            requestInterceptors: [mockRequestInterceptor],
            sessionManager: mockSessionManager
        )
        
        do {
            let bodyData = "test body".data(using: .utf8)!
            let _: TestModel = try await client.post(TestModel.self, path: "users", body: bodyData)
            
            // Check that the interceptor received a request with Content-Type header
            #expect(mockRequestInterceptor.lastInterceptedRequest?.headers["Content-Type"] == "application/json")
            #expect(mockSessionManager.callCount == 1)
            #expect(mockSessionManager.didReceiveRequest(withMethod: .POST))
        } catch {
            Issue.record("POST request failed: \(error)")
        }
    }
    
    @Test("NetworkingClient POST method preserves existing Content-Type header")
    func testPostPreservesContentTypeHeader() async throws {
        let mockRequestInterceptor = MockRequestInterceptor()
        let responseData = TestFixtures.testModelJSONData
        let mockSessionManager = MockNetworkingSessionManager()
        mockSessionManager.configureSuccess(data: responseData, statusCode: 201)
        
        let client = NetworkingClient(
            environment: testEnvironment,
            requestInterceptors: [mockRequestInterceptor],
            sessionManager: mockSessionManager
        )
        
        do {
            let customHeaders = ["Content-Type": "application/xml"]
            let bodyData = "test body".data(using: .utf8)!
            let _: TestModel = try await client.post(
                TestModel.self,
                path: "users",
                body: bodyData,
                headers: customHeaders
            )
            
            #expect(mockRequestInterceptor.lastInterceptedRequest?.headers["Content-Type"] == "application/xml")
            #expect(mockSessionManager.callCount == 1)
        } catch {
            Issue.record("POST request with custom Content-Type failed: \(error)")
        }
    }
    
    @Test("NetworkingClient PUT method adds Content-Type header when body is present")
    func testPutAddsContentTypeHeader() async throws {
        let mockRequestInterceptor = MockRequestInterceptor()
        let responseData = TestFixtures.testModelJSONData
        let mockSessionManager = MockNetworkingSessionManager()
        mockSessionManager.configureSuccess(data: responseData)
        
        let client = NetworkingClient(
            environment: testEnvironment,
            requestInterceptors: [mockRequestInterceptor],
            sessionManager: mockSessionManager
        )
        
        do {
            let bodyData = "test body".data(using: .utf8)!
            let _: TestModel = try await client.put(TestModel.self, path: "users/123", body: bodyData)
            
            #expect(mockRequestInterceptor.lastInterceptedRequest?.headers["Content-Type"] == "application/json")
            #expect(mockSessionManager.didReceiveRequest(withMethod: .PUT))
        } catch {
            Issue.record("PUT request failed: \(error)")
        }
    }
    
    @Test("NetworkingClient DELETE method returns NetworkResponse")
    func testDeleteMethod() async throws {
        let mockSessionManager = MockNetworkingSessionManager()
        mockSessionManager.configureSuccess(data: Data(), statusCode: 204)
        
        let client = NetworkingClient(
            environment: testEnvironment,
            sessionManager: mockSessionManager
        )
        
        do {
            let response = try await client.delete(path: "users/123")
            #expect(response.statusCode == 204)
            #expect(mockSessionManager.didReceiveRequest(withMethod: .DELETE))
        } catch {
            Issue.record("DELETE request failed: \(error)")
        }
    }
    
    @Test("NetworkingClient handles decoding failures")
    func testHandlesDecodingFailures() async throws {
        let mockSessionManager = MockNetworkingSessionManager()
        mockSessionManager.configureSuccess(data: TestFixtures.invalidJSONData)
        
        let client = NetworkingClient(
            environment: testEnvironment,
            sessionManager: mockSessionManager
        )
        
        do {
            let _: TestModel = try await client.get(TestModel.self, path: "users/123")
            Issue.record("Expected decoding to fail")
        } catch NetworkError.decodingFailed {
            // Expected behavior
        } catch {
            Issue.record("Expected NetworkError.decodingFailed, got: \(error)")
        }
    }
}
