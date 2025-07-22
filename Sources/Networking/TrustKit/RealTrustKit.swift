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
public final class RealTrustKit: TrustKitProtocol, Sendable {
    private let _isInitialized = Box(false)
    
    // Simple thread-safe box for storing a boolean
    private final class Box<T>: @unchecked Sendable {
        private var value: T
        private let lock = NSLock()
        
        init(_ value: T) {
            self.value = value
        }
        
        func get() -> T {
            lock.withLock { value }
        }
        
        func set(_ newValue: T) {
            lock.withLock { value = newValue }
        }
    }
    
    public init() {}
    
    public var isInitialized: Bool {
        _isInitialized.get()
    }
    
    public func initSharedInstance(withConfiguration config: [String: Any]) {
        guard !isInitialized else { return }
        TrustKit.initSharedInstance(withConfiguration: config)
        _isInitialized.set(true)
    }
    
    public var pinningValidator: PinningValidatorProtocol {
        guard isInitialized else {
            fatalError("TrustKit must be initialized before accessing pinningValidator")
        }
        return RealPinningValidator()
    }
}

/// Real implementation of PinningValidatorProtocol that wraps TrustKit's validator
private final class RealPinningValidator: PinningValidatorProtocol, Sendable {
    
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