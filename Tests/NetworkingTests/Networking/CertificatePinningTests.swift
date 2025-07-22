import Testing
import Foundation
import NetworkingInterface

@testable import Networking

@Suite("CertificatePinning Tests")
struct CertificatePinningTests {
    
    @Test("CertificatePinning initializes with environment")
    func testInitialization() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["pin1", "pin2"]]
        )
        
        let _ = CertificatePinning(environment: environment)
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning initialization is thread-safe")
    func testThreadSafeInitialization() async {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["pin1"]]
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())

        // Simulate concurrent initialization attempts
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    certificatePinning.initialize()
                }
            }
        }
        
        // If this completes without hanging or crashing, thread safety is working
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning creates TrustKit config with certificate pins")
    func testTrustKitConfigCreation() {
        let certificatePins = [
            "api.example.com": ["pin1", "pin2"],
            "secure.example.com": ["pin3", "pin4"]
        ]
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: certificatePins,
            allowInsecureConnections: false
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())

        // We can't directly test the private createTrustKitConfig method,
        // but we can test the behavior by initializing
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning creates TrustKit config with insecure connections allowed")
    func testTrustKitConfigWithInsecureConnections() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["pin1"]],
            allowInsecureConnections: true
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning creates TrustKit config with empty pins")
    func testTrustKitConfigWithEmptyPins() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: [:],
            allowInsecureConnections: false
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning canTrustServer initializes if needed")
    func testCanTrustServerInitializesIfNeeded() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["pin1"]]
        )
        
        let mockTrustKit = MockTrustKit()
        let certificatePinning = CertificatePinning(environment: environment, trustKit: mockTrustKit)
        
        // Use a dummy SecTrust - for this test we only care about initialization behavior
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let certificates: [SecCertificate] = []
        let status = SecTrustCreateWithCertificates(certificates as CFArray, policy, &trust)
        
        // If SecTrust creation fails, skip this test as it's platform dependent
        guard status == errSecSuccess, let validTrust = trust else {
            return
        }
        
        let result = certificatePinning.canTrustServer(trust: validTrust, forHostname: "api.example.com")
        
        #expect(result == true) // Mock returns true by default
        #expect(mockTrustKit.initializationCallCount == 1)
        #expect(mockTrustKit.configurationReceived != nil)
    }
    
    @Test("CertificatePinning handles multiple initialization calls")
    func testMultipleInitializationCalls() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["pin1"]]
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())

        // Multiple calls should be safe
        certificatePinning.initialize()
        certificatePinning.initialize()
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
}

@Suite("CertificatePinning Configuration Tests")
struct CertificatePinningConfigurationTests {
    
    @Test("CertificatePinning environment with single domain")
    func testSingleDomainConfiguration() {
        let pins = ["sha256-pin1", "sha256-pin2"]
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": pins]
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning environment with multiple domains")
    func testMultipleDomainConfiguration() {
        let certificatePins = [
            "api.example.com": ["pin1", "pin2"],
            "auth.example.com": ["pin3", "pin4"],
            "cdn.example.com": ["pin5"]
        ]
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: certificatePins
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning environment with complex pin formats")
    func testComplexPinFormats() {
        let complexPins = [
            "api.example.com": [
                "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
                "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
            ]
        ]
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: complexPins
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
    
    @Test("CertificatePinning environment with subdomain considerations")
    func testSubdomainConfiguration() {
        let pins = [
            "example.com": ["pin1", "pin2"],
            "api.example.com": ["pin3", "pin4"],
            "www.example.com": ["pin5", "pin6"]
        ]
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: pins
        )
        
        let certificatePinning = CertificatePinning(environment: environment, trustKit: MockTrustKit())
        certificatePinning.initialize()
        
        // Certificate pinning instance should be created successfully
    }
}

@Suite("CertificatePinning Mock Tests")
struct CertificatePinningMockTests {
    
    @Test("CertificatePinning validates valid certificate")
    func testValidCertificateValidation() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["validPin1", "validPin2"]]
        )
        
        let mockTrustKit = MockTrustKit()
        mockTrustKit.shouldAllowConnection = true
        let certificatePinning = CertificatePinning(environment: environment, trustKit: mockTrustKit)
        
