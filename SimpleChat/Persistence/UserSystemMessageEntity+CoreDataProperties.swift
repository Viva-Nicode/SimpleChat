//
//  UserSystemMessageEntity+CoreDataProperties.swift
//  Capstone_2
//
//  Created by Nicode . on 2/29/24.
//
//

import Foundation
import CoreData


extension UserSystemMessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSystemMessageEntity> {
        return NSFetchRequest<UserSystemMessageEntity>(entityName: "UserSystemMessageEntity")
    }

    @NSManaged public var detail: String
    @NSManaged public var sysid: String
    @NSManaged public var timestamp: String
    @NSManaged public var type: String
    @NSManaged public var chatroom: UserChatroomEntity

}

extension UserSystemMessageEntity : Identifiable {

}
