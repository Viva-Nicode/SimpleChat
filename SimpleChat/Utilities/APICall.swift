import Alamofire
import Foundation
import PhotosUI
import SwiftUI

protocol HTTPRequest {
    var path: String { get }
    var method: HTTPMethod { get }
}

enum APIs {
    case signup(UserAuthenticationReqeustBody)
    case storeProfile(UserProfileStoreRequestBody)
    case storeBackgroundProfile(UserProfileStoreRequestBody)
    case signin(UserAuthenticationReqeustBody)
    case changeAppState(String, String)
    case loadUserData(String)
    case sendMessage(UserSendMessageRequestBody)
    case sendWhisperMessage(UserSendWhisperMessageRequestBody)
    case sendPhotoMessage(UserSendPhotoMessageRequestBody)
    case searchOtherUser(String, String)

    case getBlackList(String)
    case getProfilesList(String)
    case unblockFriend(String, String)
    case sendFriendRequest(String, String)
    case refuseFriendRequest(String, String)
    case acceptFriendRequest(String, String)
    case removeFriend(String, String)
    case createChatroom(String, [String], String)
    case createPairChatroom(String, String)
    case readMessage(UserMessageReadRequestBody)

    case inviteUser(String, String, String)
    case exitChatroom(String, String)
    case chattingToAi(String, String)
    case exitPairChatroom(String, String)
    case changeNickname(String, String)
    case removeProfile(String, String)
    case setReadNotification(String, String, String, String)
    case reportChat(String, String, String)
    case reportUser(String, String, Int, String)
    case signout(String)

    case checkExistUser(String)
    case getReadNotificationMemberList(String, String, String)
    case deleteAccount(String, String)
    case secretAuth(String)
    case setChatroomNotification(String, String)
    case sendVideoMessage(UserSendVideoMessageRequestBody)
    case loadVideo(String)
    case getReactions(String)
    case setReaction(UserReactionRequestBody)
    case knellVoicechat(String, String)
}

extension APIs: HTTPRequest {

    var path: String {
        switch self {
        case .signin:
            return "/rest/signin"
        case .signup:
            return "/rest/signup"
        case .storeProfile:
            return "/rest/store-profile"
        case .storeBackgroundProfile:
            return "/rest/store-background"
        case .loadUserData:
            return "/rest/fetch-userdata"
        case .changeAppState:
            return "/rest/changeAppState"
        case .changeNickname:
            return "/rest/changeNickname"
        case .sendMessage:
            return "/chat/send-msg"
        case .sendWhisperMessage:
            return "/chat/send-whisper"
        case let .loadVideo(videoid):
            return "/chat/get-chatvideo/\(videoid)"
        case .sendPhotoMessage:
            return "/chat/send-photo"
        case .sendVideoMessage:
            return "/chat/send-video"
        case .getBlackList:
            return "/rest/get-blacklist"
        case .getProfilesList:
            return "/rest/get-profilelist"
        case .unblockFriend:
            return "/rest/unblock"
        case .searchOtherUser:
            return "/rest/get-newuser"
        case .sendFriendRequest:
            return "/rest/add-friend-req"
        case .refuseFriendRequest:
            return "/rest/add-friend-refuse"
        case .acceptFriendRequest:
            return "/rest/add-friend-acc"
        case .setReaction:
            return "/chat/set-react"
        case .removeFriend:
            return "/rest/remove-friend"
        case .getReactions:
            return "/chat/get-react"
        case .createChatroom:
            return "/chat/newchat"
        case .createPairChatroom:
            return "/chat/newPairchat"
        case .inviteUser:
            return "/chat/enter-chat"
        case .checkExistUser:
            return "/rest/isexist-user"
        case .exitChatroom:
            return "/chat/exit-chat"
        case .exitPairChatroom:
            return "/chat/exit-pairchat"
        case .chattingToAi:
            return "/rest/ai"
        case .readMessage:
            return "/chat/readmsg"
        case .removeProfile:
            return "/rest/remove-profile"
        case .reportChat:
            return "/rest/report-chat"
        case .reportUser:
            return "/rest/report-user"
        case .signout:
            return "/rest/sign-out"
        case .getReadNotificationMemberList:
            return "/chat/get-readnotilist"
        case .setReadNotification:
            return "/chat/set-readnoti"
        case .deleteAccount:
            return "/rest/Account-cancellation"
        case .secretAuth:
            return "/sec/auth"
        case .setChatroomNotification:
            return "/chat/set-noti"
        case .knellVoicechat:
            return "/chat/knell-voiceChat"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .loadUserData,
             .getBlackList,
             .getProfilesList,
             .loadVideo,
             .checkExistUser,
             .getReadNotificationMemberList,
             .chattingToAi,
             .getReactions,
             .searchOtherUser:
            return .get

        case .sendMessage,
             .sendWhisperMessage,
             .sendPhotoMessage,
             .sendVideoMessage,
             .signin,
             .setReadNotification,
             .changeAppState,
             .sendFriendRequest,
             .refuseFriendRequest,
             .removeFriend,
             .exitChatroom,
             .exitPairChatroom,
             .createChatroom,
             .createPairChatroom,
             .inviteUser,
             .setChatroomNotification,
             .signup,
             .setReaction,
             .storeProfile,
             .storeBackgroundProfile,
             .readMessage,
             .acceptFriendRequest,
             .unblockFriend,
             .removeProfile,
             .reportChat,
             .reportUser,
             .knellVoicechat,
             .deleteAccount,
             .signout,
             .secretAuth,
             .changeNickname:
            return .post
        }
    }
}

