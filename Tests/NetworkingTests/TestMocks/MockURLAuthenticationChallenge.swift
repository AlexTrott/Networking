//
//  MockURLAuthenticationChallenge.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//
import Foundation

final class MockURLAuthenticationChallenge {
    let challenge: URLAuthenticationChallenge
    
    init(hasServerTrust: Bool = false, hostname: String = "example.com") {
        if hasServerTrust {
            // Try to create a SecTrust, but fall back gracefully if it fails
            var serverTrust: SecTrust?
            let policy = SecPolicyCreateBasicX509()
            let certificates: [SecCertificate] = []
            let status = SecTrustCreateWithCertificates(certificates as CFArray, policy, &serverTrust)
            
            if status == errSecSuccess, let validTrust = serverTrust {
                let mockProtectionSpace = MockURLProtectionSpace(
                    host: hostname,
                    port: 443,
                    protocol: NSURLProtectionSpaceHTTPS,
                    realm: nil,
                    authenticationMethod: NSURLAuthenticationMethodServerTrust,
                    serverTrust: validTrust
                )
                
                challenge = URLAuthenticationChallenge(
                    protectionSpace: mockProtectionSpace,
                    proposedCredential: nil,
                    previousFailureCount: 0,
                    failureResponse: nil,
                    error: nil,
                    sender: MockURLAuthenticationChallengeSender()
                )
            } else {
                // Fallback to no server trust
                let protectionSpace = URLProtectionSpace(
                    host: hostname,
                    port: 443,
                    protocol: NSURLProtectionSpaceHTTPS,
                    realm: nil,
                    authenticationMethod: NSURLAuthenticationMethodServerTrust
                )
                
                challenge = URLAuthenticationChallenge(
                    protectionSpace: protectionSpace,
                    proposedCredential: nil,
                    previousFailureCount: 0,
                    failureResponse: nil,
                    error: nil,
                    sender: MockURLAuthenticationChallengeSender()
                )
            }
        } else {
            let protectionSpace = URLProtectionSpace(
                host: hostname,
                port: 443,
                protocol: NSURLProtectionSpaceHTTPS,
                realm: nil,
                authenticationMethod: NSURLAuthenticationMethodServerTrust
            )
            
            challenge = URLAuthenticationChallenge(
                protectionSpace: protectionSpace,
                proposedCredential: nil,
                previousFailureCount: 0,
                failureResponse: nil,
                error: nil,
                sender: MockURLAuthenticationChallengeSender()
            )
        }
    }
}
