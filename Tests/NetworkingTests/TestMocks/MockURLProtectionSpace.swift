//
//  MockURLProtectionSpace.swift
//  Networking
//
//  Created by Alex Trott on 22/07/2025.
//
import Foundation

final class MockURLProtectionSpace: URLProtectionSpace, @unchecked Sendable {
    private let _serverTrust: SecTrust?
    
    init(host: String, port: Int, protocol: String?, realm: String?, authenticationMethod: String?, serverTrust: SecTrust?) {
        self._serverTrust = serverTrust
        super.init(host: host, port: port, protocol: `protocol`, realm: realm, authenticationMethod: authenticationMethod)
    }
    
    required init?(coder: NSCoder) {
        self._serverTrust = nil
        super.init(coder: coder)
    }
    
    override var serverTrust: SecTrust? {
        return _serverTrust
    }
}
