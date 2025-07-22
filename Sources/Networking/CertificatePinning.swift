import Foundation
import TrustKit
import NetworkingInterface

public final class CertificatePinning: CertificatePinningProtocol, Sendable {
    private let environment: NetworkingEnvironment
    private let trustKit: TrustKitProtocol
    
    // Initialize TrustKit eagerly to avoid the need for lazy initialization
    public init(environment: NetworkingEnvironment, trustKit: TrustKitProtocol = RealTrustKit()) {
        self.environment = environment
        self.trustKit = trustKit
        
        // Eagerly initialize TrustKit to avoid thread safety concerns
        let trustKitConfig = Self.createTrustKitConfig(for: environment)
        trustKit.initSharedInstance(withConfiguration: trustKitConfig)
    }
    
    // Make this a static method to avoid self access during init
    private static func createTrustKitConfig(for environment: NetworkingEnvironment) -> [String: Any] {
        var pinnedDomains: [String: Any] = [:]
        
        for (domain, pins) in environment.certificatePins {
            pinnedDomains[domain] = [
                kTSKPublicKeyHashes: pins,
                kTSKEnforcePinning: !environment.allowsInsecureConnections,
                kTSKReportUris: [] as [String],
                kTSKIncludeSubdomains: false
            ]
        }
        
        return [
            kTSKPinnedDomains: pinnedDomains,
            kTSKSwizzleNetworkDelegates: false
        ]
    }
    
    public func canTrustServer(trust: SecTrust, forHostname hostname: String) -> Bool {
        // TrustKit is already initialized in init, so we can directly use it
        let validator = trustKit.pinningValidator
        let result = validator.evaluateTrust(trust, forHostname: hostname)
        
        // TSKTrustDecision.shouldAllowConnection means trust is valid
        return result == .shouldAllowConnection
    }
}