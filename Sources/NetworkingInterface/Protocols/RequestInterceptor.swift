//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//


public protocol RequestInterceptor: Sendable {
    func intercept(request: NetworkRequest) async throws -> NetworkRequest
}