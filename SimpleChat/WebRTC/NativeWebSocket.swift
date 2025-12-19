import Foundation

@available(iOS 13.0, *)
class NativeWebSocket: NSObject, WebSocketProvider {

    var delegate: WebSocketProviderDelegate?
    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private lazy var urlSession: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    init(url: URL) {
        self.url = url
        super.init()
    }

    func connect() {
        let socket = urlSession.webSocketTask(with: url)
        self.socket = socket
        self.socket?.resume()
        self.readMessage()
    }

    func send(data: Data) { self.socket?.send(.data(data)) { _ in } }

    func send(message: String) { self.socket?.send(.string(message)) { _ in } }

    private func readMessage() {
        self.socket?.receive { [weak self] message in
            guard let self = self else { return }

            print("receive message : \(message)")
            switch message {

            case .success(.data(let data)):
                self.delegate?.webSocket(self, didReceiveData: data)
                self.readMessage()

            case .success(.string(let message)):
                self.delegate?.webSocket(self, didReceiveString: message)
                self.readMessage()

            case .success:
                self.readMessage()

            case .failure(let error):
                debugPrint("receive failure : \(error.localizedDescription)")
                self.disconnect()
            }
        }
    }

    func disconnect() {
        self.socket?.cancel()
        self.socket = nil
        self.delegate?.webSocketDidDisconnect(self)
    }
}

@available(iOS 13.0, *)
extension NativeWebSocket: URLSessionWebSocketDelegate, URLSessionDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        debugPrint("urlSession signaling connected")
        self.delegate?.webSocketDidConnect(self)
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        debugPrint("urlSession signaling disconnected")
        self.disconnect()
    }
}
