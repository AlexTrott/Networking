import Foundation
import NetworkingInterface

@testable import Networking

final class MockURLSession: URLSessionProtocol {
    var dataToReturn: Data?
    var responseToReturn: URLResponse?
    var errorToReturn: Error?
    var requestsReceived: [URLRequest] = []
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestsReceived.append(request)
        
        if let error = errorToReturn {
            throw error
        }
        
        let data = dataToReturn ?? Data()
        let response = responseToReturn ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        return (data, response)
    }
    
    func configure(data: Data?, response: URLResponse?, error: Error?) {
        self.dataToReturn = data
        self.responseToReturn = response
        self.errorToReturn = error
    }
    
    func configureSuccess(data: Data, statusCode: Int = 200, headers: [String: String]? = nil) {
        self.dataToReturn = data
        self.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
        self.errorToReturn = nil
    }
    
    func configureError(_ error: Error) {
        self.dataToReturn = nil
        self.responseToReturn = nil
        self.errorToReturn = error
    }
    
    func reset() {
        dataToReturn = nil
        responseToReturn = nil
        errorToReturn = nil
        requestsReceived.removeAll()
    }
}

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}