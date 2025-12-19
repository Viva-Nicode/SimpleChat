import Foundation
import WebRTC
import SwiftUI


class MediaViewModel: ObservableObject {

    @Published var signalingConnected = false
    @Published var hasLocalSdp = false
    @Published var localCandidateCount = 0
    @Published var hasRemoteSdp = false
    @Published var remoteCandidateCount = 0
    @Published var speakerOn = false
    @Published var mute = false
    @Published var webRTCStatus = "new"
    @Published var chatroomid: String = ""
    @Published var joinedMembers: [String] = []

    let webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
    var signalClient: SignalingClient

    init(roomid: String) {

        let email: String = UserDefaultsKeys.userEmail.value()!
        self.chatroomid = roomid

        let webSocketProvider: WebSocketProvider
        webSocketProvider = NativeWebSocket(url: Config.getURL(email: email, roomid: roomid))
        self.signalClient = SignalingClient(webSocket: webSocketProvider)

        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
    }

    func connectSignalClient() { signalClient.connect() }

    func offer() {
        webRTCClient.offer { (sdp) in
            withAnimation(.easeInOut(duration: 0.25)) { self.hasLocalSdp = true }
            self.signalClient.send(sdp: sdp)
        }
    }

    func answer() {
        webRTCClient.answer { (localSdp) in
            withAnimation(.easeInOut(duration: 0.25)) { self.hasLocalSdp = true }
            self.signalClient.send(sdp: localSdp)
        }
    }

    func toggleSpeaker() {
        if speakerOn {
            webRTCClient.speakerOff()
        } else {
            webRTCClient.speakerOn()
        }
        speakerOn.toggle()
    }

    func toggleMute() {
        mute.toggle()
        if mute {
            webRTCClient.muteAudio()
        } else {
            webRTCClient.unmuteAudio()
        }
    }
}

extension MediaViewModel: SignalClientDelegate {

    func signalClientDidConnect(_ signalClient: SignalingClient) {
        debugPrint("signal connect")
        self.signalingConnected = true
    }

    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        debugPrint("signal disconnect")
        self.signalingConnected = false
    }

    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
//        print("sdp.sdp : \(sdp.sdp)")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            withAnimation(.easeInOut(duration: 0.25)) {
                self.hasRemoteSdp = true
            }
        }
    }

    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        self.webRTCClient.set(remoteCandidate: candidate) { error in
//            print("candidate.sdp : \(candidate.sdp)")
            self.remoteCandidateCount += 1
        }
    }

    func signalClient(_ signalClient: SignalingClient, didReceiveStringMessage: SignalingMessage) {

        switch didReceiveStringMessage.signalingMessageType {

        case.enterMember:
            joinedMembers.append(didReceiveStringMessage.targets.first!)

        case.exitMember:
            debugPrint("exit를 받음")
            if let idx = joinedMembers.firstIndex(where: { $0 == didReceiveStringMessage.targets.first! }) {
                joinedMembers.remove(at: idx)
            } else {
                debugPrint("idx를 찾을수 없음")
            }

        case.initVoiceroom:
            didReceiveStringMessage.targets.forEach { joinedMembers.append($0) }
            debugPrint(didReceiveStringMessage)

        case.undefined:
            debugPrint("레전드 버그 발생")
        }
    }
}

extension MediaViewModel: WebRTCClientDelegate {

    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        self.localCandidateCount += 1
        self.signalClient.send(candidate: candidate)
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        self.webRTCStatus = state.description
    }

    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) { /* p2p로 메시지 보낼때 쓰던거 */ }
}


//enum RecordingState {
//    case recording
//    case stopped
//}

//    @Published var engine: AVAudioEngine!
//    @Published var mixerNode: AVAudioMixerNode!
//    @Published var state: RecordingState = .stopped

//    private func setupSession() {
//        let session = AVAudioSession()
//
//        do {
//            try session.setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker, .overrideMutedMicrophoneInterruption])
//            try session.setActive(true)
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//
//    private func setupEngine() {
//        engine = AVAudioEngine()
//        mixerNode = AVAudioMixerNode()
//
//        mixerNode.volume = .zero
//
//        engine.attach(mixerNode)
//
//        let inputNode = engine.inputNode
//        let inputFormat = inputNode.outputFormat(forBus: 0)
//
//        engine.connect(inputNode, to: mixerNode, format: inputFormat)
//        engine.connect(mixerNode, to: engine.mainMixerNode, format: inputFormat)
//        engine.prepare()
//    }
//
//    public func startRecord() {
//
//        let format = mixerNode.outputFormat(forBus: 0)
//
//        var isDirectory = ObjCBool(true)
//        let voiceRecordsDirectory = URL.documentsDirectory.appending(path: "VoiceRecords")
//
//        do {
//            let exists = FileManager.default.fileExists(atPath: voiceRecordsDirectory.path(), isDirectory: &isDirectory)
//            if !(exists && isDirectory.boolValue) {
//                print("create chatvideos directory")
//                try FileManager.default.createDirectory(at: voiceRecordsDirectory, withIntermediateDirectories: false)
//            } else {
//                print("chatvideos directory exist already")
//            }
//
//            let des = URL.documentsDirectory.appending(path: "VoiceRecords/voice-record\(Date().timeIntervalSince1970).m4a")
//            let file = try AVAudioFile(forWriting: des, settings: format.settings)
//
//            mixerNode.installTap(onBus: 0, bufferSize: 2048, format: format, block: { (buffer, time) in
//                try? file.write(from: buffer)
//            })
//
//            try engine.start()
//            state = .recording
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//
//    public func stopRecord() {
//        mixerNode.removeTap(onBus: 0)
//        engine.stop()
//        state = .stopped
//    }
