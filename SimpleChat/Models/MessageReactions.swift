import Foundation

enum ReactionState: String {
    case cancel = "CANCEL"
    case good = "GOOD"
    case read = "READ"
    case bad = "BAD"
    case happy = "HAPPY"
    case question = "QUESTION"
    case undefined = "UNDEFINED"

    static let activeReactions: [Self] = [.good, .read, .bad, .happy, .question]
}

struct Reaction: Hashable {
    var email: String
    var reaction: ReactionState
    var timestamp: Date
}

struct MessageReactions: Equatable {
    var reactionTable: [String: [Reaction]] = [:]

    init() { }

    init(responseModel: [ReactionResponseModel]) {
        responseModel.forEach { react in
            if self.reactionTable[react.chatid] == nil {
                self.reactionTable[react.chatid] = []
            }
            self.reactionTable[react.chatid]?.append(Reaction(email: react.email,
                reaction: ReactionState(rawValue: react.reaction) ?? .undefined,
                timestamp: react.timestamp.stringToDate() ?? Date()))
        }
    }
}
