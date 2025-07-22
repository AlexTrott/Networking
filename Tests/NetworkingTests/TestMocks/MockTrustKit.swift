//
//  MockTrustKit.swift
//  NetworkingTests
//
//  Created by Alex Trott on 22/07/2025.
//

import Foundation
import NetworkingInterface

/// Mock implementation of TrustKitProtocol for testing
final class MockTrustKit: TrustKitProtocol, @unchecked Sendable {
    var shouldAllowConnection = true
    var configurationReceived: [String: Any]?
    var initializationCallCount = 0
    private var _isInitialized = false
    
    var isInitialized: Bool {
        _isInitialized
    }
    
    func initSharedInstance(withConfiguration config: [String: Any]) {
        configurationReceived = config
        initializationCallCount += 1
        _isInitialized = true
    }
    
    var pinningValidator: PinningValidatorProtocol {
        return MockPinningValidator(shouldAllow: shouldAllowConnection)
    }
    
    func reset() {
        shouldAllowConnection = true
        configurationReceived = nil
        initializationCallCount = 0
        _isInitialized = false
    }
}

/// Mock implementation of PinningValidatorProtocol for testing
final class MockPinningValidator: PinningValidatorProtocol, @unchecked Sendable {
    private let shouldAllow: Bool
    var evaluatedTrusts: [SecTrust] = []
    var evaluatedHostnames: [String] = []
    var evaluationCallCount = 0
    
    init(shouldAllow: Bool) {
        self.shouldAllow = shouldAllow
    }
    
    func evaluateTrust(_ trust: SecTrust, forHostname hostname: String) -> TSKTrustDecision {
        evaluatedTrusts.append(trust)
        evaluatedHostnames.append(hostname)
        evaluationCallCount += 1
        
        return shouldAllow ? .shouldAllowConnection : .shouldBlockConnection
    }
    
    func reset() {
        evaluatedTrusts.removeAll()
        evaluatedHostnames.removeAll()
        evaluationCallCount = 0
    }
}