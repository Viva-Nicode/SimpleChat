import Foundation
import SwiftUI

struct SecretCommand: Hashable {

    enum CommandAction: String {
        case background = "background"
        case aichat = "aichat"
        case undefined = "undefined"
    }

    enum CommandOption: String {
        case hutao = "hutao"
        case furina = "furina"
        case none = "none"
        case undefined = "undefined"
    }

    let action: CommandAction
    let option: CommandOption

    init(commandString: String) {
        let cmd = commandString.components(separatedBy: ":")[1]
            .components(separatedBy: "?")
        self.action = .init(rawValue: cmd[0]) ?? .undefined
        self.option = .init(rawValue: cmd[1]) ?? .undefined
    }
}

class SecretCommandModel: ObservableObject {

    @Published private var commandsSet: Set<String>
    @Published private var activedCommand: Set<SecretCommand> = Set()

    init() {

        commandsSet = Set(
            [
                "secret-cmd:background?hutao",
                "secret-cmd:background?furina",
                "secret-cmd:aichat?none"
            ]
        )
        for cmd in commandsSet {
            if let _ = UserDefaults.standard.string(forKey: cmd) {
                activedCommand.insert(SecretCommand(commandString: cmd))
            }
        }
    }

    // secret command를 입력하는 부분
    public func isSecretCommand(command: String) -> Bool {
        guard let _ = UserDefaults.standard.string(forKey: "activeSecretMode") else { return false }

        let isCorrectCommand = commandsSet.contains(command)
        if isCorrectCommand {
            self.activedCommand.insert(SecretCommand(commandString: command))
            UserDefaults.standard.set("active", forKey: command)
        }
        return isCorrectCommand
    }

    public func isActivedCommand(_ act: SecretCommand.CommandAction, _ opt: SecretCommand.CommandOption) -> Bool {
        guard let _ = UserDefaults.standard.string(forKey: "activeSecretMode") else { return false }

        let cmd = SecretCommand(commandString: "secret-cmd:\(act.rawValue)?\(opt.rawValue)")
        return activedCommand.contains(cmd)
    }
}
