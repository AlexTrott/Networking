import Foundation
import NetworkingInterface

final class MockNetworkLogger: NetworkLogger, @unchecked Sendable {
    private var _loggedRequests: [NetworkRequest] = []
    private var _loggedResponses: [(NetworkResponse, NetworkRequest)] = []
    private let lock = NSLock()
    
    var loggedRequests: [NetworkRequest] {
        lock.withLock { _loggedRequests }
    }
    
    var loggedResponses: [(NetworkResponse, NetworkRequest)] {
        lock.withLock { _loggedResponses }
    }
    
    func logRequest(_ request: NetworkRequest) {
        lock.withLock {
            _loggedRequests.append(request)
        }
    }
    
    func logResponse(_ response: NetworkResponse, for request: NetworkRequest) {
        lock.withLock {
            _loggedResponses.append((response, request))
        }
    }
    
    func reset() {
        lock.withLock {
            _loggedRequests.removeAll()
            _loggedResponses.removeAll()
        }
    }
    
    var hasLoggedRequests: Bool {
        !loggedRequests.isEmpty
    }
    
    var hasLoggedResponses: Bool {
        !loggedResponses.isEmpty
    }
}

extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}