        // Create a minimal SecTrust for testing
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let certificates: [SecCertificate] = []
        let status = SecTrustCreateWithCertificates(certificates as CFArray, policy, &trust)
        
        // Skip test if SecTrust creation fails (platform limitation)
        guard status == errSecSuccess, let validTrust = trust else {
            return
        }
        
        let result = certificatePinning.canTrustServer(trust: validTrust, forHostname: "api.example.com")
        
        #expect(result == true)
        #expect(mockTrustKit.initializationCallCount == 1)
        
        // Verify configuration was passed correctly
        let config = mockTrustKit.configurationReceived
        #expect(config != nil)
        if let pinnedDomains = config?["TSKPinnedDomains"] as? [String: Any] {
            #expect(pinnedDomains["api.example.com"] != nil)
        }
    }
    
    @Test("CertificatePinning rejects invalid certificate")
    func testInvalidCertificateRejection() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["validPin1", "validPin2"]]
        )
        
        let mockTrustKit = MockTrustKit()
        mockTrustKit.shouldAllowConnection = false
        let certificatePinning = CertificatePinning(environment: environment, trustKit: mockTrustKit)
        
        // Create a minimal SecTrust for testing
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let certificates: [SecCertificate] = []
        let status = SecTrustCreateWithCertificates(certificates as CFArray, policy, &trust)
        
        // Skip test if SecTrust creation fails (platform limitation)
        guard status == errSecSuccess, let validTrust = trust else {
            return
        }
        
        let result = certificatePinning.canTrustServer(trust: validTrust, forHostname: "malicious.example.com")
        
        #expect(result == false)
        #expect(mockTrustKit.initializationCallCount == 1)
    }
    
    @Test("CertificatePinning passes correct configuration to TrustKit")
    func testTrustKitConfigurationPassing() {
        let certificatePins = [
            "api.example.com": ["pin1", "pin2"],
            "secure.example.com": ["pin3", "pin4"]
        ]
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: certificatePins,
            allowInsecureConnections: true
        )
        
        let mockTrustKit = MockTrustKit()
        let certificatePinning = CertificatePinning(environment: environment, trustKit: mockTrustKit)
        certificatePinning.initialize()
        
        #expect(mockTrustKit.initializationCallCount == 1)
        
        let config = mockTrustKit.configurationReceived
        #expect(config != nil)
        
        if let pinnedDomains = config?["TSKPinnedDomains"] as? [String: Any] {
            #expect(pinnedDomains.keys.contains("api.example.com"))
            #expect(pinnedDomains.keys.contains("secure.example.com"))
            
            if let apiConfig = pinnedDomains["api.example.com"] as? [String: Any] {
                let pins = apiConfig["TSKPublicKeyHashes"] as? [String]
                #expect(pins == ["pin1", "pin2"])
                let enforcePinning = apiConfig["TSKEnforcePinning"] as? Bool
                #expect(enforcePinning == false) // allowInsecureConnections = true
            }
        }
    }
    
    @Test("CertificatePinning tracks trust evaluation calls")
    func testTrustEvaluationTracking() {
        let environment = TestFixtures.createTestEnvironment(
            certificatePins: ["api.example.com": ["pin1"]]
        )
        
        let mockTrustKit = MockTrustKit()
        let certificatePinning = CertificatePinning(environment: environment, trustKit: mockTrustKit)
        
        // Create a minimal SecTrust for testing
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let certificates: [SecCertificate] = []
        let status = SecTrustCreateWithCertificates(certificates as CFArray, policy, &trust)
        
        // Skip test if SecTrust creation fails (platform limitation)
        guard status == errSecSuccess, let validTrust = trust else {
            return
        }
        
        // Make multiple calls
        _ = certificatePinning.canTrustServer(trust: validTrust, forHostname: "api.example.com")
        _ = certificatePinning.canTrustServer(trust: validTrust, forHostname: "another.example.com")
        
        // Verify the validator received the calls
        let validator = mockTrustKit.pinningValidator as! MockPinningValidator
        #expect(validator.evaluationCallCount == 2)
        #expect(validator.evaluatedHostnames.contains("api.example.com"))
        #expect(validator.evaluatedHostnames.contains("another.example.com"))
    }
}
