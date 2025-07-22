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
    private let lock = NSLock()
    
    // MARK: - Configuration Properties
    private var shouldReturnSuccessResponse = true
    private var mockResponseData: Data = Data()
    private var mockStatusCode: Int = 200
    private var mockHeaders: [String: String] = [:]
    private var mockError: Error?
    
    // MARK: - Tracking Properties
    private var performedRequests: [NetworkRequest] = []
    private var performCallCount = 0
    
    // MARK: - NetworkingSessionManagerProtocol Implementation
    
    func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
        recordRequest(request)
        
        // If an error is configured, throw it
        if let error = getError() {
            throw error
        }
        
        // Return configured mock response
        let response = buildResponse(for: request)
        return response
    }
    
    // MARK: - Thread-safe helper methods
    
    private func recordRequest(_ request: NetworkRequest) {
        lock.withLock {
            performedRequests.append(request)
            performCallCount += 1
        }
    }
    
    private func getError() -> Error? {
        return lock.withLock { mockError }
    }
    
    private func buildResponse(for request: NetworkRequest) -> NetworkResponse {
        let (data, statusCode, headers) = lock.withLock {
            (mockResponseData, mockStatusCode, mockHeaders)
        }
        
        return NetworkResponse(
            data: data,
            statusCode: statusCode,
            headers: headers,
            url: request.url
        )
    }
    
    // MARK: - Configuration Methods
    
    /// Configure the mock to return a successful response with the given data
    func configureSuccess(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
        lock.withLock {
            shouldReturnSuccessResponse = true
            mockResponseData = data
            mockStatusCode = statusCode
            mockHeaders = headers
            mockError = nil
        }
    }
    
    /// Configure the mock to return an HTTP error response
    func configureHTTPError(statusCode: Int, data: Data = Data(), headers: [String: String] = [:]) {
        lock.withLock {
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
    }
    
    /// Configure the mock to throw a specific error
    func configureError(_ error: Error) {
        lock.withLock {
            mockError = error
        }
    }
    
    /// Reset the mock to its default state
    func reset() {
        lock.withLock {
            shouldReturnSuccessResponse = true
            mockResponseData = Data()
            mockStatusCode = 200
            mockHeaders = [:]
            mockError = nil
            performedRequests.removeAll()
            performCallCount = 0
        }
    }
    
    // MARK: - Inspection Methods
    
    /// Get the number of times perform(_:) was called
    var callCount: Int {
        return lock.withLock { performCallCount }
    }
    
    /// Get a copy of all performed requests
    var requestHistory: [NetworkRequest] {
        return lock.withLock { performedRequests }
    }
    
    /// Check if a request was made with the given path
    func didReceiveRequest(withPath path: String) -> Bool {
        return lock.withLock {
            performedRequests.contains { request in
                request.url.path.hasSuffix(path)
            }
        }
    }
    
    /// Check if a request was made to the given URL
    func didReceiveRequest(withURL url: URL) -> Bool {
        return lock.withLock {
            performedRequests.contains { request in
                request.url == url
            }
        }
    }
    
    /// Check if a request was made with the given HTTP method
    func didReceiveRequest(withMethod method: HTTPMethod) -> Bool {
        return lock.withLock {
            performedRequests.contains { request in
                request.method == method
            }
        }
    }
    
    /// Check if a request was made with the given header
    func didReceiveRequest(withHeader header: String, value: String) -> Bool {
        return lock.withLock {
            performedRequests.contains { request in
                request.headers[header] == value
            }
        }
    }
    
    /// Check if a request was made with the given body
    func didReceiveRequest(withBody body: Data) -> Bool {
        return lock.withLock {
            performedRequests.contains { request in
                request.body == body
            }
        }
    }
    
    /// Get the most recent request, if any
    var lastRequest: NetworkRequest? {
        return lock.withLock { performedRequests.last }
    }
}


