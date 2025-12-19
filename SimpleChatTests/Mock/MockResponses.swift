import Foundation
@testable import SimpleChat

extension MockURLProtocol.MockDTOType {

    var responseData: Data? {
        switch self {
        case .createNewChatroom_1:
            let mockResponseDictionary: [String: Any] = [
                "chatroomid": "e6ca7596-e1bc-4107-9de2-f21d5ded5a11",
                "audiencelist": "dmswns0147@gmail.com nicode@gmail.com",
                "logs": [],
                "notificationMuteState": false,
                "roomtype": "GROUP",
                "syslogs": []
            ]
            return try? JSONSerialization.data(withJSONObject: mockResponseDictionary, options: .prettyPrinted)

        case .createNewChatroom_2:
            let mockResponseDictionary: [String: Any] = [
                "chatroomid": "25b255f0-cbe1-44ab-be65-f8fa5c4114b2",
                "audiencelist": "hongsg@naver.com dmswns0147@gmail.com vivani@gmail.com",
                "notificationMuteState": false,
                "logs": [],
                "roomtype": "GROUP",
                "syslogs": []
            ]
            return try? JSONSerialization.data(withJSONObject: mockResponseDictionary, options: .prettyPrinted)

        case .test_sendMessage_successful:
            let mockResponseDictionary: [String: Any] = [
                "messageType": "TEXT",
                "chatid": "b8d64812-09cd-4a03-8728-6065c2adf232",
                "writer": "nicode@gmail.com",
                "detail": "test message",
                "timestamp": Date().dateToString(),
                "isReadNotification": false,
                "readusers": "nicode@gmail.com"
            ]
            return try? JSONSerialization.data(withJSONObject: mockResponseDictionary, options: .prettyPrinted)
            
        case .test_sendMessage_failed_roomNotFound:
            let mockResponseDictionary: [String: Any] = [
                "messageType": "TEXT",
                "chatid": "",
                "writer": "nicode@gmail.com",
                "detail": "test message",
                "timestamp": Date().dateToString(),
                "isReadNotification": false,
                "readusers": "nicode@gmail.com"
            ]
            return try? JSONSerialization.data(withJSONObject: mockResponseDictionary, options: .prettyPrinted)
        }
    }
}

//var messageType: String
//var chatid: String
//var writer: String
//var detail: String
//var timestamp: String
//var isReadNotification: Bool
//var readusers: String
