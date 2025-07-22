# Networking

A comprehensive, secure, and modern iOS networking library built with Swift 6.0 and designed for modular iOS applications.

## Features

- ✅ **Swift 6.0** with full concurrency support (`Sendable`, `async/await`, thread-safe)
- ✅ **iOS 15+** deployment target
- ✅ **Certificate Pinning** with TrustKit integration (thread-safe initialization)
- ✅ **Multi-Environment Support** (Development, Staging, Production)
- ✅ **Async/Await** throughout with proper concurrency handling
- ✅ **Protocol-Based Design** for testability and dependency injection
- ✅ **Request/Response Interceptors** for middleware functionality
- ✅ **Comprehensive Error Handling** with structured error types
- ✅ **Swift Testing** test suite (36+ tests, 100% concurrency compliant)
- ✅ **Generic & Modular** architecture with clean separation of concerns
- ✅ **Thread-Safe URLSession Management** with proper lifecycle handling
- ✅ **Comprehensive Test Coverage** with URLProtocolMock for network stubbing

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

The library uses a modern protocol-based environment configuration:

```swift
// NetworkingEnvironment protocol for flexible configuration
public protocol NetworkingEnvironment: Sendable {
    var baseURL: URL { get }
    var certificatePins: [String: [String]] { get }
    var allowInsecureConnections: Bool { get }
}

// Example implementation
public struct ProductionEnvironment: NetworkingEnvironment {
    public let baseURL = URL(string: "https://api.yourapp.com")!
    
    public let certificatePins = [
        "api.yourapp.com": [
            "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
            "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
        ]
    ]
    
    public let allowInsecureConnections = false
}
```

### Certificate Pinning

Certificate pinning is enabled by default and uses TrustKit for secure validation with **thread-safe eager initialization**:

1. **Extract certificate pins from your server:**
   ```bash
   openssl s_client -connect api.yourapp.com:443 -servername api.yourapp.com < /dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
   ```

2. **Thread-safe certificate pinning initialization:**
   ```swift
   // TrustKit is initialized eagerly and thread-safely in the constructor
   let certificatePinning = CertificatePinning(
       environment: environment,
       trustKit: RealTrustKit() // or MockTrustKit() for testing
   )
   ```

3. **For debugging, disable certificate pinning:**
   ```swift
   let debugEnvironment = TestEnvironment(allowInsecureConnections: true)
   let debugClient = NetworkingClient(environment: debugEnvironment)
   ```

## API Reference

### NetworkingClient

#### Initialization

```swift
// Primary initializer with NetworkingEnvironment protocol
public init(
    environment: any NetworkingEnvironment,
    requestInterceptors: [any RequestInterceptor] = [],
    responseInterceptors: [any ResponseInterceptor] = [],
    decoder: JSONDecoder = JSONDecoder(),
    trustKit: any TrustKitProtocol = RealTrustKit()
)

// Advanced initializer with custom session manager
public init(
    environment: any NetworkingEnvironment,
    requestInterceptors: [any RequestInterceptor] = [],
    responseInterceptors: [any ResponseInterceptor] = [],
    decoder: JSONDecoder = JSONDecoder(),
    sessionManager: any NetworkingSessionManagerProtocol
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

The library includes **36+ comprehensive tests** using Swift Testing with **100% Swift Concurrency compliance**:

```bash
swift test
```

### Test Coverage

- ✅ **NetworkingClient**: All HTTP methods, error handling, interceptors
- ✅ **Certificate Pinning**: Thread-safe initialization, TrustKit integration
- ✅ **Session Management**: URLSession lifecycle, proper cleanup
- ✅ **Request/Response Models**: Serialization, validation
- ✅ **Interceptors**: Authentication, User-Agent, Logging
- ✅ **Error Handling**: All error types, proper mapping
- ✅ **Mock Framework**: URLProtocolMock for network stubbing

### Test Features

- **URLProtocolMock**: Comprehensive network request stubbing
- **Thread-safe mocks**: All test mocks are `Sendable` compliant
- **Concurrency testing**: Async/await throughout test suite
- **Dependency injection**: Protocol-based design enables easy testing

### Running Tests in Xcode

1. Open the package in Xcode
2. Press `⌘+U` to run tests
3. View test results in the navigator

### Swift Concurrency Compliance

All tests and production code are fully compliant with Swift 6 strict concurrency:
- No `@unchecked Sendable` in production code
- Thread-safe initialization patterns
- Proper actor isolation
- Sendable protocol conformance throughout

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

## Architecture

### Key Design Principles

- **Protocol-Based**: All components implement protocols for testability and flexibility
- **Sendable Compliant**: Full Swift 6 concurrency support with thread-safe design
- **Dependency Injection**: Easy to mock and test all components
- **Separation of Concerns**: Clear boundaries between networking, security, and business logic

### Component Structure

```
├── NetworkingInterface/     # Public protocols and models
│   ├── Models/             # NetworkRequest, NetworkResponse, HTTPMethod
│   └── Protocols/          # NetworkingClientProtocol, interceptors
├── Networking/             # Core implementation
│   ├── NetworkingClient.swift          # Main client implementation
│   ├── NetworkingSessionManager.swift  # URLSession management
│   ├── CertificatePinning.swift       # TrustKit integration
│   └── Interceptors/                   # Built-in interceptors
└── Tests/                  # Comprehensive test suite
    ├── Mocks/             # URLProtocolMock, test doubles
    └── TestHelpers/       # Shared testing utilities
```

## Security

### Certificate Pinning

This library implements certificate pinning using TrustKit with **thread-safe eager initialization** to prevent man-in-the-middle attacks:

1. **Thread-Safe Initialization**: TrustKit is initialized once during CertificatePinning construction
2. **Real certificate pins in production**: Never use placeholder pins
3. **Backup pin ready**: Always have a secondary pin for certificate rotation
4. **Staging environment testing**: Thoroughly test certificate pinning before production
5. **Certificate monitoring**: Track certificate expiration dates

### Security Features

- **Eager TrustKit Initialization**: Prevents race conditions and ensures thread safety
- **Proper URLSession Lifecycle**: Sessions are properly cleaned up to prevent leaks
- **Secure by Default**: Certificate pinning enabled unless explicitly disabled
- **Protocol-Based Security**: Easy to audit and test security components

### Best Practices

- Always use HTTPS in production
- Implement proper authentication with interceptors
- Validate all user inputs before network requests
- Log security-relevant events with LoggingInterceptor
- Keep TrustKit dependency updated
- Use dependency injection for security components to enable testing

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/yourusername/Networking).