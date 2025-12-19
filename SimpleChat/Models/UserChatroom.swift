import Foundation
import SwiftUI
import SDWebImageSwiftUI

enum ChatroomType: String {
    case group = "GROUP"
    case pair = "PAIR"
}

extension Array where Element == UserChatroom {
    subscript(_ id: String) -> Int? {
        get {
            return self.firstIndex(where: { $0.chatroomid == id })
        }
    }
}

struct UserChatroom: Hashable, Cardable {
    var cardType: CardType = .chatroom
    

    var chatroomid: String
    var audiencelist: Set<String>
    var roomtype: ChatroomType
    var notificationMuteState: Bool
    var log: [any Logable] = [any Logable]()

    init(chatroomid: String, audiencelist: String, roomtype: String, log: [any Logable]? = nil) {
        self.chatroomid = chatroomid
        self.audiencelist = Set(audiencelist.components(separatedBy: " "))
        self.notificationMuteState = false
        self.roomtype = ChatroomType(rawValue: roomtype)!
        if let l = log { self.log = l }
    }

    init(_ responseModel: UserChatroomResponseModel) {
        self.chatroomid = responseModel.chatroomid
        self.notificationMuteState = responseModel.notificationMuteState
        if self.notificationMuteState {
            UserDefaults.standard.set("true", forKey: "notiState-\(self.chatroomid)")
        }
        self.audiencelist = Set(responseModel.audiencelist.components(separatedBy: " "))
        self.roomtype = ChatroomType(rawValue: responseModel.roomtype)!

        responseModel.logs.forEach { self.log.append(UserChatLog($0)) }
        responseModel.syslogs.forEach { self.log.append(SystemLog($0)) }
        self.log.sort(by: { $0.timestamp < $1.timestamp })
    }


    static func == (lhs: UserChatroom, rhs: UserChatroom) -> Bool {
        guard lhs.chatroomid == rhs.chatroomid && lhs.audiencelist == rhs.audiencelist && lhs.log.count == rhs.log.count else {
            return false
        }

        return zip(lhs.log.sorted(by: { $0.timestamp < $1.timestamp }), rhs.log.sorted(by: { $0.timestamp < $1.timestamp }))
            .map { (ll, rl) in
            (ll is SystemLog && rl is SystemLog) ||
                (ll is UserChatLog && rl is UserChatLog && (ll as! UserChatLog).readusers == (rl as! UserChatLog).readusers)
        }.allSatisfy { $0 }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(chatroomid) }

    public func recentLogDetail(_ nicknameTransfer: @escaping (String) -> String) -> String {
        if let mostRecentLog = log.last {
            switch mostRecentLog {
            case let chatlog as UserChatLog:
                return chatlog.logDetailForDisplay()
            case let syslog as SystemLog:
                return syslog.getSystemMessage { nicknameTransfer($0) }
            default:
                return ""
            }
        } else {
            return ""
        }
    }

    public var unreadCount: (String) -> Int {
        { me in
            return self.log.filter { l in
                if let ucl = l as? UserChatLog {
                    return !ucl.readusers.contains(me)
                } else { return false }
            }.count
        }
    }
}
