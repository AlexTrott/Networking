import Foundation
import NetworkingInterface

public final class NetworkingSessionManager: NSObject, NetworkingSessionManagerProtocol, Sendable {
    private let certificatePinning: CertificatePinningProtocol
    private let certificatePinningEnabled: Bool
    private let configuration: URLSessionConfiguration
    private let session: URLSession? = nil

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
    }

    func createSession() -> URLSession {
        URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    public func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
        let session = createSession()
        let urlRequest = request.toURLRequest()
        
        do {
            let (data, response): (Data, URLResponse) = try await session.data(for: urlRequest)

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
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
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
