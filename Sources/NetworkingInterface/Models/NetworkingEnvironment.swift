//
//  NetworkingEnvironment.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//


import Foundation

public struct NetworkingEnvironment: Sendable {
    public let baseURL: URL
    public let certificatePins: [String: [String]]
    public let allowsInsecureConnections: Bool

    public init(
        baseURL: URL,
        certificatePins: [String : [String]],
        allowsInsecureConnections: Bool
    ) {
        self.baseURL = baseURL
        self.certificatePins = certificatePins
        self.allowsInsecureConnections = allowsInsecureConnections
    }
}
