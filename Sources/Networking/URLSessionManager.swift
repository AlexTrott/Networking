import Foundation

public final class URLSessionManager: NSObject, Sendable {
    private let certificatePinning: CertificatePinning
    private let certificatePinningEnabled: Bool
    private let configuration: URLSessionConfiguration
    private let session: URLSession? = nil

    public init(certificatePinning: CertificatePinning, certificatePinningEnabled: Bool = true) {
        self.certificatePinning = certificatePinning
        self.certificatePinningEnabled = certificatePinningEnabled

        // pull out
        self.configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 120.0
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

extension URLSessionManager: URLSessionDelegate {
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
