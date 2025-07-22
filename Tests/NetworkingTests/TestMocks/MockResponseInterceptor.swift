//
//  MockResponseInterceptor.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//
import Foundation
import NetworkingInterface

@testable import Networking

final class MockResponseInterceptor: ResponseInterceptor, @unchecked Sendable {
    var lastInterceptedResponse: NetworkResponse?
    var lastInterceptedRequest: NetworkRequest?
    var shouldThrowError: Error?
    var responseModifier: ((NetworkResponse, NetworkRequest) -> NetworkResponse)?
    
    func intercept(response: NetworkResponse, for request: NetworkRequest) async throws -> NetworkResponse {
        if let error = shouldThrowError {
            throw error
        }
        
        lastInterceptedResponse = response
        lastInterceptedRequest = request
        return responseModifier?(response, request) ?? response
    }
}
