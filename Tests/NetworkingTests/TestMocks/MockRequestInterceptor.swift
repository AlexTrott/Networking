//
//  MockRequestInterceptor.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation
import NetworkingInterface

@testable import Networking

final class MockRequestInterceptor: RequestInterceptor, @unchecked Sendable {
    var lastInterceptedRequest: NetworkRequest?
    var shouldThrowError: Error?
    var requestModifier: ((NetworkRequest) -> NetworkRequest)?
    
    func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        if let error = shouldThrowError {
            throw error
        }
        
        lastInterceptedRequest = request
        return requestModifier?(request) ?? request
    }
}
