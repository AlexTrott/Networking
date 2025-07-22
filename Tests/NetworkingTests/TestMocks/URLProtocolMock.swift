import Foundation

class URLProtocolMock: URLProtocol {
    private static let lock = NSLock()
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    nonisolated(unsafe) static var urlHandlers: [String: ((URLRequest) throws -> (HTTPURLResponse, Data?))] = [:]
    nonisolated(unsafe) static var requestsReceived: [URLRequest] = []
    
    override class func canInit(with request: URLRequest) -> Bool {
        lock.withLock {
            requestsReceived.append(request)
        }
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let handler = URLProtocolMock.lock.withLock { () -> ((URLRequest) throws -> (HTTPURLResponse, Data?))? in
            // First check for URL-specific handler
            if let url = request.url?.absoluteString,
               let urlHandler = URLProtocolMock.urlHandlers[url] {
                return urlHandler
            }
            // Fall back to global handler
            return URLProtocolMock.requestHandler
        }
        
        guard let handler = handler else {
            fatalError("Handler is unavailable")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
    
    static func configure(statusCode: Int = 200, data: Data? = nil, headers: [String: String]? = nil, url: URL = URL(string: "https://api.example.com")!) {
        lock.withLock {
            requestHandler = { request in
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )!
                return (response, data)
            }
        }
    }
    
    static func configure(error: Error) {
        lock.withLock {
            requestHandler = { _ in
                throw error
            }
        }
    }
    
    static func configure(customHandler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data?)) {
        lock.withLock {
            requestHandler = customHandler
        }
    }
    
    static func reset() {
        lock.withLock {
            requestHandler = nil
            urlHandlers.removeAll()
            requestsReceived.removeAll()
        }
    }
    
    static func setupForTesting() {
        URLProtocol.registerClass(URLProtocolMock.self)
    }
    
    static func teardownAfterTesting() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        reset()
    }
    
    static func configureForURL(_ urlString: String, statusCode: Int = 200, data: Data? = nil, headers: [String: String]? = nil) {
        lock.withLock {
            urlHandlers[urlString] = { request in
                let response = HTTPURLResponse(
                    url: URL(string: urlString)!,
                    statusCode: statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )!
                return (response, data)
            }
        }
    }
    
    static func configureForURL(_ urlString: String, error: Error) {
        lock.withLock {
            urlHandlers[urlString] = { _ in
                throw error
            }
        }
    }
    
    static func configuredURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 120.0
        config.urlCache = nil
        return config
    }
}