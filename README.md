# Networking

A comprehensive, secure, and modern iOS networking library built with Swift 6.0 and designed for modular iOS applications.

## Features

- ✅ **Swift 6.0** with full concurrency support
- ✅ **iOS 15+** deployment target
- ✅ **Certificate Pinning** with TrustKit integration
- ✅ **Multi-Environment Support** (Development, Staging, Production)
- ✅ **Async/Await** throughout
- ✅ **Protocol-Based Design** for testability
- ✅ **Request/Response Interceptors** for middleware functionality
- ✅ **Comprehensive Error Handling**
- ✅ **Swift Testing** test suite
- ✅ **Generic & Modular** architecture

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Networking.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Choose version requirements

## Quick Start

### Basic Usage

```swift
import Networking

// Initialize the client
let client = NetworkingClient(environment: .production)

// Make a GET request
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

do {
    let user = try await client.get(User.self, path: "/users/123")
    print("User: \(user.name)")
} catch {
    print("Error: \(error)")
}
```

### Advanced Configuration

```swift
let client = NetworkingClient(
    environment: .production,
    requestInterceptors: [
        AuthenticationInterceptor { await getAuthToken() },
        UserAgentInterceptor(userAgent: "MyApp/1.0"),
        LoggingInterceptor()
    ],
    responseInterceptors: [
        LoggingInterceptor()
    ],
    decoder: customJSONDecoder,
    certificatePinningEnabled: true // Default: true
)
```

## Configuration

### Environment Setup

Update the `Environment.swift` file with your actual endpoints and certificate pins:

```swift
public enum Environment: String, CaseIterable, Sendable {
    case development
    case staging
    case production
    
    public var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "https://dev-api.yourapp.com")!
        case .staging:
            return URL(string: "https://staging-api.yourapp.com")!
        case .production:
            return URL(string: "https://api.yourapp.com")!
        }
    }
    
    public var certificatePins: [String: [String]] {
        switch self {
        case .development:
            return [
                "dev-api.yourapp.com": [
                    "YOUR_DEV_CERTIFICATE_PIN_1",
                    "YOUR_DEV_CERTIFICATE_PIN_2"
                ]
            ]
        // ... other environments
        }
    }
}
```

### Certificate Pinning

Certificate pinning is enabled by default and uses TrustKit for secure validation. To get your certificate pins:

1. **Extract certificate pins from your server:**
   ```bash
   openssl s_client -connect api.yourapp.com:443 -servername api.yourapp.com < /dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
   ```

2. **For debugging, disable certificate pinning:**
   ```swift
   let debugClient = NetworkingClient(
       environment: .development,
       certificatePinningEnabled: false
   )
   ```

## API Reference

### NetworkingClient

#### Initialization

```swift
public init(
    environment: Environment,
    requestInterceptors: [RequestInterceptor] = [],
    responseInterceptors: [ResponseInterceptor] = [],
    decoder: JSONDecoder = JSONDecoder(),
    certificatePinningEnabled: Bool = true
)
```

#### HTTP Methods

```swift
// GET request
func get<T: Decodable>(_ type: T.Type, path: String, headers: [String: String] = [:]) async throws -> T
func get<T: Decodable>(_ type: T.Type, from url: URL, headers: [String: String] = [:]) async throws -> T

// POST request
func post<T: Decodable>(_ type: T.Type, path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T
func post<T: Decodable>(_ type: T.Type, to url: URL, body: Data? = nil, headers: [String: String] = [:]) async throws -> T

// PUT request
func put<T: Decodable>(_ type: T.Type, path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T
func put<T: Decodable>(_ type: T.Type, to url: URL, body: Data? = nil, headers: [String: String] = [:]) async throws -> T

// DELETE request
func delete(path: String, headers: [String: String] = [:]) async throws -> NetworkResponse
func delete(from url: URL, headers: [String: String] = [:]) async throws -> NetworkResponse

// Raw request
func perform(_ request: NetworkRequest) async throws -> NetworkResponse
```

### NetworkRequest

```swift
let request = NetworkRequest(
    url: URL(string: "https://api.example.com/users")!,
    method: .GET,
    headers: ["Authorization": "Bearer token"],
    body: nil,
    timeoutInterval: 60.0
)

// Convenience methods
let getRequest = NetworkRequest.get(url: url, headers: headers)
let postRequest = NetworkRequest.post(url: url, headers: headers, body: data)
let putRequest = NetworkRequest.put(url: url, headers: headers, body: data)
let deleteRequest = NetworkRequest.delete(url: url, headers: headers)
```

### NetworkResponse

```swift
struct NetworkResponse {
    let data: Data
    let statusCode: Int
    let headers: [String: String]
    let url: URL?
    
    var isSuccessful: Bool { (200...299).contains(statusCode) }
    var isClientError: Bool { (400...499).contains(statusCode) }
    var isServerError: Bool { (500...599).contains(statusCode) }
    
    func decode<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T
    var string: String? { String(data: data, encoding: .utf8) }
    var json: Any? { try? JSONSerialization.jsonObject(with: data) }
}
```

