import Testing
import Foundation
import NetworkingInterface

@testable import NetworkingInterface

@Suite("NetworkRequest Tests")
struct NetworkRequestTests {
    
    @Test("NetworkRequest initializes with correct properties")
    func testInitialization() {
        let url = URL(string: "https://api.example.com/users")!
        let headers = ["Authorization": "Bearer token", "Accept": "application/json"]
        let body = "test body".data(using: .utf8)!
        
        let request = NetworkRequest(
            url: url,
            method: .POST,
            headers: headers,
            body: body
        )
        
        #expect(request.url == url)
        #expect(request.method == .POST)
        #expect(request.headers == headers)
        #expect(request.body == body)
    }
    
    @Test("NetworkRequest.get creates correct GET request")
    func testGetStaticMethod() {
        let url = URL(string: "https://api.example.com/users")!
        let headers = ["Accept": "application/json"]
        
        let request = NetworkRequest.get(url: url, headers: headers)
        
        #expect(request.url == url)
        #expect(request.method == .GET)
        #expect(request.headers == headers)
        #expect(request.body == nil)
    }
    
    @Test("NetworkRequest.post creates correct POST request")
    func testPostStaticMethod() {
        let url = URL(string: "https://api.example.com/users")!
        let headers = ["Content-Type": "application/json"]
        let body = "{\"name\": \"test\"}".data(using: .utf8)!
        
        let request = NetworkRequest.post(url: url, headers: headers, body: body)
        
        #expect(request.url == url)
        #expect(request.method == .POST)
        #expect(request.headers == headers)
        #expect(request.body == body)
    }
    
    @Test("NetworkRequest.put creates correct PUT request")
    func testPutStaticMethod() {
        let url = URL(string: "https://api.example.com/users/1")!
        let headers = ["Content-Type": "application/json"]
        let body = "{\"name\": \"updated\"}".data(using: .utf8)!
        
        let request = NetworkRequest.put(url: url, headers: headers, body: body)
        
        #expect(request.url == url)
        #expect(request.method == .PUT)
        #expect(request.headers == headers)
        #expect(request.body == body)
    }
    
    @Test("NetworkRequest.delete creates correct DELETE request")
    func testDeleteStaticMethod() {
        let url = URL(string: "https://api.example.com/users/1")!
        let headers = ["Authorization": "Bearer token"]
        
        let request = NetworkRequest.delete(url: url, headers: headers)
        
        #expect(request.url == url)
        #expect(request.method == .DELETE)
        #expect(request.headers == headers)
        #expect(request.body == nil)
    }
    
    @Test("NetworkRequest converts to URLRequest correctly")
    func testToURLRequest() {
        let url = URL(string: "https://api.example.com/users")!
        let headers = ["Authorization": "Bearer token", "Accept": "application/json"]
        let body = "test body".data(using: .utf8)!
        
        let networkRequest = NetworkRequest(
            url: url,
            method: .POST,
            headers: headers,
            body: body
        )
        
        let urlRequest = networkRequest.toURLRequest()
        
        #expect(urlRequest.url == url)
        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.httpBody == body)
        #expect(urlRequest.allHTTPHeaderFields == headers)
    }
    
    @Test("NetworkRequest converts to URLRequest with nil headers")
    func testToURLRequestWithNilHeaders() {
        let url = URL(string: "https://api.example.com/users")!
        
        let networkRequest = NetworkRequest(
            url: url,
            method: .GET,
            headers: [:],
            body: nil
        )
        
        let urlRequest = networkRequest.toURLRequest()
        
        #expect(urlRequest.url == url)
        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.httpBody == nil)
        #expect(urlRequest.allHTTPHeaderFields == nil || urlRequest.allHTTPHeaderFields?.isEmpty == true)
    }
    
    @Test("NetworkRequest handles all HTTP methods")
    func testAllHTTPMethods() {
        let url = URL(string: "https://api.example.com/test")!
        
        let methods: [(HTTPMethod, String)] = [
            (.GET, "GET"),
            (.POST, "POST"),
            (.PUT, "PUT"),
            (.DELETE, "DELETE"),
            (.PATCH, "PATCH"),
            (.HEAD, "HEAD"),
            (.OPTIONS, "OPTIONS")
        ]
        
        for (method, expectedString) in methods {
            let request = NetworkRequest(url: url, method: method, headers: [:], body: nil)
            let urlRequest = request.toURLRequest()
            
            #expect(urlRequest.httpMethod == expectedString, "Failed for method \(method)")
        }
    }
}
