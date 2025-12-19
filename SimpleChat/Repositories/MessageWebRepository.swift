//
//  MessageWebRepository.swift
//  SimpleChat
//
//  Created by Nicode . on 5/5/24.
//

import Foundation
import Alamofire
import Combine
import _PhotosUI_SwiftUI

typealias MsgRes = UserChatroomResponseModel.UserMessageLogResponseModel

protocol MessageWebRepository: WebRepository {
    func sendMessage(email: String, chatroomid: String, detail: String) -> AnyPublisher<UserChatLog, AFError>
    func sendPhotoMessage(email: String, photoId: String, chatroomid: String, photoData: Data) -> AnyPublisher<UserChatLog, AFError>
    func sendVideoMessage(email: String, chatroomid: String, videoid: String,
        title: String, videoData: Data, thumbnail: Data) -> AnyPublisher<UserChatLog, Error>
    func sendWhisperMessage(email: String, audience: String, chatroomid: String, detail: String) -> AnyPublisher<UserChatLog, AFError>
    func reportMessage(email: String, roomid: String, chatid: String) -> AnyPublisher<APIResponse, AFError>
    func aiChatMessage(email: String, text: String) -> AnyPublisher<AIChatResponse, AFError>
    func setReadNotification(email: String, roomid: String, chatid: String, audiences: String) -> AnyPublisher<APIResponse, AFError>
    func loadVideo(videoid: String) -> AnyPublisher<URL, Error>
    func getReadNotificationSetableMemeberList(email: String, roomid: String, chatid: String) -> AnyPublisher<[UserFriend], AFError>
    func getReactions(roomid: String) -> AnyPublisher<MessageReactions, AFError>
    func setReaction(email: String, roomid: String, chatid: String, reaction: Reaction) -> AnyPublisher<ReactionSettingResponseModel, AFError>
}

struct RealMessageWebRepository: MessageWebRepository {

    let session: Session

    init(session: Session) {
        self.session = session
    }

    func sendMessage(email: String, chatroomid: String, detail: String) -> AnyPublisher<UserChatLog, AFError> {
        let reqeustBody = UserSendMessageRequestBody(email: email, chatroomid: chatroomid, detail: detail)
        return call(.sendMessage(reqeustBody), MsgRes.self)
            .map { UserChatLog($0) }
            .eraseToAnyPublisher()
    }

    func sendPhotoMessage(email: String, photoId: String, chatroomid: String, photoData: Data) -> AnyPublisher<UserChatLog, AFError> {
        let emailData = email.stringToData()!
        let photoIdData = photoId.stringToData()!
        let chatroomidData = chatroomid.stringToData()!
        let requestBody = UserSendPhotoMessageRequestBody(email: emailData, photoid: photoIdData, chatroomid: chatroomidData, photoData: photoData)
        return call(.sendPhotoMessage(requestBody), MsgRes.self)
            .map { UserChatLog($0) }
            .eraseToAnyPublisher()
    }

    func sendVideoMessage(email: String, chatroomid: String, videoid: String, title: String, videoData: Data, thumbnail: Data) -> AnyPublisher<UserChatLog, Error> {
        let emailData = email.stringToData()!
        let chatroomidData = chatroomid.stringToData()!
        let titleData = title.stringToData()!
        let videoidData = videoid.stringToData()!

        let requestBody = UserSendVideoMessageRequestBody(email: emailData, videoid: videoidData,
            chatroomid: chatroomidData, title: titleData, videoData: videoData, thumbnail: thumbnail)

        return call(.sendVideoMessage(requestBody), MsgRes.self)
            .receive(on: DispatchQueue.main)
            .map { UserChatLog($0) }
            .tryMap { videoChat in

            let sendedVideoURL = URL.documentsDirectory.appending(path: "convertedVideo.mp4")

            var isDirectory = ObjCBool(true)
            let chatVideoDirectory = URL.documentsDirectory.appending(path: "chatvideos")
            let exists = FileManager.default.fileExists(atPath: chatVideoDirectory.path(), isDirectory: &isDirectory)
            if !(exists && isDirectory.boolValue) {
                print("create chatvideos directory")
                try FileManager.default.createDirectory(at: chatVideoDirectory, withIntermediateDirectories: false)
            } else {
                print("chatvideos directory exist already")
            }

            let des = URL.documentsDirectory.appending(path: "chatvideos/\(videoChat.id).mp4")

            let sendedVideoData = try Data(contentsOf: sendedVideoURL)
            try sendedVideoData.write(to: des)

            return videoChat
        }.eraseToAnyPublisher()
    }

    func sendWhisperMessage(email: String, audience: String, chatroomid: String, detail: String) -> AnyPublisher<UserChatLog, Alamofire.AFError> {
        let requestBody = UserSendWhisperMessageRequestBody(email: email, audience: audience, chatroomid: chatroomid, detail: detail)
        return call(.sendWhisperMessage(requestBody), MsgRes.self)
            .map { UserChatLog($0) }
            .eraseToAnyPublisher()
    }

    func getReadNotificationSetableMemeberList(email: String, roomid: String, chatid: String) -> AnyPublisher<[UserFriend], AFError> {
        call(.getReadNotificationMemberList(email, roomid, chatid), [UserDataFetchResponseModel.UserFriendResponseModel].self)
            .realFlattenMap { idx, value in
            UserFriend(value)
        }.eraseToAnyPublisher()
    }

    func loadVideo(videoid: String) -> AnyPublisher<URL, Error> {
        call(.loadVideo(videoid), VideoDataResponseModel.self)
            .tryMap {
            var isDirectory = ObjCBool(true)
            let chatVideoDirectory = URL.documentsDirectory.appending(path: "chatvideos")
            let exists = FileManager.default.fileExists(atPath: chatVideoDirectory.path(), isDirectory: &isDirectory)
            if !(exists && isDirectory.boolValue) {
                print("create chatvideos directory")
                try FileManager.default.createDirectory(at: chatVideoDirectory, withIntermediateDirectories: false)
            } else {
                print("chatvideos directory exist already")
            }
            let videoPath: URL = chatVideoDirectory.appendingPathComponent($0.videoName)
            try $0.data.write(to: videoPath)
            return videoPath
        }.eraseToAnyPublisher()
    }

    func getReactions(roomid: String) -> AnyPublisher<MessageReactions, AFError> {
        call(.getReactions(roomid), [ReactionResponseModel].self)
            .map { MessageReactions(responseModel: $0) }.eraseToAnyPublisher()
    }

    func setReaction(email: String, roomid: String, chatid: String, reaction: Reaction) -> AnyPublisher<ReactionSettingResponseModel, AFError> {
        let requestBody = UserReactionRequestBody(email: email, roomid: roomid, chatid: chatid, reaction: reaction.reaction.rawValue)
        return call(.setReaction(requestBody), ReactionSettingResponseModel.self)
    }

    func reportMessage(email: String, roomid: String, chatid: String) -> AnyPublisher<APIResponse, AFError> {
        call(.reportChat(email, roomid, chatid), APIResponse.self)
    }

    func setReadNotification(email: String, roomid: String, chatid: String, audiences: String) -> AnyPublisher<APIResponse, AFError> {
        call(.setReadNotification(email, roomid, chatid, audiences), APIResponse.self)
    }

    func aiChatMessage(email: String, text: String) -> AnyPublisher<AIChatResponse, AFError> {
        call(.chattingToAi(email, text), AIChatResponse.self)
    }
}
