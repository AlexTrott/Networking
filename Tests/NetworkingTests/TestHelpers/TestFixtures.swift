import Foundation
import NetworkingInterface

enum TestFixtures {
    static let validJSONString = """
    {
        "id": 123,
        "name": "Test User",
        "email": "test@example.com",
        "active": true
    }
    """
    
    static let invalidJSONString = """
    {
        "id": 123,
        "name": "Test User",
        "email": "test@example.com",
        "active": true
        // Missing closing brace - this is genuinely invalid JSON
    """
    
    static let emptyJSONString = "{}"
    
    static var validJSONData: Data {
        validJSONString.data(using: .utf8)!
    }
    
    static var invalidJSONData: Data {
        invalidJSONString.data(using: .utf8)!
    }
    
    static var emptyJSONData: Data {
        emptyJSONString.data(using: .utf8)!
    }
    
    static let testBearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
    static let testUserAgent = "TestApp/1.0 iOS/15.0"
    
    static let commonHeaders = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Cache-Control": "no-cache"
    ]
    
    static func createTestEnvironment(
        baseURL: String = "https://api.example.com",
        certificatePins: [String: [String]] = [:],
        allowInsecureConnections: Bool = false
    ) -> NetworkingEnvironment {
        return NetworkingEnvironment(
            baseURL: URL(string: baseURL)!,
            certificatePins: certificatePins,
            allowsInsecureConnections: allowInsecureConnections
        )
    }
}

struct TestModel: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
    let active: Bool
}

extension TestFixtures {
    static let testModel = TestModel(
        id: 123,
        name: "Test User",
        email: "test@example.com",
        active: true
    )
    
    static var testModelJSONData: Data {
        try! JSONEncoder().encode(testModel)
    }
}
