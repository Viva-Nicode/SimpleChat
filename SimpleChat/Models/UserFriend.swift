import Foundation

struct UserFriend: Hashable {
    var email: String
    var nickname: String?

    static func == (lhs: UserFriend, rhs: UserFriend) -> Bool {
        return lhs.email == rhs.email
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }

    init(email: String, nickname: String? = nil) {
        self.email = email
        self.nickname = nickname
    }

    init(_ responseModel: UserDataFetchResponseModel.UserFriendResponseModel) {
        self.email = responseModel.friendEmail
        self.nickname = responseModel.nickname
    }
}
