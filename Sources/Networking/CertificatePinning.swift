import Foundation
import TrustKit
import NetworkingInterface

public final class CertificatePinning: CertificatePinningProtocol, @unchecked Sendable {
    private let environment: NetworkingEnvironment
    private let trustKit: TrustKitProtocol
    private var isInitialized = false
    private let initializationLock = NSLock()
    
    public init(environment: NetworkingEnvironment, trustKit: TrustKitProtocol = RealTrustKit()) {
        self.environment = environment
        self.trustKit = trustKit
    }
    
    public func initialize() {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        guard !isInitialized else { return }
        
        let trustKitConfig = createTrustKitConfig()
        trustKit.initSharedInstance(withConfiguration: trustKitConfig)
        isInitialized = true
    }
    
    private func createTrustKitConfig() -> [String: Any] {
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
        if !isInitialized {
            initialize()
        }
        
        let validator = trustKit.pinningValidator
        let result = validator.evaluateTrust(trust, forHostname: hostname)
        
        // TSKTrustDecision.shouldAllowConnection means trust is valid
        return result == .shouldAllowConnection
    }
}
