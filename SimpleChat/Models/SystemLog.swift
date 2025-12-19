import Foundation
import SwiftUI

struct SystemLog: Logable, Hashable {

    var id: String
    var logType: LogType
    var detail: String
    var timestamp: Date

    init(id: String, logType: String, timestamp: String, detail: String) {
        self.id = id
        self.logType = LogType(rawValue: logType) ?? LogType.undefined
        self.detail = detail
        self.timestamp = timestamp.stringToDate()!
        self.detail = detail
    }

    init(_ responseModel: UserChatroomResponseModel.UserSystemLogResponseModel) {
        self.id = responseModel.sysid
        self.logType = LogType(rawValue: responseModel.type) ?? LogType.undefined
        self.detail = responseModel.detail
        self.timestamp = responseModel.timestamp.stringToDate()!
    }

    mutating func addReadusers(user: String) { }

    mutating func changeMediaStateAsComplete(_ state: MediaChatLoadState) { }

    func getSystemMessage(_ nicknameTransfer: @escaping (String) -> String) -> String {
        switch logType {
        case .startchat:
            return LocalizationString.startSystemMessage(detail.components(separatedBy: " ").map { nicknameTransfer($0) }.joined(separator: ", "))

        case .exit:
            return LocalizationString.exitSystemMessage(nicknameTransfer(detail))

        case .enter:
            let users: [String] = detail.components(separatedBy: " ")
            return LocalizationString
                .enterSystemMessage(nicknameTransfer(users.first!), users[1..<users.count].map { nicknameTransfer($0) }.joined(separator: ","))

        default:
            return "undefined case"
        }
    }
}
