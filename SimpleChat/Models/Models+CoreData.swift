import Foundation
import CoreData

extension UserChatroom {

    init (_ entity: UserChatroomEntity) {
        self.chatroomid = entity.chatroomid
        self.audiencelist = Set(entity.audiencelist.components(separatedBy: " "))
        self.roomtype = ChatroomType(rawValue: entity.chatroomtype)!
        self.notificationMuteState = false
        entity.log.forEach { self.log.append(UserChatLog($0 as! UserMessageEntity)) }
        entity.syslog.forEach { self.log.append(SystemLog($0 as! UserSystemMessageEntity)) }

        self.log.sort(by: { $0.timestamp < $1.timestamp })
    }

    @discardableResult
    func store(in ctx: NSManagedObjectContext) -> UserChatroomEntity {
        let userChatroomEntity = UserChatroomEntity(context: ctx)
        userChatroomEntity.chatroomid = self.chatroomid
        userChatroomEntity.audiencelist = self.audiencelist.joined(separator: " ")
        userChatroomEntity.chatroomtype = self.roomtype.rawValue

        self.log.forEach { $0.store(in: ctx, chatroomEntity: userChatroomEntity) }
        return userChatroomEntity
    }

    @discardableResult
    func remove(in ctx: NSManagedObjectContext) -> Int? {
        let fetchRequest = UserChatroomEntity.fetchByChatroomid(chatroomid: self.chatroomid)
        do {
            let fetchResult = try ctx.fetch(fetchRequest)
            fetchResult.forEach { ctx.delete($0) }
            return fetchResult.count
        } catch {
            print("in remove : \(error)")
            return nil
        }
    }
}

extension UserChatLog {

    init(_ entity: UserMessageEntity) {
        self.id = entity.chatid
        self.logType = LogType(rawValue: entity.messageType) ?? LogType.undefined
        self.writer = entity.writer
        self.timestamp = entity.timestamp.stringToDate()!
        self.detail = entity.detail
        self.readusers = Set(entity.readusers.components(separatedBy: " "))
        self.isSetReadNotification = false
    }

    func store(in context: NSManagedObjectContext, chatroomEntity: UserChatroomEntity) {
        let userMessageEntity = UserMessageEntity(context: context)
        userMessageEntity.chatid = self.id
        userMessageEntity.detail = self.detail
        userMessageEntity.writer = self.writer
        userMessageEntity.messageType = self.logType.rawValue
        userMessageEntity.readusers = self.readusers.joined(separator: " ")
        userMessageEntity.timestamp = self.timestamp.dateToString()
        userMessageEntity.chatroom = chatroomEntity
        print("added this chatlog entity \(userMessageEntity.detail)")
    }
}


extension SystemLog {

    init(_ entity: UserSystemMessageEntity) {
        self.id = entity.sysid
        self.logType = LogType(rawValue: entity.type) ?? LogType.undefined
        self.detail = entity.detail
        self.timestamp = entity.timestamp.stringToDate()!
    }

    func store(in context: NSManagedObjectContext, chatroomEntity: UserChatroomEntity) {
        let userSystemMessageEntity = UserSystemMessageEntity(context: context)
        userSystemMessageEntity.detail = self.detail
        userSystemMessageEntity.sysid = self.id
        userSystemMessageEntity.timestamp = self.timestamp.dateToString()
        userSystemMessageEntity.type = self.logType.rawValue
        userSystemMessageEntity.chatroom = chatroomEntity
    }
}

extension UserFriend {

    init(_ entity: UserFriendEntity) {
        self.email = entity.email
        self.nickname = entity.nickname
    }

    @discardableResult
    func store(in ctx: NSManagedObjectContext) -> UserFriendEntity {
        let userFriendEntity = UserFriendEntity(context: ctx)
        userFriendEntity.email = self.email
        userFriendEntity.nickname = self.nickname
        return userFriendEntity
    }

    @discardableResult
    func remove(in ctx: NSManagedObjectContext) -> Int? {
        let fetchRequest = UserFriendEntity.fetchRequestByEmail(email: self.email)
        do {
            let fetchResult = try ctx.fetch(fetchRequest)
            fetchResult.forEach { ctx.delete($0) }
            return fetchResult.count
        } catch {
            print("in remove : \(error)")
            return nil
        }
    }
}

extension ChatroomBundle {

    init(chatroomBundleEntity: UserChatroomBundle) {
        self.bundleID = chatroomBundleEntity.bundleId
        self.bundleName = chatroomBundleEntity.bundleName
        self.bundleProfileURL = chatroomBundleEntity.bundleURL
        self.bundlePosition = .init(rawValue: chatroomBundleEntity.bundlePosition) ?? .none
        if chatroomBundleEntity.chatroomList.isEmpty {
            self.bundleChatroomList = []
        } else {
            self.bundleChatroomList = chatroomBundleEntity.chatroomList.components(separatedBy: ",")
        }
    }

    @discardableResult
    func store(in ctx: NSManagedObjectContext) -> UserChatroomBundle {
        let chatroomBundleEntity = UserChatroomBundle(context: ctx)
        chatroomBundleEntity.bundleId = self.bundleID
        chatroomBundleEntity.bundleName = self.bundleName
        chatroomBundleEntity.bundlePosition = self.bundlePosition.rawValue
        chatroomBundleEntity.bundleURL = self.bundleProfileURL
        chatroomBundleEntity.chatroomList = self.bundleChatroomList.joined(separator: ",")
        return chatroomBundleEntity
    }

    @discardableResult
    func remove(in ctx: NSManagedObjectContext) -> Int? {
        let fetchRequest = UserChatroomBundle.fetchRequestById(self.bundleID)
        do {
            let fetchResult = try ctx.fetch(fetchRequest)
            fetchResult.forEach { ctx.delete($0) }
            return fetchResult.count
        } catch {
            print("bundle remove : \(error)")
            return nil
        }
    }
}

extension Array where Element == UserFriend {
    @discardableResult
    func store(in ctx: NSManagedObjectContext) -> [UserFriendEntity] {
        self.map { $0.store(in: ctx) }
    }
}

extension Array where Element == UserChatroom {

    func store(in ctx: NSManagedObjectContext) -> [UserChatroomEntity] {
        print("store : \(self.count)")
        return self.map { $0.store(in: ctx) }
    }

    func remove(in ctx: NSManagedObjectContext) -> Int? {
        print("remove : \(self.count)")
        return self.map { $0.remove(in: ctx) ?? 0 }.reduce(0, +)
    }
}
