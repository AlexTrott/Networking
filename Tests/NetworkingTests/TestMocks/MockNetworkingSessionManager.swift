//
//  MockNetworkingSessionManager.swift
//  NetworkingTests
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation
import NetworkingInterface

@testable import Networking

/// Mock implementation of NetworkingSessionManagerProtocol for testing
final class MockNetworkingSessionManager: NetworkingSessionManagerProtocol, @unchecked Sendable {
    
    // MARK: - Configuration Properties
    var shouldReturnSuccessResponse = true
    var mockResponseData: Data = Data()
    var mockStatusCode: Int = 200
    var mockHeaders: [String: String] = [:]
    var mockError: Error?
    
    // MARK: - Tracking Properties
    var performedRequests: [NetworkRequest] = []
    var performCallCount = 0
    
    // MARK: - NetworkingSessionManagerProtocol Implementation
    
    func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
        performedRequests.append(request)
        performCallCount += 1
        
        // If an error is configured, throw it
        if let error = mockError {
            throw error
        }
        
        // Return configured mock response
        let response = NetworkResponse(
            data: mockResponseData,
            statusCode: mockStatusCode,
            headers: mockHeaders,
            url: request.url
        )
        
        return response
    }
    
    // MARK: - Configuration Methods
    
    /// Configure the mock to return a successful response with the given data
    func configureSuccess(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
        shouldReturnSuccessResponse = true
        mockResponseData = data
        mockStatusCode = statusCode
        mockHeaders = headers
        mockError = nil
    }
    
    /// Configure the mock to return an HTTP error response
    func configureHTTPError(statusCode: Int, data: Data = Data(), headers: [String: String] = [:]) {
        mockStatusCode = statusCode
        mockResponseData = data
        mockHeaders = headers
        
        let httpError = HTTPError(
            statusCode: statusCode,
            data: data,
            response: nil
        )
        mockError = NetworkError.httpError(httpError)
    }
    
    /// Configure the mock to throw a specific error
    func configureError(_ error: Error) {
        mockError = error
    }
    
    /// Configure the mock to return a timeout error
    func configureTimeoutError() {
        mockError = NetworkError.timeout
    }
    
    /// Configure the mock to return a connection error
    func configureConnectionError() {
        let urlError = URLError(.networkConnectionLost)
        mockError = NetworkError.connectionError(urlError)
    }
    
    /// Reset the mock to its initial state
    func reset() {
        shouldReturnSuccessResponse = true
        mockResponseData = Data()
        mockStatusCode = 200
        mockHeaders = [:]
        mockError = nil
        performedRequests.removeAll()
        performCallCount = 0
    }
    
    // MARK: - Verification Methods
    
    /// Check if a request was made with the given path
    func didReceiveRequest(withPath path: String) -> Bool {
        return performedRequests.contains { request in
            request.url.path.hasSuffix(path)
        }
    }
    
    /// Get the last performed request
    var lastRequest: NetworkRequest? {
        return performedRequests.last
    }
    
    /// Check if a request was made with the given HTTP method
    func didReceiveRequest(withMethod method: HTTPMethod) -> Bool {
        return performedRequests.contains { request in
            request.method == method
        }
    }
    
    /// Check if a request was made with specific headers
    func didReceiveRequest(withHeaders headers: [String: String]) -> Bool {
        return performedRequests.contains { request in
            headers.allSatisfy { key, value in
                request.headers[key] == value
            }
        }
    }
}