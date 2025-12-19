import Foundation

final class MockURLProtocol: URLProtocol {

    enum ResponseType {
        case error(Error)
        case success(HTTPURLResponse)
    }

    static var responseType: ResponseType!
    static var dtoType: MockDTOType!

    private lazy var session: URLSession = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration)
    }()

    private(set) var activeTask: URLSessionTask?

    override class func canInit(with request: URLRequest) -> Bool { return true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }

    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool { return false }

    override func startLoading() {
        let response = setUpMockResponse()
        let data = setUpMockData()

        client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data!)

        self.client?.urlProtocolDidFinishLoading(self)
        activeTask = session.dataTask(with: request.url!)
        activeTask?.cancel()
    }


    private func setUpMockResponse() -> HTTPURLResponse? {
        var response: HTTPURLResponse?
        switch MockURLProtocol.responseType {
        case .error(let error)?:
            client?.urlProtocol(self, didFailWithError: error)
        case .success(let newResponse)?:
            response = newResponse
        default:
            fatalError("No fake responses found.")
        }
        return response!
    }

    private func setUpMockData() -> Data? { MockURLProtocol.dtoType.responseData }

    override func stopLoading() { activeTask?.cancel() }
}

extension MockURLProtocol {

    enum MockError: Error {
        case none
    }

    static func responseWithFailure() {
        MockURLProtocol.responseType = MockURLProtocol.ResponseType.error(MockError.none)
    }

    static func responseWithStatusCode(code: Int) {
        MockURLProtocol.responseType = MockURLProtocol.ResponseType.success(
            HTTPURLResponse(url: URL(string: "http://dummyURL.com")!, statusCode: code, httpVersion: nil, headerFields: nil)!)
    }

    static func responseWithDTO(type: MockDTOType) {
        MockURLProtocol.dtoType = type
    }
}

extension MockURLProtocol {
    enum MockDTOType {
        case createNewChatroom_1
        case createNewChatroom_2
        case test_sendMessage_successful
        case test_sendMessage_failed_roomNotFound
    }
}
