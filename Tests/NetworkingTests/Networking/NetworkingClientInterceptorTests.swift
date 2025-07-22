//import Testing
//import Foundation
//import NetworkingInterface
//
//@testable import Networking
//
//@Suite("NetworkingClient Interceptor Chain Tests")
//struct NetworkingClientInterceptorTests {
//    
//    let testEnvironment = TestFixtures.createTestEnvironment()
//    
//    @Test("NetworkingClient executes request interceptors in order")
//    func testRequestInterceptorsExecutionOrder() async throws {
//        let executionOrder = LockingArray<String>()
//        
//        let interceptor1 = CallTrackingRequestInterceptor(name: "First") { order in
//            executionOrder.append(order)
//        }
//        let interceptor2 = CallTrackingRequestInterceptor(name: "Second") { order in
//            executionOrder.append(order)
//        }
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            requestInterceptors: [interceptor1, interceptor2],
//            certificatePinningEnabled: false
//        )
//        
//        URLProtocolMock.setupForTesting()
//        defer { URLProtocolMock.teardownAfterTesting() }
//        
//        URLProtocolMock.configure(statusCode: 200, data: TestFixtures.testModelJSONData)
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            #expect(executionOrder.items == ["First", "Second"])
//        } catch {
//            Issue.record("Request failed: \(error)")
//        }
//    }
//    
//    @Test("NetworkingClient executes response interceptors in order")
//    func testResponseInterceptorsExecutionOrder() async throws {
//        let executionOrder = LockingArray<String>()
//        
//        let interceptor1 = CallTrackingResponseInterceptor(name: "First") { order in
//            executionOrder.append(order)
//        }
//        let interceptor2 = CallTrackingResponseInterceptor(name: "Second") { order in
//            executionOrder.append(order)
//        }
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            responseInterceptors: [interceptor1, interceptor2],
//            certificatePinningEnabled: false
//        )
//        
//        URLProtocolMock.setupForTesting()
//        defer { URLProtocolMock.teardownAfterTesting() }
//        
//        URLProtocolMock.configure(statusCode: 200, data: TestFixtures.testModelJSONData)
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            #expect(executionOrder.items == ["First", "Second"])
//        } catch {
//            Issue.record("Request failed: \(error)")
//        }
//    }
//    
//    @Test("NetworkingClient request interceptor can modify request")
//    func testRequestInterceptorModification() async throws {
//        let modifyingInterceptor = MockRequestInterceptor()
//        modifyingInterceptor.requestModifier = { request in
//            var modifiedHeaders = request.headers
//            modifiedHeaders["X-Modified"] = "true"
//            return NetworkRequest(
//                url: request.url,
//                method: request.method,
//                headers: modifiedHeaders,
//                body: request.body
//            )
//        }
//        
//        let trackingInterceptor = MockRequestInterceptor()
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            requestInterceptors: [modifyingInterceptor, trackingInterceptor],
//            certificatePinningEnabled: false
//        )
//        
//        URLProtocolMock.setupForTesting()
//        defer { URLProtocolMock.teardownAfterTesting() }
//        
//        URLProtocolMock.configure(statusCode: 200, data: TestFixtures.testModelJSONData)
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            #expect(trackingInterceptor.lastInterceptedRequest?.headers["X-Modified"] == "true")
//        } catch {
//            Issue.record("Request failed: \(error)")
//        }
//    }
//    
//    @Test("NetworkingClient response interceptor can modify response")
//    func testResponseInterceptorModification() async throws {
//        let mockLogger = MockNetworkLogger()
//        let loggingInterceptor = MockResponseInterceptor()
//        loggingInterceptor.responseModifier = { response, request in
//            mockLogger.logResponse(response, for: request)
//            return response
//        }
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            responseInterceptors: [loggingInterceptor],
//            certificatePinningEnabled: false
//        )
//        
//        URLProtocolMock.setupForTesting()
//        defer { URLProtocolMock.teardownAfterTesting() }
//        
//        URLProtocolMock.configure(statusCode: 200, data: TestFixtures.testModelJSONData)
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            #expect(mockLogger.hasLoggedResponses)
//        } catch {
//            Issue.record("Request failed: \(error)")
//        }
//    }
//    
//    @Test("NetworkingClient handles request interceptor errors")
//    func testRequestInterceptorErrorHandling() async throws {
//        let failingInterceptor = MockRequestInterceptor()
//        failingInterceptor.shouldThrowError = MockInterceptorError.requestFailed
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            requestInterceptors: [failingInterceptor],
//            certificatePinningEnabled: false
//        )
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            Issue.record("Expected request to fail due to interceptor error")
//        } catch MockInterceptorError.requestFailed {
//            // Expected behavior
//        } catch {
//            Issue.record("Expected MockInterceptorError.requestFailed, got: \(error)")
//        }
//    }
//    
//    @Test("NetworkingClient handles response interceptor errors")
//    func testResponseInterceptorErrorHandling() async throws {
//        let failingInterceptor = MockResponseInterceptor()
//        failingInterceptor.shouldThrowError = MockInterceptorError.responseFailed
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            responseInterceptors: [failingInterceptor],
//            certificatePinningEnabled: false
//        )
//        
//        URLProtocolMock.setupForTesting()
//        defer { URLProtocolMock.teardownAfterTesting() }
//        
//        URLProtocolMock.configure(statusCode: 200, data: TestFixtures.testModelJSONData)
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            Issue.record("Expected request to fail due to response interceptor error")
//        } catch MockInterceptorError.responseFailed {
//            // Expected behavior
//        } catch {
//            Issue.record("Expected MockInterceptorError.responseFailed, got: \(error)")
//        }
//    }
//    
//    @Test("NetworkingClient executes interceptors even with no body")
//    func testInterceptorsWithNoBody() async throws {
//        let requestInterceptor = MockRequestInterceptor()
//        let responseInterceptor = MockResponseInterceptor()
//        
//        let client = NetworkingClient(
//            environment: testEnvironment,
//            requestInterceptors: [requestInterceptor],
//            responseInterceptors: [responseInterceptor],
//            certificatePinningEnabled: false
//        )
//        
//        URLProtocolMock.setupForTesting()
//        defer { URLProtocolMock.teardownAfterTesting() }
//        
//        URLProtocolMock.configure(statusCode: 200, data: TestFixtures.testModelJSONData)
//        
//        do {
//            let _: TestModel = try await client.get(TestModel.self, path: "test")
//            
//            #expect(requestInterceptor.lastInterceptedRequest != nil)
//            #expect(responseInterceptor.lastInterceptedResponse != nil)
//        } catch {
//            Issue.record("Request failed: \(error)")
//        }
//    }
//}
//
//// MARK: - Helper Classes
//
//final class CallTrackingRequestInterceptor: RequestInterceptor, @unchecked Sendable {
//    private let name: String
//    private let callback: @Sendable (String) -> Void
//    
//    init(name: String, callback: @escaping @Sendable (String) -> Void) {
//        self.name = name
//        self.callback = callback
//    }
//    
//    func intercept(request: NetworkRequest) async throws -> NetworkRequest {
//        callback(name)
//        return request
//    }
//}
//
//final class CallTrackingResponseInterceptor: ResponseInterceptor, @unchecked Sendable {
//    private let name: String
//    private let callback: @Sendable (String) -> Void
//    
//    init(name: String, callback: @escaping @Sendable (String) -> Void) {
//        self.name = name
//        self.callback = callback
//    }
//    
//    func intercept(response: NetworkResponse, for request: NetworkRequest) async throws -> NetworkResponse {
//        callback(name)
//        return response
//    }
//}
//
//enum MockInterceptorError: Error {
//    case requestFailed
//    case responseFailed
//}
//
//final class LockingArray<T>: @unchecked Sendable {
//    private var _items: [T] = []
//    private let lock = NSLock()
//    
//    var items: [T] {
//        lock.withLock { _items }
//    }
//    
//    func append(_ item: T) {
//        lock.withLock { _items.append(item) }
//    }
//}
//