## Interceptors

### Built-in Interceptors

#### Authentication Interceptor
```swift
let authInterceptor = AuthenticationInterceptor { () async -> String? in
    return await TokenManager.shared.getToken()
}
```

#### User Agent Interceptor
```swift
let userAgentInterceptor = UserAgentInterceptor(userAgent: "MyApp/1.0 (iOS)")
```

#### Logging Interceptor
```swift
let loggingInterceptor = LoggingInterceptor() // Uses default logger
let customLoggingInterceptor = LoggingInterceptor(logger: MyCustomLogger())
```

### Custom Interceptors

```swift
public struct CustomHeaderInterceptor: RequestInterceptor {
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        var headers = request.headers
        headers["X-Custom-Header"] = "CustomValue"
        
        return NetworkRequest(
            url: request.url,
            method: request.method,
            headers: headers,
            body: request.body,
            timeoutInterval: request.timeoutInterval
        )
    }
}
```

## Error Handling

```swift
do {
    let user = try await client.get(User.self, path: "/users/123")
} catch NetworkError.httpError(let httpError) {
    switch httpError.statusCode {
    case 401:
        // Handle unauthorized
        break
    case 404:
        // Handle not found
        break
    case 500...599:
        // Handle server errors
        break
    default:
        // Handle other HTTP errors
        break
    }
} catch NetworkError.decodingFailed(let error) {
    // Handle JSON decoding errors
    print("Failed to decode response: \(error)")
} catch NetworkError.connectionError(let urlError) {
    // Handle connection issues
    print("Connection error: \(urlError.localizedDescription)")
} catch NetworkError.certificatePinningFailed {
    // Handle certificate pinning failures
    print("Certificate pinning validation failed")
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
```

### NetworkError Types

- `invalidURL` - The URL is malformed
- `invalidRequest` - The request is invalid
- `noData` - No data received from server
- `decodingFailed(Error)` - JSON decoding failed
- `encodingFailed(Error)` - Request encoding failed
- `httpError(HTTPError)` - HTTP error with status code
- `connectionError(URLError)` - Network connection error
- `certificatePinningFailed` - Certificate validation failed
- `timeout` - Request timed out
- `cancelled` - Request was cancelled
- `unknown(Error)` - Unknown error occurred

## Examples

### Complete Example

```swift
import Networking

class UserService {
    private let client: NetworkingClient
    
    init() {
        self.client = NetworkingClient(
            environment: .production,
            requestInterceptors: [
                AuthenticationInterceptor { await AuthManager.shared.token },
                UserAgentInterceptor(userAgent: "MyApp/1.0"),
                LoggingInterceptor()
            ],
            responseInterceptors: [
                LoggingInterceptor()
            ]
        )
    }
    
    func getUser(id: Int) async throws -> User {
        return try await client.get(User.self, path: "/users/\(id)")
    }
    
    func createUser(_ user: CreateUserRequest) async throws -> User {
        let data = try JSONEncoder().encode(user)
        return try await client.post(User.self, path: "/users", body: data)
    }
    
    func updateUser(id: Int, _ user: UpdateUserRequest) async throws -> User {
        let data = try JSONEncoder().encode(user)
        return try await client.put(User.self, path: "/users/\(id)", body: data)
    }
    
    func deleteUser(id: Int) async throws {
        _ = try await client.delete(path: "/users/\(id)")
    }
}
```

### Mock for Testing

```swift
class MockNetworkingClient: NetworkingClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    
    func perform(_ request: NetworkRequest) async throws -> NetworkResponse {
        if let error = mockError {
            throw error
        }
        
        let data = try JSONSerialization.data(withJSONObject: mockResponse ?? [:])
        return NetworkResponse(data: data, statusCode: 200, headers: [:], url: request.url)
    }
    
    func get<T: Decodable>(_ type: T.Type, from url: URL, headers: [String: String]) async throws -> T {
        let response = try await perform(NetworkRequest.get(url: url, headers: headers))
        return try response.decode(type)
    }
    
    // ... implement other methods
}
```

## Testing

The library includes comprehensive tests using Swift Testing:

```bash
swift test
```

### Running Tests in Xcode

1. Open the package in Xcode
2. Press `⌘+U` to run tests
3. View test results in the navigator

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 15.0+

## Dependencies

- [TrustKit](https://github.com/datatheorem/TrustKit) - Certificate pinning and security

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security

### Certificate Pinning

This library implements certificate pinning using TrustKit to prevent man-in-the-middle attacks. Ensure you:

1. Use real certificate pins in production
2. Have a backup pin ready for certificate rotation
3. Test certificate pinning thoroughly in your staging environment
4. Monitor certificate expiration dates

### Best Practices

- Always use HTTPS in production
- Implement proper authentication
- Validate all user inputs
- Log security-relevant events
- Keep dependencies updated

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/yourusername/Networking).