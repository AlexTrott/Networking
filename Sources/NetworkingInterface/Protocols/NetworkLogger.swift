//
//  NetworkLogger.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//


public protocol NetworkLogger: Sendable {
    func logRequest(_ request: NetworkRequest)
    func logResponse(_ response: NetworkResponse, for request: NetworkRequest)
}