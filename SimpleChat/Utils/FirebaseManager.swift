//
//  FirebaseManager.swift
//  SimpleChat
//
//  Created by Nicode . on 2023/07/17.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseMessaging


class FirebaseManager : NSObject {
    let auth : Auth
    let storage : Storage
    let firestore : Firestore
    
    static let shared = FirebaseManager()
    
    override init(){
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        super.init()
    }
}

