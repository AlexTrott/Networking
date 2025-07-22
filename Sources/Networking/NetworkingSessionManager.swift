import Foundation
import NetworkingInterface

public final class NetworkingSessionManager: NSObject, NetworkingSessionManagerProtocol {
    private let certificatePinning: CertificatePinningProtocol
    private let certificatePinningEnabled: Bool
    private let configuration: URLSessionConfiguration
    private let sessionHolder: SessionHolder
    private let delegateQueue: OperationQueue
    
    // Use a reference type to hold the session to maintain Sendable conformance
    private final class SessionHolder: @unchecked Sendable {
        private var _session: URLSession?
        private let lock = NSLock()
        
        func setSession(_ session: URLSession) {
            lock.lock()
            defer { lock.unlock() }
            _session = session
        }
        
        var session: URLSession {
            lock.lock()
            defer { lock.unlock() }
            guard let session = _session else {
                fatalError("URLSession accessed before initialization")
            }
            return session
        }
    }

    public init(
        certificatePinning: CertificatePinningProtocol,
        certificatePinningEnabled: Bool = true,
        configuration: URLSessionConfiguration? = nil
    ) {
        self.certificatePinning = certificatePinning
        self.certificatePinningEnabled = certificatePinningEnabled

        // Use provided configuration or create default
        if let configuration = configuration {
            self.configuration = configuration
        } else {
            self.configuration = URLSessionConfiguration.default
            self.configuration.timeoutIntervalForRequest = 60.0
            self.configuration.timeoutIntervalForResource = 120.0
        }
        
        // Create a dedicated queue for delegate callbacks
        self.delegateQueue = OperationQueue()
        self.delegateQueue.name = "com.networking.sessionManager.delegateQueue"
        self.delegateQueue.maxConcurrentOperationCount = 1
        
        self.sessionHolder = SessionHolder()
        
        super.init()
        
        // Now create the actual session with self as delegate
        let session = URLSession(
            configuration: self.configuration,
            delegate: self,
            delegateQueue: self.delegateQueue
        )
        self.sessionHolder.setSession(session)
    }
    
    deinit {
        // Properly invalidate the session to prevent memory leaks
        sessionHolder.session.invalidateAndCancel()
    }

    public func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
        let urlRequest = request.toURLRequest()
        
        do {
            let (data, response): (Data, URLResponse) = try await sessionHolder.session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidRequest
            }
            
            let networkResponse = NetworkResponse(data: data, response: httpResponse)
            
            if !networkResponse.isSuccessful {
                throw NetworkError.httpError(HTTPError(
                    statusCode: httpResponse.statusCode,
                    data: data,
                    response: httpResponse
                ))
            }
            
            return networkResponse
            
        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw NetworkError.timeout
            case .cancelled:
                throw NetworkError.cancelled
            default:
                throw NetworkError.connectionError(urlError)
            }
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}

extension NetworkingSessionManager: URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard certificatePinningEnabled else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let hostname = challenge.protectionSpace.host as String? else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if certificatePinning.canTrustServer(trust: serverTrust, forHostname: hostname) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// Make NetworkingSessionManager explicitly Sendable
extension NetworkingSessionManager: @unchecked Sendable {}