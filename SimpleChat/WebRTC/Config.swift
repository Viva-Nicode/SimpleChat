import Foundation

fileprivate let defaultSignalingServerUrl = URL(string: "ws://1.246.134.84/websocket")!

fileprivate let defaultIceServers = [
    "stun:stun.l.google.com:19302",
    "stun:stun1.l.google.com:19302",
    "stun:stun2.l.google.com:19302",
    "stun:stun3.l.google.com:19302",
    "stun:stun4.l.google.com:19302"
]

struct Config {
    let signalingServerUrl: URL
    let webRTCIceServers: [String]

//    static func getURL(email: String, roomid: String) -> URL {
//        let urlString = "ws://localhost:51699/websocket?email=\(email)&roomid=\(roomid)"
//        return URL(string: urlString)!
//    }

    static func getURL(email: String, roomid: String) -> URL {
        let urlString = "ws://1.246.134.84/websocket?email=\(email)&roomid=\(roomid)"
        return URL(string: urlString)!
    }

    static let `default` = Config(signalingServerUrl: defaultSignalingServerUrl, webRTCIceServers: defaultIceServers)
}
