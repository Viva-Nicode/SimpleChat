import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct UserChatLog: Logable, Hashable {

    var id: String
    var logType: LogType
    var timestamp: Date
    var writer: String
    var detail: String
    var isSetReadNotification: Bool
    var readusers: Set<String>

    var mediaState: MediaChatLoadState = .end

    init(id: String, logType: String, writer: String, timestamp: String, detail: String, isSetReadNotification: Bool, readusers: String) {
        self.id = id
        self.logType = LogType(rawValue: logType) ?? LogType.undefined
        self.writer = writer
        self.timestamp = timestamp.stringToDate()!
        self.detail = detail
        self.isSetReadNotification = isSetReadNotification
        self.readusers = Set(readusers.components(separatedBy: " "))
    }

    init(id: String, logType: String, writer: String, timestamp: String, detail: String,
        isSetReadNotification: Bool, readusers: String, mediaState: MediaChatLoadState) {
        self.id = id
        self.logType = LogType(rawValue: logType) ?? LogType.undefined
        self.writer = writer
        self.timestamp = timestamp.stringToDate()!
        self.detail = detail
        self.isSetReadNotification = isSetReadNotification
        self.readusers = Set(readusers.components(separatedBy: " "))
        self.mediaState = mediaState
    }

    init(_ responseModel: UserChatroomResponseModel.UserMessageLogResponseModel) {
        self.id = responseModel.chatid
        self.logType = LogType(rawValue: responseModel.messageType) ?? LogType.undefined
        self.writer = responseModel.writer
        self.timestamp = responseModel.timestamp.stringToDate() ?? Date()
        self.detail = responseModel.detail
        self.readusers = Set(responseModel.readusers.components(separatedBy: " "))
        self.isSetReadNotification = responseModel.isReadNotification
    }

    mutating func addReadusers(user: String) { self.readusers.insert(user) }

    mutating func changeMediaStateAsComplete(_ state: MediaChatLoadState) { self.mediaState = state }

    func logDetailForDisplay() -> String {
        switch logType {
        case .text, .whisper:
            return detail
        case .video:
            return detail == "No Title Video" ? LocalizationString.noTitleVideo : detail
        case .photo:
            return LocalizationString.photoMessage
        case .blocked:
            return LocalizationString.blockedMessage
        default:
            return ""
        }
    }
}
