import Testing
import Foundation
import NetworkingInterface

@testable import NetworkingInterface

@Suite("NetworkError Tests")
struct NetworkErrorTests {
    
    @Test("NetworkError equality works correctly for same cases")
    func testEqualityForSameCases() {
        let error1 = NetworkError.invalidURL
        let error2 = NetworkError.invalidURL
        
        #expect(error1 == error2)
        
        let urlError = URLError(.networkConnectionLost)
        let networkError1 = NetworkError.connectionError(urlError)
        let networkError2 = NetworkError.connectionError(urlError)
        
        #expect(networkError1 == networkError2)
    }
    
    @Test("NetworkError equality works correctly for different cases")
    func testEqualityForDifferentCases() {
        let error1 = NetworkError.invalidURL
        let error2 = NetworkError.timeout
        
        #expect(error1 != error2)
        
        let urlError1 = URLError(.networkConnectionLost)
        let urlError2 = URLError(.timedOut)
        let networkError1 = NetworkError.connectionError(urlError1)
        let networkError2 = NetworkError.connectionError(urlError2)
        
        #expect(networkError1 != networkError2)
    }
    
    @Test("NetworkError basic cases")
    func testBasicCases() {
        let cases: [NetworkError] = [
            .invalidURL,
            .invalidRequest,
            .noData,
            .certificatePinningFailed,
            .timeout,
            .cancelled
        ]
        
        for networkError in cases {
            #expect(networkError == networkError) // Self-equality
        }
    }
    
    @Test("NetworkError associated value cases")
    func testAssociatedValueCases() {
        let urlError = URLError(.networkConnectionLost)
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test error")
        )
        let httpError = HTTPError(statusCode: 404)
        
        let cases: [NetworkError] = [
            .decodingFailed(decodingError),
            .encodingFailed(decodingError),
            .httpError(httpError),
            .connectionError(urlError),
            .unknown(urlError)
        ]
        
        for networkError in cases {
            #expect(networkError == networkError) // Self-equality
        }
    }
    
    @Test("HTTPError equality")
    func testHTTPErrorEquality() {
        let error1 = HTTPError(statusCode: 404)
        let error2 = HTTPError(statusCode: 404)
        let error3 = HTTPError(statusCode: 500)
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
    
    @Test("HTTPError with data and response")
    func testHTTPErrorWithDataAndResponse() {
        let data = "Not Found".data(using: .utf8)!
        let url = URL(string: "https://api.example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        let httpError = HTTPError(statusCode: 404, data: data, response: response)
        
        #expect(httpError.statusCode == 404)
        #expect(httpError.data == data)
        #expect(httpError.response == response)
    }
    
    @Test("HTTPError status code properties")
    func testHTTPErrorStatusCodeProperties() {
        let clientError = HTTPError(statusCode: 404)
        let serverError = HTTPError(statusCode: 500)
        let successStatus = HTTPError(statusCode: 200)
        
        #expect(clientError.statusCode == 404)
        #expect(serverError.statusCode == 500)
        #expect(successStatus.statusCode == 200)
    }
}
