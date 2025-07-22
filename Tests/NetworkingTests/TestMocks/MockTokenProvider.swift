import Foundation
import NetworkingInterface

final class MockTokenProvider {
    var tokenToReturn: String?
    var errorToThrow: Error?
    var callCount = 0
    var shouldDelay = false
    var delayDuration: TimeInterval = 0.1
    
    func provideToken() async throws -> String? {
        callCount += 1
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if let error = errorToThrow {
            throw error
        }
        
        return tokenToReturn
    }
    
    func configure(token: String?) {
        self.tokenToReturn = token
        self.errorToThrow = nil
    }
    
    func configure(error: Error) {
        self.errorToThrow = error
        self.tokenToReturn = nil
    }
    
    func configure(delay: TimeInterval) {
        self.shouldDelay = true
        self.delayDuration = delay
    }
    
    func reset() {
        tokenToReturn = nil
        errorToThrow = nil
        callCount = 0
        shouldDelay = false
        delayDuration = 0.1
    }
}

enum MockTokenError: Error {
    case tokenExpired
    case networkUnavailable
    case unauthorized
}