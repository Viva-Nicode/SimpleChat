//
//  SignalingClient.swift
//  SimpleChat
//
//  Created by Nicode . on 8/14/24.
//

import Foundation
import WebRTC

protocol SignalClientDelegate: AnyObject {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
    func signalClient(_ signalClient: SignalingClient, didReceiveStringMessage: SignalingMessage)
}

final class SignalingClient {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let webSocket: WebSocketProvider
    weak var delegate: SignalClientDelegate?

    init(webSocket: WebSocketProvider) { self.webSocket = webSocket }

    func disconnect() { webSocket.disconnect() }

    func connect() {
        self.webSocket.delegate = self
        self.webSocket.connect()
    }

    func send(sdp rtcSdp: RTCSessionDescription) {
        let message = Message.sdp(SessionDescription(from: rtcSdp))
        do {
            let dataMessage = try self.encoder.encode(message)

            self.webSocket.send(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }

    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate))
        do {
            let dataMessage = try self.encoder.encode(message)
            self.webSocket.send(data: dataMessage)
        }
        catch {
            debugPrint("Warning: Could not encode candidate: \(error)")
        }
    }

    func send(_ signalingMessage: SignalingMessage) {
        if let msg = signalingMessage.buildJsonString {
            self.webSocket.send(message: msg)
        } else {
            debugPrint("genrated error during build jsonString")
        }
    }
}


extension SignalingClient: WebSocketProviderDelegate {

    func webSocketDidConnect(_ webSocket: WebSocketProvider) {
        self.delegate?.signalClientDidConnect(self)
    }

    func webSocketDidDisconnect(_ webSocket: WebSocketProvider) {
        self.delegate?.signalClientDidDisconnect(self)
    }

    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
        let message: Message
        do {
            message = try self.decoder.decode(Message.self, from: data)
        } catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }

        switch message {
        case .candidate(let iceCandidate):
            self.delegate?.signalClient(self, didReceiveCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription.rtcSessionDescription)
        }
    }

    func webSocket(_ webSocket: WebSocketProvider, didReceiveString string: String) {
        do {
            let message = try string.DecodeToSignalingMessage()
            self.delegate?.signalClient(self, didReceiveStringMessage: message)
        } catch(let error) {
            print(error.localizedDescription)
            print("Received String : \(string)")
        }
    }
}
