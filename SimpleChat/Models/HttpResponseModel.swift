
import Foundation
import SwiftUI

protocol ResponseType: Decodable { }

enum ReactionResponseCode: Int, Decodable {
    case cancel = 1
    case success = 0
    case canceledAlready = -1
    case dup = -2
    case undefined = -3
}

struct ReactionSettingResponseModel: ResponseType {
    let code: ReactionResponseCode

    enum CodingKeys: CodingKey {
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try .init(rawValue: container.decode(Int.self, forKey: .code)) ?? .undefined
    }
}

enum APIResponseCode: Int, Decodable {
    case undefined = -1
    case success = 0
    case notExistEmail = 1
    case passwordMismatch = 2
    case duplicateEmail = 3
    case failToStoreProfile = 4
    case duplicateLogin = 5
    case suspendedAccount = 6

    var description: LocalizedStringKey {
        switch self {
        case .undefined:
            "undefined response code"
        case .success:
            "request success"
        case .notExistEmail:
            "Non-existent email"
        case .passwordMismatch:
            "Password mismatch"
        case .duplicateEmail:
            "duplicate email"
        case .failToStoreProfile:
            "fail to Store the profile"
        case .duplicateLogin:
            "You cannot log in because you are logged in on another device"
        case .suspendedAccount:
            "Service use will be restricted due to inappropriate activity identified in the account."
        }
    }
}

struct UserProfileResponseModel: ResponseType {
    var imageName: String
    var profileType: String
    var isCurrentUsing: Bool
    var timestamp: String
}

struct ReactionResponseModel: ResponseType {
    var chatid: String
    var email: String
    var reaction: String
    var timestamp: String
}

struct APIResponse: ResponseType {
    let code: APIResponseCode

    enum CodingKeys: CodingKey {
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try .init(rawValue: container.decode(Int.self, forKey: .code)) ?? .undefined
    }
}

struct AIChatResponse: ResponseType {
    var aiResponse: String
}

struct VideoDataResponseModel: ResponseType {
    var videoName: String
    var data: Data
}

extension [UserDataFetchResponseModel.UserFriendResponseModel]: ResponseType { }

struct UserDataFetchResponseModel: ResponseType {
    var friendlist: [UserFriendResponseModel]
    var messagelist: [UserChatroomResponseModel]
    var whisperlist: [UserWhisperMessageList]
    var notificationlist: [UserNotificationResponseModel]
    var settings: UserAppSettings
    var isSyspended: Bool

    struct UserFriendResponseModel: Decodable {
        var friendEmail: String
        var nickname: String?
    }

    struct UserNotificationResponseModel: Decodable {
        var timestamp: String
        var notitype: String
        var fromemail: String
    }

    struct UserAppSettings: Decodable {
        var nickname: String?
    }

    struct UserWhisperMessageList: Decodable {
        var chatid: String
        var receiver: String
    }
}

struct UserChatroomResponseModel: ResponseType {
    var chatroomid: String
    var audiencelist: String
    var roomtype: String
    var notificationMuteState: Bool
    var logs: [UserMessageLogResponseModel]
    var syslogs: [UserSystemLogResponseModel]

    struct UserMessageLogResponseModel: ResponseType {
        var messageType: String
        var chatid: String
        var writer: String
        var detail: String
        var timestamp: String
        var isReadNotification: Bool
        var readusers: String
    }

    struct UserSystemLogResponseModel: ResponseType {
        var sysid: String
        var type: String
        var timestamp: String
        var detail: String
    }
}

struct OtherUserSearchResponseModel: ResponseType {
    var result: String
    var requestState: OtherUserSearchResponseState

    enum OtherUserSearchResponseState: String, Decodable {
        case `init` = "init"
        case wait = "wait"
        case accept = "accept"
        case notFound = "notfound"
    }

    enum CodingKeys: CodingKey {
        case result
        case requestState
    }

    init(result: String, requestState: OtherUserSearchResponseState) {
        self.result = result
        self.requestState = requestState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.result = try (container.decodeIfPresent(String?.self, forKey: .result) ?? "notfound") ?? "notfound"
        self.requestState = try .init(rawValue: container.decode(String?.self, forKey: .requestState) ?? "notfound")!
    }
}
