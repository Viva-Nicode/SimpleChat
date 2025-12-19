import Foundation
import CoreData
import Combine
import SwiftUI

class ApplicationViewModel: ObservableObject {

    @Published var cancellableSet: Set<AnyCancellable> = []
    @Published var userChatrooms: [UserChatroom] = [UserChatroom]()
    @Published var userfriends: [UserFriend] = [UserFriend]()
    @Published var userNotifications: [UserNotification] = [UserNotification]()
    @Published var userChatroomBundles: [ChatroomBundle] = [ChatroomBundle]()
    @Published var userChatroomTitles: [String: String] = [:]
    @Published var whisperMessageSender: [String: String] = [:]
    @Published var isSuspended = false

    init() { }

    init(_ data: UserDataFetchResponseModel, co: (UserDataFetchResponseModel.UserAppSettings) -> ()) {
        self.userfriends = data.friendlist.map { UserFriend($0) }
        self.userChatrooms = data.messagelist.map { UserChatroom($0) }
        self.userNotifications = data.notificationlist.map { UserNotification($0) }
        self.whisperMessageSender = Dictionary(uniqueKeysWithValues: data.whisperlist.map { ($0.chatid, $0.receiver) })
        self.isSuspended = data.isSyspended
        co(data.settings)
    }

    public func whisperTarget(_ chatid: String) -> String {
        getNickname(whisperMessageSender[chatid] ?? "")
    }

    public var invitableFriendlist: (String) -> [UserFriend] {
        { [userChatrooms, userfriends] chatroomid in
            if let idx = userChatrooms.firstIndex(where: { $0.chatroomid == chatroomid }) {
                let list: [String] = Set(userfriends.map { $0.email }).subtracting(userChatrooms[idx].audiencelist).sorted()
                return userfriends.filter { list.contains($0.email) }
            } else { return [] }
        }
    }

    public var bundleableChatrooms: [UserChatroom] {
        var ids: [String] = []
        userChatroomBundles.forEach { ids.append(contentsOf: $0.bundleChatroomList) }
        return userChatrooms.filter { !ids.contains($0.chatroomid) }
    }

    public func getNickname(_ email: String) -> String {
        if let me: String = UserDefaultsKeys.userEmail.value() {
            if me == email {
                return UserDefaultsKeys.userNickname.value() ?? email
            } else {
                return userfriends.first { $0.email == email }?.nickname ?? email
            }
        } else {
            return userfriends.first { $0.email == email }?.nickname ?? email
        }
    }

    public var unreadCount: Int {
        if let me: String = UserDefaultsKeys.userEmail.value() {
            let count = self.userChatrooms.map { $0.unreadCount(me) }.reduce(0, +)
            return count > 999 ? 999 : count
        } else { return 0 }
    }

    public func getMainMessageCards() -> [Cardable] {
        var result: [Cardable] = []

        self.userChatrooms.forEach {
            if isContainChatroomInBundles($0) { result.append($0) }
        }

        self.userChatroomBundles.forEach {
            if $0.bundlePosition == .none { result.append($0) }
        }

        result.sort(by: { lhs, rhs in
            var lhsDate = Date()
            var rhsDate = Date()

            if lhs.cardType == .bundle {
                let bundle = lhs as! ChatroomBundle
                lhsDate = bundleRecentDate(bundle.bundleID)
            } else {
                let chatroom = lhs as! UserChatroom
                lhsDate = chatroom.log.last?.timestamp ?? Date()
            }

            if rhs.cardType == .bundle {
                let bundle = rhs as! ChatroomBundle
                rhsDate = bundleRecentDate(bundle.bundleID)
            } else {
                let chatroom = rhs as! UserChatroom
                rhsDate = chatroom.log.last?.timestamp ?? Date()
            }

            return lhsDate > rhsDate
        })

        result.insert(contentsOf: self.userChatroomBundles
                .filter { $0.bundlePosition == .mostTop }
                .sorted(by: { bundleRecentDate($0.bundleID) > bundleRecentDate($1.bundleID) }), at: 0)

        result.append(contentsOf: self.userChatroomBundles
                .filter { $0.bundlePosition == .mostBottom }
                .sorted(by: { bundleRecentDate($0.bundleID) > bundleRecentDate($1.bundleID) }))

        return result

        func isContainChatroomInBundles(_ chatroom: UserChatroom) -> Bool {
            for bundle in self.userChatroomBundles {
                if bundle.bundleChatroomList.contains(chatroom.chatroomid) {
                    return false
                }
            }
            return true
        }
    }
}

extension ApplicationViewModel {

    public func getBundleById(_ bundleId: String) -> ChatroomBundle? {
        self.userChatroomBundles.first(where: { $0.bundleID == bundleId })
    }

