import Testing
import Foundation
import NetworkingInterface

@testable import NetworkingInterface

@Suite("NetworkResponse Tests")
struct NetworkResponseTests {
    
    @Test("NetworkResponse initializes with correct properties")
    func testInitialization() {
        let data = TestFixtures.validJSONData
        let headers = ["Content-Type": "application/json"]
        let url = URL(string: "https://api.example.com/test")!
        
        let response = NetworkResponse(
            data: data,
            statusCode: 201,
            headers: headers,
            url: url
        )
        
        #expect(response.data == data)
        #expect(response.statusCode == 201)
        #expect(response.headers == headers)
        #expect(response.url == url)
    }
    
    @Test("NetworkResponse statusCode property returns correct value")
    func testStatusCodeProperty() {
        let response = NetworkTestHelpers.createTestResponse(statusCode: 404)
        
        #expect(response.statusCode == 404)
    }
    
    @Test("NetworkResponse isSuccessful returns true for 2xx status codes")
    func testIsSuccessfulForSuccessStatusCodes() {
        let successCodes = [200, 201, 202, 204, 299]
        
        for statusCode in successCodes {
            let response = NetworkTestHelpers.createTestResponse(statusCode: statusCode)
            
            #expect(response.isSuccessful == true, "Status code \(statusCode) should be successful")
        }
    }
    
    @Test("NetworkResponse isSuccessful returns false for non-2xx status codes")
    func testIsSuccessfulForNonSuccessStatusCodes() {
        let nonSuccessCodes = [100, 199, 300, 400, 404, 500, 503]
        
        for statusCode in nonSuccessCodes {
            let response = NetworkTestHelpers.createTestResponse(statusCode: statusCode)
            
            #expect(response.isSuccessful == false, "Status code \(statusCode) should not be successful")
        }
    }
    
    @Test("NetworkResponse isClientError returns true for 4xx status codes")
    func testIsClientErrorFor4xxStatusCodes() {
        let clientErrorCodes = [400, 401, 403, 404, 422, 429, 499]
        
        for statusCode in clientErrorCodes {
            let response = NetworkTestHelpers.createTestResponse(statusCode: statusCode)
            
            #expect(response.isClientError == true, "Status code \(statusCode) should be client error")
        }
    }
    
    @Test("NetworkResponse isServerError returns true for 5xx status codes")
    func testIsServerErrorFor5xxStatusCodes() {
        let serverErrorCodes = [500, 501, 502, 503, 504, 599]
        
        for statusCode in serverErrorCodes {
            let response = NetworkTestHelpers.createTestResponse(statusCode: statusCode)
            
            #expect(response.isServerError == true, "Status code \(statusCode) should be server error")
        }
    }
    
    @Test("NetworkResponse decode successfully decodes valid JSON")
    func testDecodeWithValidJSON() throws {
        let data = TestFixtures.testModelJSONData
        let response = NetworkTestHelpers.createTestResponse(data: data)
        
        let decoded = try response.decode(TestModel.self)
        
        #expect(decoded == TestFixtures.testModel)
    }
    
    @Test("NetworkResponse decode throws error for invalid JSON")
    func testDecodeWithInvalidJSON() {
        let data = TestFixtures.invalidJSONData
        let response = NetworkTestHelpers.createTestResponse(data: data)
        
        #expect(throws: (any Error).self) {
            try response.decode(TestModel.self)
        }
    }
    
    @Test("NetworkResponse string returns string for valid UTF-8 data")
    func testStringWithValidUTF8() {
        let testString = "Hello, World!"
        let data = testString.data(using: .utf8)!
        let response = NetworkTestHelpers.createTestResponse(data: data)
        
        let result = response.string
        
        #expect(result == testString)
    }
    
    @Test("NetworkResponse string returns nil for invalid UTF-8 data")
    func testStringWithInvalidUTF8() {
        let invalidData = Data([0xFF, 0xFE, 0xFD])
        let response = NetworkTestHelpers.createTestResponse(data: invalidData)
        
        let result = response.string
        
        #expect(result == nil)
    }
    
    @Test("NetworkResponse string returns empty string for empty data")
    func testStringWithEmptyData() {
        let emptyData = Data()
        let response = NetworkTestHelpers.createTestResponse(data: emptyData)
        
        let result = response.string
        
        #expect(result == "")
    }
    
    @Test("NetworkResponse headers property returns HTTP headers")
    func testHeadersProperty() {
        let headers = ["Content-Type": "application/json", "X-Custom": "test"]
        let response = NetworkTestHelpers.createTestResponse(headers: headers)
        
        #expect(response.headers == headers)
    }
}
