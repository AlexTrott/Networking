//
//  ResponseInterceptor.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//


public protocol ResponseInterceptor: Sendable {
    func intercept(response: NetworkResponse, for request: NetworkRequest) async throws -> NetworkResponse
}
