import Foundation
import NetworkingInterface

@testable import Networking

final class MockCertificatePinning: CertificatePinningProtocol, @unchecked Sendable {

    var shouldPassCertificateValidation = true
    var receivedTrusts: [SecTrust] = []
    var receivedHostnames: [String] = []
    var shouldThrowError: Error?
    
    func canTrustServer(trust: SecTrust, forHostname hostname: String) -> Bool {
        receivedTrusts.append(trust)
        receivedHostnames.append(hostname)
        return shouldPassCertificateValidation
    }
    
    func configure(shouldPass: Bool) {
        shouldPassCertificateValidation = shouldPass
        shouldThrowError = nil
    }
    
    func configure(error: Error) {
        shouldThrowError = error
        shouldPassCertificateValidation = false
    }
    
    func reset() {
        shouldPassCertificateValidation = true
        receivedTrusts.removeAll()
        receivedHostnames.removeAll()
        shouldThrowError = nil
    }
}


