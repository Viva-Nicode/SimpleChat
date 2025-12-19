import Foundation
import Combine
import WebRTC

class WebSocketHandler: NSObject, URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connection opened")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket connection closed")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("WebSocket task complete with error: \(error)")
        }
    }
}

class WebSocketManager {

    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables: Set<AnyCancellable> = []

    func connect() {
        if let email: String = UserDefaultsKeys.userEmail.value() {

            let url = URL(string: "ws://1.246.134.84/websocket?email=\"\(email)\"&roomid=\"fwiogwe-24g24g-g24g-224g\"")!
            let webSocketTask = URLSession.shared.webSocketTask(with: url)
            self.webSocketTask = webSocketTask

            webSocketTask.delegate = WebSocketHandler()
            webSocketTask.resume()
            receiveMessage()
        }
    }

    func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
            case .success(.string(let message)):
                print(message)
            case .success:
                break
            }
        }
    }

    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }

    func sendMessage(_ binaryData: Data) {
        let message = URLSessionWebSocketTask.Message.data(binaryData)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending data: \(error)")
            }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
