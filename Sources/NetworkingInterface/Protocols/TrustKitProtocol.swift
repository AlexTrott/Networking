//
//  TrustKitProtocol.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation

/// Abstraction for TrustKit's trust decision types
public enum TSKTrustDecision: Sendable {
    case shouldAllowConnection
    case shouldBlockConnection
    case domainNotPinned
    case shouldPerformDefaultHandling
}

/// Protocol abstracting TrustKit's pinning validator functionality
public protocol PinningValidatorProtocol: Sendable {
    /// Evaluates whether a certificate chain should be trusted for a given hostname
    /// - Parameters:
    ///   - trust: The SecTrust object to evaluate
    ///   - hostname: The hostname being validated
    /// - Returns: The trust decision result
    func evaluateTrust(_ trust: SecTrust, forHostname hostname: String) -> TSKTrustDecision
}

/// Protocol abstracting TrustKit's main functionality
public protocol TrustKitProtocol: Sendable {
    /// Initialize the shared TrustKit instance with configuration
    /// - Parameter config: Dictionary containing TrustKit configuration
    func initSharedInstance(withConfiguration config: [String: Any])
    
    /// Access to the pinning validator for certificate evaluation
    var pinningValidator: PinningValidatorProtocol { get }
    
    /// Whether TrustKit has been initialized
    var isInitialized: Bool { get }
}