    public func getChatroomsInBundleById(_ bundleId: String) -> [UserChatroom] {
        if let bundle = self.userChatroomBundles.first(where: { $0.bundleID == bundleId }) {
            var result: [UserChatroom] = []
            bundle.bundleChatroomList.forEach { chatroomid in
                if let chatroom = self.userChatrooms.first(where: { $0.chatroomid == chatroomid }) {
                    result.append(chatroom)
                }
            }
            return result.sorted(by: { $0.log.last?.timestamp ?? Date() > $1.log.last?.timestamp ?? Date() })
        } else {
            return []
        }
    }

    public func bundleUnreadCount(_ bundleId: String) -> Int? {
        if let bundle = self.userChatroomBundles.first(where: { $0.bundleID == bundleId }) {
            var unreadCount: Int = .zero

            bundle.bundleChatroomList.forEach { roomid in
                if let room = self.userChatrooms.first(where: { $0.chatroomid == roomid }) {
                    if let me: String = UserDefaultsKeys.userEmail.value() {
                        unreadCount += room.unreadCount(me)
                    }
                }
            }
            return min(999, unreadCount)
        } else {
            return nil
        }
    }

    public func bundleRecentMessage(_ bundleId: String) -> String {
        if let bundle = self.userChatroomBundles.first(where: { $0.bundleID == bundleId }) {
            var mostDate = Date(timeIntervalSince1970: 0)
            var recentLogDetail = ""
            bundle.bundleChatroomList.forEach { roomid in
                if let room = self.userChatrooms.first(where: { $0.chatroomid == roomid }) {
                    if let mostLastLog = room.log.last {
                        if mostLastLog.timestamp > mostDate {
                            mostDate = mostLastLog.timestamp
                            recentLogDetail = room.recentLogDetail { self.getNickname($0) }
                        }
                    }
                }
            }
            return recentLogDetail
        } else {
            return ""
        }
    }

    public func bundleRecentShowableDate(_ bundleId: String) -> String? {
        if let bundle = self.userChatroomBundles.first(where: { $0.bundleID == bundleId }) {
            var mostDate = Date(timeIntervalSince1970: 0)
            var showableMostDate:String?
            
            bundle.bundleChatroomList.forEach { roomid in
                if let room = self.userChatrooms.first(where: { $0.chatroomid == roomid }) {
                    if let mostLastLog = room.log.last {
                        if mostLastLog.timestamp > mostDate {
                            mostDate = mostLastLog.timestamp
                            showableMostDate = mostLastLog.showableTimestamp
                        }
                    }
                }
            }
            return showableMostDate
        } else {
            return ""
        }
    }

    public func bundleRecentDate(_ bundleId: String) -> Date {

        if let bundle = self.userChatroomBundles.first(where: { $0.bundleID == bundleId }) {

            var dates: [Date] = []

            bundle.bundleChatroomList.forEach { roomid in
                if let room = self.userChatrooms.first(where: { $0.chatroomid == roomid }) {
                    if let mostLastLog = room.log.last {
                        dates.append(mostLastLog.timestamp)
                    }
                }
            }

            return dates.sorted().last ?? Date()
        } else {
            return Date()
        }
    }
}

protocol TimeStampable { var timestamp: Date { get } }

extension TimeStampable {

    private var secondsElaped: Int? { return Int(Date().timeIntervalSince(self.timestamp)) }

    public var showableTimestamp: String {
        get {
            let timeConvertConsts: [Int] = [31536000, 2592000, 86400, 3600, 60, 1]
            let timeConvertUnits: [String] = [
                LocalizationString.year,
                LocalizationString.month,
                LocalizationString.day,
                LocalizationString.hour,
                LocalizationString.minutes,
                LocalizationString.seconds
            ]

            if let sec = self.secondsElaped {
                for idx in 0..<timeConvertConsts.count {
                    if sec / timeConvertConsts[idx] > 0 {
                        return String(sec / timeConvertConsts[idx]) + timeConvertUnits[idx]
                    }
                }
            }
            return LocalizationString.now
        }
    }
}

protocol Logable: TimeStampable, Equatable, Hashable {
    var id: String { get set }
    var logType: LogType { get set }
    var detail: String { get set }

    func store(in context: NSManagedObjectContext, chatroomEntity: UserChatroomEntity)

    mutating func addReadusers(user: String)

    mutating func changeMediaStateAsComplete(_ state: MediaChatLoadState)

    static func == (lhs: any Logable, rhs: any Logable) -> Bool
}

enum MediaChatLoadState {
    case loading
    case complete
    case end
}

extension Logable {
    static func == (lhs: any Logable, rhs: any Logable) -> Bool {
        print("called == Logable")
        return lhs.id == rhs.id && lhs.logType == rhs.logType && lhs.detail == rhs.detail
    }
}

public enum LogType: String {

    case text = "TEXT"
    case photo = "PHOTO"
    case video = "VIDEO"
    case whisper = "WHISPER"
    case blocked = "BLOCKED"
    case startchat = "STARTCHAT"
    case exit = "EXIT"
    case enter = "ENTER"
    case undefined = "UNDEFINED"
}


