//
//  NetworkingClientProtocol.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation

public protocol NetworkingClientProtocol: Sendable {
    func get<T: Decodable>(_ type: T.Type, path: String, headers: [String: String]) async throws -> T
    func post<T: Decodable>(_ type: T.Type, path: String, body: Data?, headers: [String: String]) async throws -> T
    func put<T: Decodable>(_ type: T.Type, path: String, body: Data?, headers: [String: String]) async throws -> T
    func delete(path: String, headers: [String: String]) async throws -> NetworkResponse
}
