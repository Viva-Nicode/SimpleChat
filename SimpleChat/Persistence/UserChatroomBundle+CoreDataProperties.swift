//
//  UserChatroomBundle+CoreDataProperties.swift
//  SimpleChat
//
//  Created by Nicode . on 11/13/24.
//
//

import Foundation
import CoreData


extension UserChatroomBundle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserChatroomBundle> {
        return NSFetchRequest<UserChatroomBundle>(entityName: "UserChatroomBundle")
    }

    @nonobjc public class func fetchRequestById(_ id: String) -> NSFetchRequest<UserChatroomBundle> {
        let request = NSFetchRequest<UserChatroomBundle>(entityName: "UserChatroomBundle")
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(UserChatroomBundle.bundleId), id)
        return request
    }

    @NSManaged public var bundleId: String
    @NSManaged public var bundleName: String
    @NSManaged public var bundleURL: String?
    @NSManaged public var bundlePosition: String
    @NSManaged public var chatroomList: String

}

extension UserChatroomBundle: Identifiable {

}
