import Alamofire
import Combine
import Foundation
import _PhotosUI_SwiftUI
import SwiftUI
import SDWebImageSwiftUI

protocol MessageSendingViewModelInterface {
    func clearDetailTextField()
    func displayNotFoundChatroomAlert()
    func dismissFullScreenCover()
    func scrollMostDown()
}

enum DataConvertingError: Error {
    case TextDataConvertingError(String)
    case PhotoDataConvertingError(PhotosPickerItem)
}

protocol MessageInteractor {

    func sendMessage(sender: String, roomid: String, detail: String,
        chatrooms: Binding<[UserChatroom]>, vm: MessageSendingViewModelInterface) -> AnyPublisher<UserChatLog, AFError>

    func sendPhotoMessage(sender: String, roomid: String, photoData: Data,
        chatrooms: Binding<[UserChatroom]>, vm: MessageSendingViewModelInterface) -> AnyCancellable

    func sendVideoMessage(sender: String, roomid: String, title: String, videoData: Data, thumbnail: Data,
        chatrooms: Binding<[UserChatroom]>, vm: MessageSendingViewModelInterface) -> AnyCancellable

    func sendWhisperMessage(email: String, receiver: String, roomid: String, detail: String,
        chatrooms: Binding<[UserChatroom]>, wmt: Binding<[String:String]>, vm: MessageSendingViewModelInterface) -> AnyCancellable

    func reportMessage(email: String, roomid: String, chatid: String,
        activeAlert: Binding<ActiveAlert>, chatrooms: Binding<[UserChatroom]>, completeAlert: Binding<Bool>) -> AnyCancellable

    func reportMessage(email: String, roomid: String, chatid: String,
        shouldShowFullScreenVideoView: Binding<Bool>, chatrooms: Binding<[UserChatroom]>) -> AnyCancellable

    func setReadNotification(email: String, roomid: String, chatid: String, audienceList: [String],
        chatrooms: Binding<[UserChatroom]>, activeBell: Binding<Bool>, isPresented: Binding<Bool>) -> AnyCancellable

    func getReadNotificatinMemberList(email: String, roomid: String, chatid: String, list: LoadableSubject<[UserFriend]>)

    func loadVideo(videoid: String, avplayer: LoadableSubject<URL>)

    func aiChatting(email: String, text: String, aiChatresult: LoadableSubject<AIChatResponse>)

    func getReactions(roomid: String, reactionsModel: Binding<MessageReactions>) -> AnyCancellable

    func setReaction(roomid: String, chatid: String, reaction: Reaction, taskStatus: TaskStatusSubject, reactions: Binding<MessageReactions>) -> AnyCancellable
}

struct RealMessageInteractor: MessageInteractor {

    let webRepository: MessageWebRepository
    let dbRepository: DBOperationsContainer

    func sendMessage(sender: String, roomid: String, detail: String, chatrooms: Binding<[UserChatroom]>,
        vm: MessageSendingViewModelInterface) -> AnyPublisher<UserChatLog, AFError> {

        vm.clearDetailTextField()

        let waitLoguuid = UUID().uuidString
        if let roomidx = chatrooms.wrappedValue[roomid] {
            withAnimation(.linear(duration: 0.3)) {
                chatrooms.wrappedValue[roomidx].log.append(UserChatLog(
                    id: waitLoguuid,
                    logType: LogType.text.rawValue,
                    writer: sender,
                    timestamp: Date().dateToString(),
                    detail: detail,
                    isSetReadNotification: false,
                    readusers: sender))
            }
            vm.scrollMostDown()
        }

        return webRepository.sendMessage(email: sender, chatroomid: roomid, detail: detail)
            .map { chat in
            if chat.id.isEmpty {
                vm.displayNotFoundChatroomAlert()
            } else {
                dbRepository.messagePersistentOperations.createMessage(chat: chat, roomid: roomid)
                if let roomidx = chatrooms.wrappedValue[roomid] {
                    if let waitidx = chatrooms.wrappedValue[roomidx].log.firstIndex(where: { $0.id == waitLoguuid }) {
                        chatrooms.wrappedValue[roomidx].log[waitidx].id = chat.id
                    }
                }
            }
            return chat
        }.eraseToAnyPublisher()
    }

