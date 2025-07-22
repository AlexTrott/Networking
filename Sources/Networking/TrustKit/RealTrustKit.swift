//
//  RealTrustKit.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation
import TrustKit
import NetworkingInterface

/// Real implementation of TrustKitProtocol that wraps the actual TrustKit library
public final class RealTrustKit: TrustKitProtocol, @unchecked Sendable {
    private var _isInitialized = false
    private let initLock = NSLock()
    
    public init() {}
    
    public var isInitialized: Bool {
        initLock.withLock { _isInitialized }
    }
    
    public func initSharedInstance(withConfiguration config: [String: Any]) {
        initLock.withLock {
            guard !_isInitialized else { return }
            TrustKit.initSharedInstance(withConfiguration: config)
            _isInitialized = true
        }
    }
    
    public var pinningValidator: PinningValidatorProtocol {
        guard isInitialized else {
            fatalError("TrustKit must be initialized before accessing pinningValidator")
        }
        return RealPinningValidator()
    }
}

/// Real implementation of PinningValidatorProtocol that wraps TrustKit's validator
private final class RealPinningValidator: PinningValidatorProtocol, @unchecked Sendable {
    
    func evaluateTrust(_ trust: SecTrust, forHostname hostname: String) -> NetworkingInterface.TSKTrustDecision {
        let trustKit = TrustKit.sharedInstance()
        let validator = trustKit.pinningValidator
        let result = validator.evaluateTrust(trust, forHostname: hostname)
        
        // Convert TrustKit's TSKTrustDecision to our abstracted enum
        switch result {
        case .shouldAllowConnection:
            return .shouldAllowConnection
        case .shouldBlockConnection:
            return .shouldBlockConnection
        case .domainNotPinned:
            return .domainNotPinned
        @unknown default:
            return .shouldPerformDefaultHandling
        }
    }
}

extension NSLock {
    func withLock<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}