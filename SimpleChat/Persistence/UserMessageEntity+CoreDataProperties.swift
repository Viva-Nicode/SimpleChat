//
//  UserMessageEntity+CoreDataProperties.swift
//  Capstone_2
//
//  Created by Nicode . on 2/29/24.
//
//

import Foundation
import CoreData


extension UserMessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMessageEntity> {
        return NSFetchRequest<UserMessageEntity>(entityName: "UserMessageEntity")
    }

    @NSManaged public var chatid: String
    @NSManaged public var detail: String
    @NSManaged public var messageType: String
    @NSManaged public var readusers: String
    @NSManaged public var timestamp: String
    @NSManaged public var writer: String
    @NSManaged public var chatroom: UserChatroomEntity

}

extension UserMessageEntity : Identifiable {

}
