import Foundation
import _PhotosUI_SwiftUI

struct UserReactionRequestBody {
    var email: String
    var roomid: String
    var chatid: String
    var reaction: String
}

struct UserAuthenticationReqeustBody {
    var email: String
    var password: String
    var fcmtoken: String
}

struct UserSendMessageRequestBody {
    var email: String
    var chatroomid: String
    var detail: String
}

struct UserSendWhisperMessageRequestBody {
    var email: String
    var audience: String
    var chatroomid: String
    var detail: String
}

struct UserMessageReadRequestBody {
    var email: String
    var chatroomid: String
    var chatidlist: String
    var typelist: String
}

struct UserProfileStoreRequestBody {
    var email: Data?
    var profile: Data?
}

struct UserSendPhotoMessageRequestBody {
    var email: Data
    var photoid: Data
    var chatroomid: Data
    var photoData: Data
}

struct UserSendVideoMessageRequestBody {
    var email: Data
    var videoid: Data
    var chatroomid: Data
    var title: Data
    var videoData: Data
    var thumbnail: Data
}
