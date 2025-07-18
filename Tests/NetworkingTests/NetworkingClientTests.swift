import Testing
import Foundation
@testable import Networking


@Test("Environment configuration")
func testEnvironmentConfiguration() {
    let devEnv = Environment.development
    let stagingEnv = Environment.staging
    let prodEnv = Environment.production
    
    #expect(devEnv.baseURL.absoluteString == "https://dev-api.example.com")
    #expect(stagingEnv.baseURL.absoluteString == "https://staging-api.example.com")
    #expect(prodEnv.baseURL.absoluteString == "https://api.example.com")
    
    #expect(devEnv.allowsInsecureConnections == true)
    #expect(stagingEnv.allowsInsecureConnections == false)
    #expect(prodEnv.allowsInsecureConnections == false)
}

@Test("NetworkRequest creation")
func testNetworkRequestCreation() {
    let url = URL(string: "https://api.example.com/test")!
    let request = NetworkRequest.get(url: url, headers: ["Authorization": "Bearer token"])
    
    #expect(request.url == url)
    #expect(request.method == .GET)
    #expect(request.headers["Authorization"] == "Bearer token")
    #expect(request.body == nil)
    #expect(request.timeoutInterval == 60.0)
}

@Test("NetworkResponse decoding")
func testNetworkResponseDecoding() throws {
    struct TestModel: Codable {
        let id: Int
        let name: String
    }
    
    let testData = try JSONEncoder().encode(TestModel(id: 1, name: "Test"))
    let response = NetworkResponse(
        data: testData,
        statusCode: 200,
        headers: ["Content-Type": "application/json"],
        url: URL(string: "https://api.example.com/test")
    )
    
    #expect(response.isSuccessful == true)
    #expect(response.isClientError == false)
    #expect(response.isServerError == false)
    
    let decodedModel = try response.decode(TestModel.self)
    #expect(decodedModel.id == 1)
    #expect(decodedModel.name == "Test")
}

@Test("HTTPError properties")
func testHTTPErrorProperties() {
    let clientError = HTTPError(statusCode: 400)
    let serverError = HTTPError(statusCode: 500)
    let unauthorizedError = HTTPError(statusCode: 401)
    let forbiddenError = HTTPError(statusCode: 403)
    let notFoundError = HTTPError(statusCode: 404)
    
    #expect(clientError.isClientError == true)
    #expect(clientError.isServerError == false)
    
    #expect(serverError.isClientError == false)
    #expect(serverError.isServerError == true)
    
    #expect(unauthorizedError.isUnauthorized == true)
    #expect(forbiddenError.isForbidden == true)
    #expect(notFoundError.isNotFound == true)
}

@Test("NetworkError equality")
func testNetworkErrorEquality() {
    let error1 = NetworkError.invalidURL
    let error2 = NetworkError.invalidURL
    let error3 = NetworkError.noData
    
    #expect(error1 == error2)
    #expect(error1 != error3)
    
    let httpError1 = NetworkError.httpError(HTTPError(statusCode: 400))
    let httpError2 = NetworkError.httpError(HTTPError(statusCode: 400))
    let httpError3 = NetworkError.httpError(HTTPError(statusCode: 500))
    
    #expect(httpError1 == httpError2)
    #expect(httpError1 != httpError3)
}

@Test("HTTPMethod enum")
func testHTTPMethodEnum() {
    #expect(HTTPMethod.GET.rawValue == "GET")
    #expect(HTTPMethod.POST.rawValue == "POST")
    #expect(HTTPMethod.PUT.rawValue == "PUT")
    #expect(HTTPMethod.DELETE.rawValue == "DELETE")
    #expect(HTTPMethod.PATCH.rawValue == "PATCH")
    #expect(HTTPMethod.HEAD.rawValue == "HEAD")
    #expect(HTTPMethod.OPTIONS.rawValue == "OPTIONS")
}

@Test("Certificate pinning configuration")
func testCertificatePinningConfiguration() {
    let _ = CertificatePinning(environment: .development)
    let _ = CertificatePinning(environment: .production)
    
    // Certificate pinning objects successfully initialized
}

@Test("URLRequest conversion")
func testURLRequestConversion() {
    let url = URL(string: "https://api.example.com/test")!
    let headers = ["Authorization": "Bearer token", "Content-Type": "application/json"]
    let body = "test body".data(using: .utf8)
    
    let networkRequest = NetworkRequest(
        url: url,
        method: .POST,
        headers: headers,
        body: body,
        timeoutInterval: 30.0
    )
    
    let urlRequest = networkRequest.toURLRequest()
    
    #expect(urlRequest.url == url)
    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.timeoutInterval == 30.0)
    #expect(urlRequest.httpBody == body)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
}
