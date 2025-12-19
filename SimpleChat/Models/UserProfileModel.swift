//
//  UserProfileModel.swift
//  SimpleChat
//
//  Created by Nicode . on 6/21/24.
//

import Foundation

public enum ProfileType: String {
    case profile = "profile"
    case background = "background"
    case undefined = "undefined"
}

struct UserProfileModel: Hashable {
    var imageName: String
    var timestamp: Date
    var isCurrentUsing: Bool
    var profileType: ProfileType

    init(_ userProfileResponseModel: UserProfileResponseModel) {
        self.imageName = userProfileResponseModel.imageName
        self.timestamp = userProfileResponseModel.timestamp.stringToDate() ?? Date()
        self.isCurrentUsing = userProfileResponseModel.isCurrentUsing
        self.profileType = ProfileType(rawValue: userProfileResponseModel.profileType) ?? .undefined
    }
}
