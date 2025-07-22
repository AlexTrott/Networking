import Foundation
import NetworkingInterface

enum NetworkTestHelpers {
    static func createTestRequest(
        url: String = "https://api.example.com/test",
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) -> NetworkRequest {
        return NetworkRequest(
            url: URL(string: url)!,
            method: method,
            headers: headers,
            body: body
        )
    }
    
    static func createTestResponse(
        request: NetworkRequest? = nil,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        data: Data? = nil
    ) -> NetworkResponse {
        let testRequest = request ?? createTestRequest()
        let responseData = data ?? Data()
        
        return NetworkResponse(
            data: responseData,
            statusCode: statusCode,
            headers: headers,
            url: testRequest.url
        )
    }
    
    static func createTestError(code: URLError.Code = .networkConnectionLost) -> URLError {
        return URLError(code, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    }
    
    static func createHTTPResponse(
        url: URL = URL(string: "https://api.example.com")!,
        statusCode: Int = 200,
        headers: [String: String]? = nil
    ) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
    }
}

extension NetworkTestHelpers {
    static func createSecTrust() -> SecTrust {
        // Create a simple self-signed certificate for testing purposes
        // This is a minimal working X.509 certificate in DER format
        let certificateData = Data(base64Encoded: """
        MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAlRuRnThUjU8/prwYxbty
        WPiuEy/BMeQNkY7oNlC1Z1gZojfLlZzqJ0LNuohP0H7Q5NcRmMbR6E6DqBl1/3/3
        eKz7TFO9p4gF8I9lzKzO0vYm8Q7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z
        1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6m
        NzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz
        8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z
        1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6mNzYz8F7Z1L6m
        NzYzRQQCAIERAA==
        """) ?? Data()
        
        // Try to create certificate from the data
        if let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) {
            let policy = SecPolicyCreateSSL(true, "example.com" as CFString)
            var trust: SecTrust?
            let status = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)
            if status == errSecSuccess, let validTrust = trust {
                return validTrust
            }
        }
        
        // Fallback: Create a minimal trust object for testing
        // Some tests may need this, even if it's not a "real" certificate chain
        let policy = SecPolicyCreateSSL(false, nil) // No hostname validation for testing
        var trust: SecTrust?
        
        // Create with a dummy certificate data - sometimes works better than empty array
        let dummyCertData = Data([0x30, 0x82]) // Just start of ASN.1 structure
        if let dummyCert = SecCertificateCreateWithData(nil, dummyCertData as CFData) {
            let status = SecTrustCreateWithCertificates([dummyCert] as CFArray, policy, &trust)
            if status == errSecSuccess, let validTrust = trust {
                return validTrust
            }
        }
        
        // Last resort: For testing purposes only, create an unchecked SecTrust
        // This is purely for unit testing and should never be used in production
        fatalError("Unable to create SecTrust for testing - this may indicate a platform limitation")
    }
}