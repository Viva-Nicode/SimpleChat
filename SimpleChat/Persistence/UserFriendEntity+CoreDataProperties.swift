//
//  UserFriendEntity+CoreDataProperties.swift
//  Capstone_2
//
//  Created by Nicode . on 2/23/24.
//
//

import Foundation
import CoreData


extension UserFriendEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserFriendEntity> {
        return NSFetchRequest<UserFriendEntity>(entityName: "UserFriendEntity")
    }
    
    
    @nonobjc public class func fetchRequestByEmail(email:String) -> NSFetchRequest<UserFriendEntity> {
        let request = NSFetchRequest<UserFriendEntity>(entityName: "UserFriendEntity")
        request.predicate = NSPredicate(format: "%K == %@",#keyPath(UserFriendEntity.email), email)
        return request
    }

    @NSManaged public var email: String
    @NSManaged public var nickname: String?
}

extension UserFriendEntity : Identifiable {

}