extension APIs: URLRequestConvertible {
    static var baseURL: String = Bundle.main.object(forInfoDictionaryKey: "ServerUrl") as! String

    func asURLRequest() throws -> URLRequest {

        var request = URLRequest(url: URL(string: Self.baseURL + path)!)
        request.method = method

        switch self {
        case let .signup(userInfo):
            return try URLEncoding.default.encode(request, with: [
                "email": userInfo.email,
                "password": userInfo.password,
                "fcmtoken": userInfo.fcmtoken])

        case .storeProfile:
            request.headers = ["Content-Type": "multipart/form-data"]
            return try URLEncoding.default.encode(request, with: nil)

        case .storeBackgroundProfile:
            request.headers = ["Content-Type": "multipart/form-data"]
            return try URLEncoding.default.encode(request, with: nil)

        case let .signin(userInfo):
            return try URLEncoding.default.encode(request, with: [
                "email": userInfo.email,
                "password": userInfo.password,
                "fcmtoken": userInfo.fcmtoken])

        case let .changeAppState(me, state):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "state": state])

        case let .knellVoicechat(me, target):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "target": target])

        case let .changeNickname(email, nickname):
            return try URLEncoding.default.encode(request, with: [
                "email": email,
                "nickname": nickname])

        case let .loadUserData(email):
            return try URLEncoding.default.encode(request, with: ["email": email])

        case let .sendMessage(msgInfo):
            return try URLEncoding.default.encode(request, with: [
                "me": msgInfo.email,
                "chatroomid": msgInfo.chatroomid,
                "detail": msgInfo.detail])

        case let .sendWhisperMessage(msgInfo):
            return try URLEncoding.default.encode(request, with: [
                "me": msgInfo.email,
                "chatroomid": msgInfo.chatroomid,
                "detail": msgInfo.detail,
                "audience": msgInfo.audience])

        case .sendPhotoMessage:
            request.headers = ["Content-Type": "multipart/form-data"]
            return try URLEncoding.default.encode(request, with: nil)

        case .sendVideoMessage:
            request.headers = ["Content-Type": "multipart/form-data"]
            return try URLEncoding.default.encode(request, with: nil)

        case let .readMessage(msgs):
            return try URLEncoding.default.encode(request, with: [
                "me": msgs.email,
                "chatroomid": msgs.chatroomid,
                "chatidlist": msgs.chatidlist,
                "typelist": msgs.typelist])

        case let .getReactions(roomid):
            return try URLEncoding.default.encode(request, with: [
                "chatroomid": roomid])

        case let .searchOtherUser(email, keyword):
            return try URLEncoding.default.encode(request, with: [
                "me": email,
                "keyword": keyword])

        case let .createChatroom(email, members, roomtype):
            return try URLEncoding.default.encode(request, with: [
                "me": email,
                "audiences": members.joined(separator: " "),
                "roomtype": roomtype])

        case let .getBlackList(email):
            return try URLEncoding.default.encode(request, with: [
                "me": email])

        case .loadVideo:
            return try URLEncoding.default.encode(request, with: nil)

        case let .unblockFriend(me, audience):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience])

        case let .getReadNotificationMemberList(me, roomid, chatid):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "chatroomid": roomid,
                "chatid": chatid])

        case let .setChatroomNotification(me, roomid):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "chatroomid": roomid])

        case let .createPairChatroom(me, audience):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience])

        case let .chattingToAi(me, text):
            return try URLEncoding.default.encode(request, with: [
                "email": me,
                "text": text])

        case let .checkExistUser(email):
            return try URLEncoding.default.encode(request, with: [
                "email": email])

        case let .exitChatroom(email, chatroomid):
            return try URLEncoding.default.encode(request, with: [
                "me": email,
                "chatroomid": chatroomid])

        case let .exitPairChatroom(email, chatroomid):
            return try URLEncoding.default.encode(request, with: [
                "me": email,
                "chatroomid": chatroomid])

        case let .inviteUser(email, audience, chatroomid):
            return try URLEncoding.default.encode(request, with: [
                "me": email,
                "target": audience,
                "chatroomid": chatroomid])

        case let .sendFriendRequest(me, audience):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience])

        case let .refuseFriendRequest(me, audience):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience])

        case let .acceptFriendRequest(me, audience):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience])

        case let .removeFriend(me, audience):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience])

        case let .getProfilesList(target):
            return try URLEncoding.default.encode(request, with: [
                "target": target])

        case let .removeProfile(me, targetImage):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "targetImage": targetImage])

        case let .reportChat(me, roomid, chatid):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "roomid": roomid,
                "chatid": chatid])

        case let .setReadNotification(me, roomid, chatid, audiences):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "roomid": roomid,
                "chatid": chatid,
                "audiences": audiences])

        case let .reportUser(me, audience, reason, detail):
            return try URLEncoding.default.encode(request, with: [
                "me": me,
                "audience": audience,
                "reason": reason,
                "detail": detail])

        case let .setReaction(requestBody):
            return try URLEncoding.default.encode(request, with: [
                "me": requestBody.email,
                "chatroomid": requestBody.roomid,
                "chatid": requestBody.chatid,
                "reaction": requestBody.reaction])

        case let .signout(me):
            return try URLEncoding.default.encode(request, with: [
                "me": me])

        case let .deleteAccount(me, pw):
            return try URLEncoding.default.encode(request, with: [
                "email": me,
                "password": pw])

        case let .secretAuth(key):
            return try URLEncoding.default.encode(request, with: [
                "authKey": key])
        }
    }

    var multipartFormData: MultipartFormData {

        let multipartFormData = MultipartFormData()

        switch self {
        case let .sendPhotoMessage(msgInfo):
            multipartFormData.append(msgInfo.photoData,
                withName: "photo",
                fileName: "photoMessage.jpeg",
                mimeType: "image/jpeg")
            multipartFormData.append(msgInfo.email, withName: "me")
            multipartFormData.append(msgInfo.chatroomid, withName: "chatroomid")
            multipartFormData.append(msgInfo.photoid, withName: "photoid")
            return multipartFormData

        case let .sendVideoMessage(msgInfo):
            multipartFormData.append(msgInfo.videoData,
                withName: "video",
                fileName: "videoMessage.mp4",
                mimeType: "video/mp4")
            multipartFormData.append(msgInfo.thumbnail,
                withName: "thumbnail",
                fileName: "thumbnail.jpeg",
                mimeType: "image/jpeg")
            multipartFormData.append(msgInfo.email, withName: "me")
            multipartFormData.append(msgInfo.title, withName: "title")
            multipartFormData.append(msgInfo.videoid, withName: "videoid")
            multipartFormData.append(msgInfo.chatroomid, withName: "chatroomid")
            return multipartFormData

        case let .storeProfile(profile):
            multipartFormData.append(profile.profile!,
                withName: "image",
                fileName: "profile.jpeg",
                mimeType: "image/jpeg")
            multipartFormData.append(profile.email!, withName: "email")
            return multipartFormData

        case let .storeBackgroundProfile(profile):
            multipartFormData.append(profile.profile!,
                withName: "image",
                fileName: "profile.jpeg",
                mimeType: "image/jpeg")
            multipartFormData.append(profile.email!, withName: "email")
            return multipartFormData

        default:
            return MultipartFormData()
        }
    }
}

enum APIError: Swift.Error {
    case invalidURL
    case httpCode(HTTPCode)
    case unexpectedResponse
    case imageDeserialization
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case let .httpCode(code): return "Unexpected HTTP code: \(code)"
        case .unexpectedResponse: return "Unexpected response from the server"
        case .imageDeserialization: return "Cannot deserialize image from Data"
        }
    }
}

typealias HTTPCode = Int
typealias HTTPCodes = Range<HTTPCode>
extension HTTPCodes { static let success = 200 ..< 300 }
