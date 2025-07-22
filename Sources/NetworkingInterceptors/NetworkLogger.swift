import Foundation
import os.log
import NetworkingInterface


public final class DefaultNetworkLogger: NetworkLogger {
    private let logger = Logger(subsystem: "com.networking", category: "NetworkLogger")
    
    public init() {}
    
    public func logRequest(_ request: NetworkRequest) {
        logger.info("🚀 Request: \(request.method.rawValue) \(request.url.absoluteString)")
        
        if !request.headers.isEmpty {
            logger.debug("Headers: \(request.headers)")
        }
        
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("Body: \(bodyString)")
        }
    }
    
    public func logResponse(_ response: NetworkResponse, for request: NetworkRequest) {
        let statusEmoji = response.isSuccessful ? "✅" : "❌"
        logger.info("\(statusEmoji) Response: \(response.statusCode) for \(request.url.absoluteString)")
        
        if !response.headers.isEmpty {
            logger.debug("Headers: \(response.headers)")
        }
        
        if let responseString = response.string {
            logger.debug("Body: \(responseString)")
        }
    }
}

public final class NoOpNetworkLogger: NetworkLogger {
    public init() {}
    
    public func logRequest(_ request: NetworkRequest) {}
    public func logResponse(_ response: NetworkResponse, for request: NetworkRequest) {}
}
