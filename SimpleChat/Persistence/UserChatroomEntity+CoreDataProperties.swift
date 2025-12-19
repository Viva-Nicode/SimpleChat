//
//  UserChatroomEntity+CoreDataProperties.swift
//  Capstone_2
//
//  Created by Nicode . on 2/29/24.
//
//

import Foundation
import CoreData


extension UserChatroomEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserChatroomEntity> {
        return NSFetchRequest<UserChatroomEntity>(entityName: "UserChatroomEntity")
    }

    @nonobjc public class func fetchByChatroomid(chatroomid: String) -> NSFetchRequest<UserChatroomEntity> {
        let request = NSFetchRequest<UserChatroomEntity>(entityName: "UserChatroomEntity")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(UserChatroomEntity.chatroomid), chatroomid)
        return request
    }

    @NSManaged public var audiencelist: String
    @NSManaged public var chatroomid: String
    @NSManaged public var chatroomTitle: String?
    @NSManaged public var chatroomtype: String
    @NSManaged public var log: NSSet
    @NSManaged public var syslog: NSSet
}

// MARK: Generated accessors for log
extension UserChatroomEntity {

    @objc(addLogObject:)
    @NSManaged public func addToLog(_ value: UserMessageEntity)

    @objc(removeLogObject:)
    @NSManaged public func removeFromLog(_ value: UserMessageEntity)

    @objc(addLog:)
    @NSManaged public func addToLog(_ values: NSSet)

    @objc(removeLog:)
    @NSManaged public func removeFromLog(_ values: NSSet)

}

// MARK: Generated accessors for syslog
extension UserChatroomEntity {

    @objc(addSyslogObject:)
    @NSManaged public func addToSyslog(_ value: UserSystemMessageEntity)

    @objc(removeSyslogObject:)
    @NSManaged public func removeFromSyslog(_ value: UserSystemMessageEntity)

    @objc(addSyslog:)
    @NSManaged public func addToSyslog(_ values: NSSet)

    @objc(removeSyslog:)
    @NSManaged public func removeFromSyslog(_ values: NSSet)

}

extension UserChatroomEntity: Identifiable {

}
