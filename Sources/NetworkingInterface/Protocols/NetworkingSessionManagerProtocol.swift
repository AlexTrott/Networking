//
//  NetworkingSessionManagerProtocol.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation

/// Protocol defining the core networking session management functionality
public protocol NetworkingSessionManagerProtocol: Sendable {
    /// Performs a network request and returns the response
    /// - Parameter request: The network request to perform
    /// - Returns: The network response
    /// - Throws: NetworkError for various failure scenarios
    func perform(_ request: NetworkRequest) async throws -> NetworkResponse
}