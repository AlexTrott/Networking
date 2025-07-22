import Foundation
import NetworkingInterface

@testable import Networking

final class MockCertificatePinning: CertificatePinningProtocol, Sendable {
    private let state: State
    
    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var shouldPassCertificateValidation = true
        private var receivedTrusts: [SecTrust] = []
        private var receivedHostnames: [String] = []
        private var shouldThrowError: Error?
        
        func recordValidation(trust: SecTrust, hostname: String) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            
            receivedTrusts.append(trust)
            receivedHostnames.append(hostname)
            return shouldPassCertificateValidation
        }
        
        func configure(shouldPass: Bool) {
            lock.lock()
            defer { lock.unlock() }
            
            shouldPassCertificateValidation = shouldPass
            shouldThrowError = nil
        }
        
        func configure(error: Error) {
            lock.lock()
            defer { lock.unlock() }
            
            shouldThrowError = error
            shouldPassCertificateValidation = false
        }
        
        func getReceivedHostnames() -> [String] {
            lock.lock()
            defer { lock.unlock() }
            return receivedHostnames
        }
        
        func getReceivedTrustsCount() -> Int {
            lock.lock()
            defer { lock.unlock() }
            return receivedTrusts.count
        }
        
        func reset() {
            lock.lock()
            defer { lock.unlock() }
            
            shouldPassCertificateValidation = true
            receivedTrusts.removeAll()
            receivedHostnames.removeAll()
            shouldThrowError = nil
        }
    }
    
    init() {
        self.state = State()
    }
    
    func canTrustServer(trust: SecTrust, forHostname hostname: String) -> Bool {
        return state.recordValidation(trust: trust, hostname: hostname)
    }
    
    func configure(shouldPass: Bool) {
        state.configure(shouldPass: shouldPass)
    }
    
    func configure(error: Error) {
        state.configure(error: error)
    }
    
    var receivedHostnames: [String] {
        return state.getReceivedHostnames()
    }
    
    var receivedTrusts: [SecTrust] {
        // Note: We can't expose actual SecTrusts due to thread safety, so return empty array
        // Tests should use receivedTrustsCount instead
        return []
    }
    
    var receivedTrustsCount: Int {
        return state.getReceivedTrustsCount()
    }
    
    func getReceivedHostnames() -> [String] {
        return state.getReceivedHostnames()
    }
    
    func getReceivedTrustsCount() -> Int {
        return state.getReceivedTrustsCount()
    }
    
    func reset() {
        state.reset()
    }
}