    func sendPhotoMessage(sender: String, roomid: String, photoData: Data,
        chatrooms: Binding<[UserChatroom]>, vm: MessageSendingViewModelInterface) -> AnyCancellable {

        vm.dismissFullScreenCover()

        let photoId = UUID().uuidString
        let cacheKey = "\(serverUrl)/chat/get-chatphoto/\(photoId)"
        let image = UIImage(data: photoData)?.fixedOrientation().clippingImage()

        SDImageCache.shared.store(image, forKey: cacheKey, completion: {
            if let roomidx = chatrooms.wrappedValue[roomid] {
                withAnimation(.linear(duration: 0.3)) {
                    chatrooms.wrappedValue[roomidx].log.append(UserChatLog(
                        id: photoId,
                        logType: LogType.photo.rawValue,
                        writer: sender,
                        timestamp: Date().dateToString(),
                        detail: "photo",
                        isSetReadNotification: false,
                        readusers: sender,
                        mediaState: .loading))
                }
                vm.scrollMostDown()
            }
        })

        return webRepository.sendPhotoMessage(email: sender, photoId: photoId, chatroomid: roomid, photoData: photoData)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("sendPhotoMessage finished")
            case .failure(let error):
                print(error.errorDescription ?? "nil")
            }
        }, receiveValue: { photoChat in
                if photoChat.id.isEmpty {
                    vm.displayNotFoundChatroomAlert()
                } else {
                    dbRepository.messagePersistentOperations.createMessage(chat: photoChat, roomid: roomid)
                    if let roomidx = chatrooms.wrappedValue[roomid] {
                        if let photoChatIndex = chatrooms.wrappedValue[roomidx].log.firstIndex(where: { $0.id == photoId }) {
                            withAnimation(.spring(duration: 0.3)) {
                                chatrooms.wrappedValue[roomidx].log[photoChatIndex].changeMediaStateAsComplete(.complete)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation(.spring(duration: 0.3)) {
                                    chatrooms.wrappedValue[roomidx].log[photoChatIndex].changeMediaStateAsComplete(.end)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    func sendVideoMessage(sender: String, roomid: String, title: String, videoData: Data, thumbnail: Data,
        chatrooms: Binding<[UserChatroom]>, vm: any MessageSendingViewModelInterface) -> AnyCancellable {

        vm.dismissFullScreenCover()

        let videoId = UUID().uuidString
        let cacheKey = "\(serverUrl)/chat/get-thumbnail/\(videoId)"
        let image = UIImage(data: thumbnail)?.fixedOrientation().clippingImage()

        SDImageCache.shared.store(image, forKey: cacheKey, completion: {
            if let roomidx = chatrooms.wrappedValue[roomid] {
                withAnimation(.linear(duration: 0.3)) {
                    chatrooms.wrappedValue[roomidx].log.append(UserChatLog(
                        id: videoId,
                        logType: LogType.video.rawValue,
                        writer: sender,
                        timestamp: Date().dateToString(),
                        detail: title == "" ? "No Title Video" : title,
                        isSetReadNotification: false,
                        readusers: sender,
                        mediaState: .loading))
                }
                vm.scrollMostDown()
            }
        })

        return webRepository.sendVideoMessage(email: sender, chatroomid: roomid, videoid: videoId, title: title, videoData: videoData, thumbnail: thumbnail)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("sendVideoMessage finished")
            case .failure(let error):
                print("in sendVideoMessage interaction")
                print(error.localizedDescription)
            }
        }, receiveValue: { videoChat in
                if videoChat.id.isEmpty {
                    vm.displayNotFoundChatroomAlert()
                } else {
                    dbRepository.messagePersistentOperations.createMessage(chat: videoChat, roomid: roomid)

                    if let roomidx = chatrooms.wrappedValue[roomid] {
                        if let videoChatIndex = chatrooms.wrappedValue[roomidx].log.firstIndex(where: { $0.id == videoId }) {
                            withAnimation(.spring(duration: 0.3)) {
                                chatrooms.wrappedValue[roomidx].log[videoChatIndex].changeMediaStateAsComplete(.complete)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation(.spring(duration: 0.3)) {
                                    chatrooms.wrappedValue[roomidx].log[videoChatIndex].changeMediaStateAsComplete(.end)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    func loadVideo(videoid: String, avplayer: LoadableSubject<URL>) {
        let cb = CancelBag()
        avplayer.wrappedValue.setIsLoading(cancelBag: cb)

        webRepository.loadVideo(videoid: videoid)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("video load finished")
            case .failure(let error):
                print("error desc : \(error.localizedDescription)")
            }
        }, receiveValue: { videoURL in
                avplayer.wrappedValue = .loaded(videoURL)
            }
        ).store(in: cb)
    }

    func sendWhisperMessage(email: String, receiver: String, roomid: String, detail: String,
        chatrooms: Binding<[UserChatroom]>, wmt: Binding<[String:String]>, vm: MessageSendingViewModelInterface) -> AnyCancellable {

        vm.clearDetailTextField()

        return webRepository.sendWhisperMessage(email: email, audience: receiver, chatroomid: roomid, detail: detail)
            .sink(receiveCompletion: { _ in },
            receiveValue: { whisperChat in
                dbRepository.messagePersistentOperations.createMessage(chat: whisperChat, roomid: roomid)
                if let roomidx = chatrooms.wrappedValue[roomid] {
                    wmt.wrappedValue[whisperChat.id] = receiver
                    withAnimation(.linear(duration: 0.3)) {
                        chatrooms.wrappedValue[roomidx].log.append(whisperChat)
                    }
                    vm.scrollMostDown()
                }
            }
        )
    }

    func getReadNotificatinMemberList(email: String, roomid: String, chatid: String, list: LoadableSubject<[UserFriend]>) {
        let cb = CancelBag()
        list.wrappedValue.setIsLoading(cancelBag: cb)

        return webRepository.getReadNotificationSetableMemeberList(email: email, roomid: roomid, chatid: chatid)
            .sink(receiveCompletion: { _ in },
            receiveValue: { memeberlist in
                list.wrappedValue = .loaded(memeberlist)
            }).store(in: cb)
    }

    func reportMessage(email: String, roomid: String, chatid: String, activeAlert: Binding<ActiveAlert>,
        chatrooms: Binding<[UserChatroom]>, completeAlert: Binding<Bool>) -> AnyCancellable {
        return webRepository.reportMessage(email: email, roomid: roomid, chatid: chatid)
            .sink(receiveCompletion: { _ in },
            receiveValue: { value in
                if value.code == .success {
                    completeAlert.wrappedValue = false
                    activeAlert.wrappedValue = .messageReportComplete
                    completeAlert.wrappedValue = true
                    if let roomidx = chatrooms.wrappedValue.firstIndex(where: { $0.chatroomid == roomid }) {
                        if let chatidx = chatrooms.wrappedValue[roomidx].log.firstIndex(where: { $0.id == chatid }) {
                            chatrooms.wrappedValue[roomidx].log[chatidx].logType = .blocked
                        }
                    }
                }
            }
        )
    }

    func reportMessage(email: String, roomid: String, chatid: String, shouldShowFullScreenVideoView: Binding<Bool>,
        chatrooms: Binding<[UserChatroom]>) -> AnyCancellable {
        return webRepository.reportMessage(email: email, roomid: roomid, chatid: chatid)
            .sink(receiveCompletion: { _ in },
            receiveValue: { value in
                if value.code == .success {

                    if let roomidx = chatrooms.wrappedValue.firstIndex(where: { $0.chatroomid == roomid }) {
                        if let chatidx = chatrooms.wrappedValue[roomidx].log.firstIndex(where: { $0.id == chatid }) {
                            chatrooms.wrappedValue[roomidx].log[chatidx].logType = .blocked
                        }
                    }
                    let copy = URL.documentsDirectory.appending(path: "chatvideos/\(chatid).mp4")
                    if FileManager.default.fileExists(atPath: copy.path()) {
                        do {
                            try FileManager.default.removeItem(at: copy)
                        } catch {
                            debugPrint("error during the remove video")
                        }
                        withAnimation(.spring(duration: 0.3)) {
                            shouldShowFullScreenVideoView.wrappedValue = false
                        }
                    } else {
                        print("\(chatid).mp4 is not exist already")
                        withAnimation(.spring(duration: 0.3)) {
                            shouldShowFullScreenVideoView.wrappedValue = false
                        }
                    }
                }
            }
        )
    }

    func aiChatting(email: String, text: String, aiChatresult: LoadableSubject<AIChatResponse>) {
        let cb = CancelBag()
        aiChatresult.wrappedValue.setIsLoading(cancelBag: cb)

        return webRepository.aiChatMessage(email: email, text: text)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("aichat finished")
            case .failure(let error):
                print(error.errorDescription ?? "nil")
            }
        }, receiveValue: { value in
                print(value)
                aiChatresult.wrappedValue = .loaded(value)
            }).store(in: cb)
    }

    func getReactions(roomid: String, reactionsModel: Binding<MessageReactions>) -> AnyCancellable {
        webRepository.getReactions(roomid: roomid)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("getReactions finished")
            case .failure(let error):
                print("getReactions fail : \(error.errorDescription ?? "")")
            }
        }, receiveValue: {
                reactionsModel.wrappedValue = $0
//                for (_, v) in $0.reactionTable.enumerated() {
//                    print("key : \(v.key)")
//                    for react in v.value {
//                        print("\(react.email) : \(react.reaction)")
//                    }
//                }
            }
        )
    }

    func setReaction(roomid: String, chatid: String, reaction: Reaction, taskStatus: TaskStatusSubject, reactions: Binding<MessageReactions>) -> AnyCancellable {
        taskStatus.wrappedValue = .processing

        return webRepository.setReaction(email: reaction.email, roomid: roomid, chatid: chatid, reaction: reaction)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("setReactions finished")
            case .failure(let error):
                print("setReactions fail : \(error.errorDescription ?? "")")
            }
        }, receiveValue: { res in
                DispatchQueue.main.async {
                    switch res.code {
                    case .success:
                        if reaction.reaction != .cancel {

                            if reactions.wrappedValue.reactionTable[chatid] == nil {
                                reactions.wrappedValue.reactionTable[chatid] = []
                            }

                            if let idx = reactions.wrappedValue.reactionTable[chatid]!.firstIndex(where: { $0.email == reaction.email }) {
                                reactions.wrappedValue.reactionTable[chatid]!.remove(at: idx)
                            }
                            reactions.wrappedValue.reactionTable[chatid]!.append(reaction)
                            taskStatus.wrappedValue = .complete
                        }
                    case .cancel:
                        if let idx = reactions.wrappedValue.reactionTable[chatid]!.firstIndex(where: { $0.email == reaction.email }) {
                            reactions.wrappedValue.reactionTable[chatid]!.remove(at: idx)
                        }
                        taskStatus.wrappedValue = .complete
                    case .canceledAlready:
                        debugPrint("이미 없는데 왜 또 취소하세요?")
                    case .dup:
                        debugPrint("레전드 버그 발생")
                    case .undefined:
                        break
                    }
                }
            })
    }

    func setReadNotification(email: String, roomid: String, chatid: String, audienceList: [String],
        chatrooms: Binding<[UserChatroom]>, activeBell: Binding<Bool>, isPresented: Binding<Bool>) -> AnyCancellable {
        return webRepository.setReadNotification(email: email, roomid: roomid, chatid: chatid, audiences: audienceList.joined(separator: " "))
            .sink(receiveCompletion: { _ in },
            receiveValue: { res in
                if let roomidx = chatrooms.wrappedValue[roomid] {
                    if let chatidx = chatrooms.wrappedValue[roomidx].log.firstIndex(where: { $0.id == chatid }) {
                        if var chatlog = chatrooms.wrappedValue[roomidx].log[chatidx] as? UserChatLog {
                            if res.code.rawValue > 0 {
                                chatlog.isSetReadNotification = true
                                withAnimation(.spring(duration: 0.3)) {
                                    isPresented.wrappedValue = false
                                    activeBell.wrappedValue = true
                                }
                            } else {
                                chatlog.isSetReadNotification = false
                                withAnimation(.spring(duration: 0.3)) {
                                    isPresented.wrappedValue = false
                                    activeBell.wrappedValue = false
                                }
                            }
                            chatrooms.wrappedValue[roomidx].log[chatidx] = chatlog
                        }
                    }
                }
            }
        )
    }
}

