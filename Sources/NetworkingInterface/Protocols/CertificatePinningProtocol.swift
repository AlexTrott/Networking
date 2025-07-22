//
//  CertificatePinningProtocol.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation

public protocol CertificatePinningProtocol: Sendable {
    func canTrustServer(trust: SecTrust, forHostname hostname: String) -> Bool
}
