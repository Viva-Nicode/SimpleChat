import Foundation

enum SignalingMessageType: String, Decodable {
    case enterMember = "entermember"
    case exitMember = "exitmember"
    case initVoiceroom = "initvoiceroom"
    case undefined = "undefined"
}

struct SignalingMessage: Decodable {
    var voiceChatroomIdentifier: String
    var signalingMessageType: SignalingMessageType
    var targets: [String]

    enum CodingKeys: CodingKey {
        case roomid
        case MessageType
        case targets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.voiceChatroomIdentifier = try (container.decodeIfPresent(String?.self, forKey: .roomid) ?? "notFound") ?? "notFound"
        self.signalingMessageType = try .init(rawValue: container.decode(String?.self, forKey: .MessageType) ?? "undefined") ?? .undefined
        self.targets = try (container.decodeIfPresent([String]?.self, forKey: .targets) ?? []) ?? []
    }

    init(voiceChatroomIdentifier: String, signalingMessageType: SignalingMessageType, targets: [String]) {
        self.voiceChatroomIdentifier = voiceChatroomIdentifier
        self.signalingMessageType = signalingMessageType
        self.targets = targets
    }

    var buildJsonString: String? {
        let dict: [String: Any] = [
            "MessageType": self.signalingMessageType.rawValue,
            "roomid": self.voiceChatroomIdentifier,
            "targets": self.targets
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

extension String {
    func DecodeToSignalingMessage() throws -> SignalingMessage {
        let decoder = JSONDecoder()
        let jsonData = Data(self.utf8)
        return try decoder.decode(SignalingMessage.self, from: jsonData)
    }
}
