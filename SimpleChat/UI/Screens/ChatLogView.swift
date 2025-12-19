import SwiftUI
import CoreData
import Alamofire
import SDWebImageSwiftUI
import Foundation
import PhotosUI
import Combine
import AVFoundation
import WebRTC
import UIKit
import AVKit

enum ActiveAlert {
    case messageSendFail
    case messageReport
    case messageReportComplete
    case permissionRequest
}

enum SendVideoViewAlert {
    case tooBiggerSizeVideo
    case videoConvertingError
    case unsupportedVideoFormat
}

struct TextFieldLimitModifer: ViewModifier {
    @Binding var value: String
    var length: Int

    func body(content: Content) -> some View {
        content
            .onReceive(value.publisher.collect()) {
            value = String($0.prefix(length))
        }
    }
}

extension View {
    func limitInputLength(value: Binding<String>, length: Int) -> some View {
        self.modifier(TextFieldLimitModifer(value: value, length: length))
    }
}

class MessageSendingViewModel: ObservableObject {
    @Published var scrollDownToggle = false
    @Published var userInputText = ""
    @Published var videoTitleText = ""
    @Published var messagePhotosPickerItem: PhotosPickerItem?
    @Published var messagePickerUIImage: UIImage?

    @Published var messageVideoData: Data?
    @Published var messageVideoThumbnailData: Data?

    @Published var shouldShowDidSendPhotoFullScreenView = false
    @Published var shouldShowDidSendVideoFullScreenView = false
    @Published var shouldShowWhisperMemberListView = false

    @Published var activeAlert: ActiveAlert = .messageReport
    @Published var videoSendingViewAlert: SendVideoViewAlert = .tooBiggerSizeVideo

    @Published var shouldShowAlert = false
    @Published var shouldShowVideoSendingViewAlert = false
}

extension MessageSendingViewModel: MessageSendingViewModelInterface {

    func clearDetailTextField() { userInputText = "" }

    func displayNotFoundChatroomAlert() {
        activeAlert = .messageSendFail
        shouldShowAlert = true
    }

    func dismissFullScreenCover() {
        shouldShowDidSendPhotoFullScreenView = false
        shouldShowDidSendVideoFullScreenView = false
    }

    func scrollMostDown() { scrollDownToggle.toggle() }
}

class PresentationViewModel: ObservableObject {
    @Published var shouldShowChatroomInfoCover = false
    @Published var shouldShowNewuserInviteView = false
    @Published var shouldShowNewMessageButton = false
    @Published var shouldShowFriendDetailView = false
    @Published var shouldShowChatroomEditView = false
    @Published var shouldShowAiChatView = false
    @Published var shouldShowVoiceChatroomView = false
    @Published var shouldShowOptionalFeaturesBar = false
    @Published var shouldShowMessageSendingPhotoPickerView = false
    @Published var shouldShowReadNotificationSettingView = false
    @Published var shouldShowFullScreenVideoView = false
    @Published var shouldShowFullScreenPhotoView = false
    @Published var shouldShowChatroomBackgroundPhotoPickerView = false
    @Published var shouldShowChatroomBackgroundActionSheet = false
    @Published var shouldShowBuiltInBackgroundPhotoSelectionView = false
}

class ChatLogViewModel: ObservableObject {

    @Published var selectedUserList: [String] = []
    @Published var searchKeywordInput: String = ""

    @Published var chatDetailViewId: String = ""
    @Published var friendDetailViewTarget = ""

    @Published var chatroomProfilephotosPickerItem: PhotosPickerItem?
    @Published var chatroomProfilephotosUIImage: UIImage?

    @Published var chatroomBackgroundphotosPickerItem: PhotosPickerItem?
    @Published var chatroomBackgroundphotosUIImage: UIImage?

    @Published var subscriptions: Set<AnyCancellable> = []

    @Published var bell: Binding<Bool>? = nil
    @Published var readNotificationSetableMemberList: Loadable<[UserFriend]> = .notRequested
    @Published var setReadNotificationList: [String] = []
    @Published var setReadNotificationChatId = ""

    @Published var reportedChatid = ""
    @Published var currentButtonInedx = 1
}

struct ChatLogView: View {

    @Environment(\.injected) private var injected: DIContainer
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var appSettingModel: AppSettingModel

    @StateObject var chatlogViewModel = ChatLogViewModel()
    @StateObject var messageSendingViewModel = MessageSendingViewModel()
    @StateObject var presentationViewModel = PresentationViewModel()
    @ObservedObject private var sc: SecretCommandModel = SecretCommandModel()

    @EnvironmentObject var currentViewObject: CurrentViewObject
    @FocusState private var isFocused: Bool

    //MARK: side menu presentation
    @State private var sidemenuoffset = UIScreen.main.bounds.width * 0.9
    @State private var isPresentSidemenu = false

    @State private var subscriptions: Set<AnyCancellable> = []
    @State var chatroomTitle: String = ""
    @State var chatroomTitleTextField: String = ""
    @State var successToLoadChatroomProfilePhoto = true
    @State var scrollDownUntilMostBottom: (() -> ())?
    @State var successToLoadChatroomBackgroundPhoto = false
    @State var refreshChatroomBackgroundPhoto = true

    @State var lastMessageGeometryProxy: GeometryProxy?

    @State var isDisabledScroll = false
    @State var chatReactions: MessageReactions = MessageReactions()

    @State private var selectedMessageIdForShowContextMenu: String?
    @StateObject var keyboardResponder = KeyboardResponder()

    let currentChatroomid: String

    @State private var built_in_BackgroundPhotoNames: [String] = [
        "builtin-background-eggs",
        "builtin-background-nightsky",
        "builtin-background-oranges",
        "builtin-background-cats",
        "builtin-background-cookies",
        "builtin-background-dark-pastel",
        "builtin-background-right-pastel"
    ]

    let unselectedFriendColor: LinearGradient = LinearGradient(colors: [.black.opacity(0.05)], startPoint: .top, endPoint: .bottom)

    let selectedFriendColor: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color("Gradation orange end light"), Color("pastel green")]),
        startPoint: .topLeading, endPoint: .bottomTrailing)

    let optionalVoiceButtonColor: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color("OptionalButton1-1"), Color("OptionalButton1-2")]),
        startPoint: .topLeading, endPoint: .bottomTrailing)

    let optionalInviteButtonColor: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color("OptionalButton4-1"), Color("OptionalButton4-2")]),
        startPoint: .topTrailing, endPoint: .bottomLeading)

    let optionalAIChatButtonColor: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color("OptionalButton2-1"), Color("OptionalButton2-2")]),
        startPoint: .topLeading, endPoint: .bottomTrailing)

    let optionalEditButtonColor: LinearGradient = LinearGradient(
        gradient: Gradient(colors: [Color("OptionalButton3-1"), Color("OptionalButton3-2")]),
        startPoint: .topLeading, endPoint: .bottomTrailing)

    @State var aiMessage: Loadable<AIChatResponse> = .notRequested
    @State var aichatText: String = ""

    @State var selectedBuiltInBackgroundPhotoName: String?
    @State var fullScreenPhotoId: String?
    @State var fullScreenVideoId: String?
    @State private var videoConvertState: VideoConvertState = .unknown

    @State private var renderingLimit = 30

    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                messageView
                    .simultaneousGesture(TapGesture().onEnded {
                        withAnimation(.spring(duration: 0.3)) {
                            isFocused = false
                            presentationViewModel.shouldShowOptionalFeaturesBar = false
                            NotificationCenter.default.post(name: .hideContextMenu, object: nil, userInfo: nil)
                        }
                    }
                ).photosPicker(isPresented: $presentationViewModel.shouldShowMessageSendingPhotoPickerView, selection: $messageSendingViewModel.messagePhotosPickerItem)
            }.onAppear {
                currentViewObject.currentChatroomid = currentChatroomid
                chatroomTitle = applicationViewModel.userChatroomTitles[currentChatroomid] ?? ""

                if let email: String = UserDefaultsKeys.userEmail.value() {
                    injected.interactorContainer.chatroomInteractor.readMessage(email, currentChatroomid,
                        $applicationViewModel.userChatrooms
                    ).store(in: &subscriptions)
                }
            }.onReceive(NotificationCenter.default.publisher(for: .completeDataInit)) { notification in
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    injected.interactorContainer.chatroomInteractor.readMessage(email, currentChatroomid,
                        $applicationViewModel.userChatrooms).store(in: &subscriptions)
                }
            }.onReceive(NotificationCenter.default.publisher(for: .arrivedReaction)) { notification in
                if let roomid = notification.userInfo?["roomid"] as? String {
                    if currentChatroomid == roomid {
                        let email = notification.userInfo!["email"] as! String
                        let chatid = notification.userInfo!["chatid"] as! String
                        let reaction = notification.userInfo!["reaction"] as! String

                        let reactionState = ReactionState(rawValue: reaction) ?? .undefined

                        if ReactionState.activeReactions.contains(reactionState) {

                            if chatReactions.reactionTable[chatid] == nil {
                                chatReactions.reactionTable[chatid] = []
                            }

                            if let idx = chatReactions.reactionTable[chatid]!.firstIndex(where: { $0.email == email }) {
                                chatReactions.reactionTable[chatid]!.remove(at: idx)
                            }

                            chatReactions.reactionTable[chatid]!.append(Reaction(email: email,
                                reaction: reactionState, timestamp: Date()))
                        } else if reactionState == .cancel {
                            if chatReactions.reactionTable[chatid] != nil {
                                if let idx = chatReactions.reactionTable[chatid]!.firstIndex(where: { $0.email == email }) {
                                    chatReactions.reactionTable[chatid]?.remove(at: idx)
                                }
                            }
                        }
                    }
                }
            }.onReceive(NotificationCenter.default.publisher(for: .arrivedMessage)) { notification in
                if let email: String = UserDefaultsKeys.userEmail.value(), let roomid = notification.userInfo?["roomid"] as? String {

                    if roomid == currentChatroomid {
                        injected.interactorContainer.chatroomInteractor.readMessage(email, currentChatroomid,
                            $applicationViewModel.userChatrooms).store(in: &subscriptions)

                        if let lastMessageGeometryProxy {
                            // 빨간 바의 위쪽 변의 높이가 스크린 아래로 내려가있는 상태라면 버튼 생성
                            if lastMessageGeometryProxy.frame(in: .global).minY > screenHeight - keyboardResponder.currentHeight {
                                withAnimation(.spring(duration: 0.3)) { presentationViewModel.shouldShowNewMessageButton = true }
                            } else {
                                scrollDownUntilMostBottom?()
                            }
                        }
                    }
                }
            }
                .onDisappear { currentViewObject.currentChatroomid = nil }
                .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isFocused = false
                        withAnimation(.spring(duration: 0.3)) {
                            if presentationViewModel.shouldShowOptionalFeaturesBar { presentationViewModel.shouldShowOptionalFeaturesBar = false }
                        }

                        if presentationViewModel.shouldShowChatroomInfoCover {
                            withAnimation(.spring(duration: 0.3)) {
                                presentationViewModel.shouldShowChatroomInfoCover = false
                                sidemenuoffset = UIScreen.main.bounds.width * 0.9
                            } completion: { isPresentSidemenu = false }
                        } else {
                            NotificationCenter.default.post(name: .hideContextMenu, object: nil, userInfo: nil)
                            isPresentSidemenu = true
                            withAnimation(.spring(duration: 0.3)) {
                                presentationViewModel.shouldShowChatroomInfoCover = true
                                sidemenuoffset = .zero
                            }
                        }
                    }) { Image(systemName: "line.horizontal.3").contentShape(Rectangle()) }
                }
            }.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if presentationViewModel.shouldShowChatroomInfoCover {
                            withAnimation(.spring(duration: 0.3)) {
                                presentationViewModel.shouldShowChatroomInfoCover = false
                                sidemenuoffset = UIScreen.main.bounds.width * 0.9
                            } completion: { isPresentSidemenu = false }
                        }
                        NotificationCenter.default.post(name: .hideContextMenu, object: nil, userInfo: nil)
                        withAnimation(.spring(duration: 0.3)) {
                            presentationViewModel.shouldShowOptionalFeaturesBar.toggle()
                        }
                    }) { Image(systemName: "cat").contentShape(Rectangle()) }
                }
            }.fullScreenCover(isPresented: $presentationViewModel.shouldShowChatroomEditView) {
                chatroomProfileEditView
            }.fullScreenCover(isPresented: $presentationViewModel.shouldShowVoiceChatroomView) {
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    if let roomidx = applicationViewModel.userChatrooms.firstIndex(where: { $0.chatroomid == currentChatroomid }) {
                        VoiceChatroomView(shouldShowVoiceChatroomView: $presentationViewModel.shouldShowVoiceChatroomView, roomid: currentChatroomid,
                            audience: applicationViewModel.userChatrooms[roomidx].audiencelist.filter { $0 != email }.first!)
                    }
                }
            }.fullScreenCover(isPresented: $presentationViewModel.shouldShowAiChatView) {
                aiChatView
            }.fullScreenCover(isPresented: $presentationViewModel.shouldShowNewuserInviteView) {
                newuserInviteView
            }.fullScreenCover(isPresented: $presentationViewModel.shouldShowFriendDetailView) {
                ZStack {
                    if let idx = self.applicationViewModel.userChatrooms[currentChatroomid] {
                        FriendDetailView(friendEmail: chatlogViewModel.friendDetailViewTarget,
                            isPresented: $presentationViewModel.shouldShowFriendDetailView,
                            closeSideMenu: {
                                withAnimation(.spring(duration: 0.3)) {
                                    presentationViewModel.shouldShowChatroomInfoCover = false
                                    sidemenuoffset = UIScreen.main.bounds.width * 0.9
                                } completion: { isPresentSidemenu = false }
                            }, chatroomType: applicationViewModel.userChatrooms[idx].roomtype)
                    }
                }.background(TransparentBackgroundView())
            }.navigationTitle(chatroomTitle)

            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if let idx = self.applicationViewModel.userChatrooms[currentChatroomid] {
                            if applicationViewModel.userChatrooms[idx].roomtype == .group {
                                VStack(alignment: .center, spacing: 5) {
                                    ZStack(alignment: .center) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 45)
                                            .foregroundStyle(.white)
                                    }.padding(8)
                                    Text("Invite")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .foregroundStyle(optionalInviteButtonColor)
                                }
                                    .cornerRadius(15)
                                    .containerRelativeFrame(.horizontal, count: 4, spacing: 8)
                                    .clipped()
                                    .scrollTransition { content, phase in
                                    content.opacity(phase.isIdentity ? 1.0 : 0.0)
                                        .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
                                        .offset(y: phase.isIdentity ? 0 : 50)
                                }.onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) {
                                        presentationViewModel.shouldShowOptionalFeaturesBar = false
                                    }
                                    presentationViewModel.shouldShowNewuserInviteView = true
                                }.id("invite")
                            } else {
                                VStack(alignment: .center, spacing: 5) {
                                    ZStack(alignment: .center) {
                                        Image(systemName: "speaker.wave.2.bubble.rtl")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 45)
                                            .foregroundStyle(.white)
                                    }.padding(8)
                                    Text("Voice")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .foregroundStyle(optionalVoiceButtonColor)
                                }
                                    .cornerRadius(15)
                                    .containerRelativeFrame(.horizontal, count: 4, spacing: 8)
                                    .clipped()
                                    .scrollTransition { content, phase in
                                    content.opacity(phase.isIdentity ? 1.0 : 0.0)
                                        .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
                                        .offset(y: phase.isIdentity ? 0 : 50)
                                }.onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) {
                                        presentationViewModel.shouldShowOptionalFeaturesBar = false
                                    }
                                    if Permissions.checkAudioAuthorizationStatus() != .allowed || Permissions.checkCameraAuthorizationStatus() != .allowed {
                                        messageSendingViewModel.activeAlert = .permissionRequest
                                        messageSendingViewModel.shouldShowAlert = true
                                    } else {
                                        presentationViewModel.shouldShowVoiceChatroomView = true
                                    }
                                }.id("voice")
                            }
                        }

                        if sc.isActivedCommand(.aichat, .none) {
                            VStack(alignment: .center, spacing: 5) {
                                ZStack(alignment: .center) {
                                    Image(systemName: "cpu")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 45)
                                        .foregroundStyle(.white)
                                }.padding(8)
                                Text("AI Chat")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                            }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .foregroundStyle(optionalAIChatButtonColor)
                            }
                                .cornerRadius(15)
                                .containerRelativeFrame(.horizontal, count: 4, spacing: 8)
                                .clipped()
                                .scrollTransition { content, phase in
                                content.opacity(phase.isIdentity ? 1.0 : 0.0)
                                    .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
                                    .offset(y: phase.isIdentity ? 0 : 50)
                            }.onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    presentationViewModel.shouldShowOptionalFeaturesBar = false
                                }
                                presentationViewModel.shouldShowAiChatView = true
                            }.id("ai chat")
                        }

                        VStack(alignment: .center, spacing: 5) {
                            ZStack(alignment: .center) {
                                Image(systemName: "bubbles.and.sparkles.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 45)
                                    .foregroundStyle(.white)
                            }.padding(8)
                            Text("Edit")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background {
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundStyle(optionalEditButtonColor)
                        }
                            .cornerRadius(15)
                            .containerRelativeFrame(.horizontal, count: 4, spacing: 8)
                            .clipped()
                            .scrollTransition { content, phase in
                            content.opacity(phase.isIdentity ? 1.0 : 0.0)
                                .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
                                .offset(y: phase.isIdentity ? 0 : 50)
                        }.onTapGesture {
                            withAnimation(.spring(duration: 0.3)) {
                                presentationViewModel.shouldShowOptionalFeaturesBar = false
                            }
                            presentationViewModel.shouldShowChatroomEditView = true
                        }.id("chatroomEdit")
                    }.scrollTargetLayout()
                }
                    .background(BackgroundBlurView())
                    .contentMargins(8, for: .scrollContent)
                    .scrollTargetBehavior(.viewAligned)
                    .offset(y: presentationViewModel.shouldShowOptionalFeaturesBar ? 0 : -UIScreen.main.bounds.height * 0.1)
                    .zIndex(99)
                Spacer().opacity(0).zIndex(-1)
            }.opacity(presentationViewModel.shouldShowOptionalFeaturesBar ? 1 : .zero)

            if let idx = self.applicationViewModel.userChatrooms[currentChatroomid] {
                SideMenu(isShowing: $presentationViewModel.shouldShowChatroomInfoCover,
                    isPresentSidemenu: $isPresentSidemenu,
                    sideMenuOffset: $sidemenuoffset,
                    chatlog: $applicationViewModel.userChatrooms[idx].log,
                    chatroomTitle: $chatroomTitle,
                    ChatroomType: applicationViewModel.userChatrooms[idx].roomtype,
                    chatroomid: currentChatroomid,
                    audienceList: applicationViewModel.userChatrooms[idx].audiencelist,
                    showFriendDetailView: { email in
                        chatlogViewModel.friendDetailViewTarget = email
                        presentationViewModel.shouldShowFriendDetailView = true
                    },
                    showFullScreenChatPhotoView: { chatid in
                        withAnimation(.spring(duration: 0.3)) {
                            presentationViewModel.shouldShowChatroomInfoCover = false
                            sidemenuoffset = UIScreen.main.bounds.width * 0.9
                        } completion: { isPresentSidemenu = false }
                        self.fullScreenPhotoId = chatid
                        withAnimation(.easeInOut(duration: 0.3)) {
                            presentationViewModel.shouldShowFullScreenPhotoView = true
                        }
                    }).zIndex(999)
            }

            VStack(alignment: .center) {
                Spacer()
                chatBottomBar
            }
        }.alert(isPresented: $messageSendingViewModel.shouldShowAlert) {
            switch messageSendingViewModel.activeAlert {
            case .messageSendFail:
                return Alert(title: Text("message send fail"), message: Text("can not found this chatroom"))

            case .messageReport:
                let yes = Alert.Button.destructive(Text("report")) {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        injected.interactorContainer.messageInteractor.reportMessage(
                            email: email,
                            roomid: currentChatroomid,
                            chatid: chatlogViewModel.reportedChatid,
                            activeAlert: $messageSendingViewModel.activeAlert,
                            chatrooms: $applicationViewModel.userChatrooms,
                            completeAlert: $messageSendingViewModel.shouldShowAlert)
                            .store(in: &subscriptions)
                    }
                }
                let no = Alert.Button.cancel(Text("cancel"))
                return Alert(title: Text("Report"), message: Text("Do you want to declare that content?\nIf you report, users who review the content and create the content within 24 hours may be restricted from using the service."),
                    primaryButton: no, secondaryButton: yes)

            case .messageReportComplete:
                return Alert(
                    title: Text("Report"),
                    message: Text("We have received your report.\nWe will review it promptly and take appropriate action as soon as possible.\nThank you."))

            case .permissionRequest:
                return Alert(title: Text("Permission required"),
                    message: Text("Please allow microphone and camera permissions in in-app settings"))
            }
        }
            .overlay { presentationViewModel.shouldShowReadNotificationSettingView ? readNotificationView : nil }
            .overlay { messageSendingViewModel.shouldShowWhisperMemberListView ? whisperMemberListView : nil }
            .overlay { messageSendingViewModel.shouldShowDidSendVideoFullScreenView ?
            VideoMessageSendingView(videoConvertState: videoConvertState, roomid: currentChatroomid).environmentObject(messageSendingViewModel): nil }
            .overlay { messageSendingViewModel.shouldShowDidSendPhotoFullScreenView ?
            PhotoMessageSendingView(shouldShowDidSendPhotoFullScreenView: $messageSendingViewModel.shouldShowDidSendPhotoFullScreenView,
                messagePickerUIImage: $messageSendingViewModel.messagePickerUIImage,
                messagePhotosPickerItem: $messageSendingViewModel.messagePhotosPickerItem,
                currentChatroomid: currentChatroomid,
                sendPhotoMessage: {
                    if let email: String = UserDefaultsKeys.userEmail.value(), let photo = messageSendingViewModel.messagePickerUIImage {
                        if let data = photo.jpegData(compressionQuality: 1.0) {
                            injected.interactorContainer.messageInteractor.sendPhotoMessage(
                                sender: email, roomid: currentChatroomid, photoData: data,
                                chatrooms: $applicationViewModel.userChatrooms,
                                vm: messageSendingViewModel
                            ).store(in: &applicationViewModel.cancellableSet)
                        }
                    }
                }): nil }
            .overlay(presentationViewModel.shouldShowFullScreenPhotoView ?
            FullScreenChatPhotoView(shouldShowFullScreenPhotoView: $presentationViewModel.shouldShowFullScreenPhotoView,
                imagePath: fullScreenPhotoId, currentChatroomid: currentChatroomid, reactions: $chatReactions): nil)
            .overlay(presentationViewModel.shouldShowFullScreenVideoView ?
            VideoChatView(fullScreenVideoId: fullScreenVideoId!,
                shouldShowFullScreenVideoView: $presentationViewModel.shouldShowFullScreenVideoView,
                reactions: $chatReactions, currentChatroomid: currentChatroomid): nil)
            .background(background)
            .navigationBarHidden(presentationViewModel.shouldShowFullScreenPhotoView || presentationViewModel.shouldShowFullScreenVideoView)
            .task { injected.interactorContainer.messageInteractor.getReactions(roomid: currentChatroomid, reactionsModel: $chatReactions).store(in: &subscriptions) }
            .onChange(of: messageSendingViewModel.scrollDownToggle) { _, _ in scrollDownUntilMostBottom?() }
    }

    @ViewBuilder
    private var background: some View {
        ZStack {
            GeometryReader { geo in
                VStack(alignment: .center) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation background start" : "Gradation chatlog background start dark"), Color(appSettingModel.appTheme ? "Gradation background end" : "Gradation chatlog background end dark")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: geo.size.width, height: geo.size.height)
                }.ignoresSafeArea(edges: .top)
            }.opacity(successToLoadChatroomBackgroundPhoto ? 0 : 1.0)

            if refreshChatroomBackgroundPhoto {
                GeometryReader { geo in
                    VStack(alignment: .center) {
                        WebImage(url: URL(string: "chatroomBackground\(currentChatroomid)"), options: [.fromCacheOnly])
                            .onSuccess { _, _, _ in
                            successToLoadChatroomBackgroundPhoto = true }
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: UIScreen.main.bounds.height)
                            .clipped()
                            .onReceive(NotificationCenter.default.publisher(for: .updatedChatroomBackgroundPhoto)) { notification in
                            refreshChatroomBackgroundPhoto = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation { refreshChatroomBackgroundPhoto = true }
                            }
                        }
                    }.ignoresSafeArea(.all)
                }
            }
        }.ignoresSafeArea(.all)
    }

    @ViewBuilder
    private var whisperMemberListView: some View {
        ZStack {
            Color.black.opacity(0.7)
                .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    messageSendingViewModel.shouldShowWhisperMemberListView = false
                }
            }
            VStack {
                HStack(alignment: .center) {
                    Text("Whisper Message")
                        .bold()
                        .font(.title3)
                    Spacer()
                }
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 10) {
                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            if let idx = applicationViewModel.userChatrooms[currentChatroomid] {
                                ForEach(applicationViewModel.userChatrooms[idx].audiencelist.filter { $0 != email }, id: \.self) { member in
                                    Button {
                                        injected.interactorContainer.messageInteractor.sendWhisperMessage(
                                            email: email,
                                            receiver: member,
                                            roomid: currentChatroomid,
                                            detail: messageSendingViewModel.userInputText.trimmingCharacters(in: .whitespacesAndNewlines),
                                            chatrooms: $applicationViewModel.userChatrooms,
                                            wmt: $applicationViewModel.whisperMessageSender,
                                            vm: messageSendingViewModel
                                        ).store(in: &subscriptions)
                                        withAnimation(.spring(duration: 0.3)) {
                                            messageSendingViewModel.shouldShowWhisperMemberListView = false
                                        }
                                    } label: {
                                        HStack(alignment: .center) {
                                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(member)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 34, height: 34)
                                                .clipped()
                                                .cornerRadius(7)
                                                .modifier(RefreshableWebImageProfileModifier(member, false))
                                            Text(applicationViewModel.getNickname(member))
                                                .foregroundStyle(Color("pastel orange foreground"))
                                            Spacer()
                                        }
                                            .frame(width: UIScreen.main.bounds.width * 0.4)
                                            .padding(10)
                                            .cornerRadius(10)
                                            .background { Color("pastel orange").opacity(0.6).cornerRadius(10) }
                                    }
                                }
                            }
                        }
                    }
                }.frame(maxHeight: 300)
            }
                .fixedSize(horizontal: true, vertical: true)
                .padding()
                .cornerRadius(10)
                .background { Color.white.cornerRadius(10) }
        }.ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private var readNotificationView: some View {
        ZStack {
            Color.black.opacity(0.7)
                .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    presentationViewModel.shouldShowReadNotificationSettingView = false
                }
            }
            VStack {
                switch chatlogViewModel.readNotificationSetableMemberList {
                case .notRequested:
                    if let roomidx = applicationViewModel.userChatrooms[currentChatroomid] {
                        if let log = applicationViewModel.userChatrooms[roomidx].log.first(where: { $0.id == chatlogViewModel.setReadNotificationChatId }) {
                            if let chatlog = log as? UserChatLog {
                                if chatlog.isSetReadNotification {
                                    HStack(alignment: .center) {
                                        Text("Read Notification")
                                            .bold()
                                            .font(.title3)
                                        Spacer()
                                    }
                                    VStack(alignment: .center, spacing: 10) {
                                        Image(systemName: "bell.slash")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .foregroundStyle(Color("pastel yellow foreground"))
                                            .opacity(0.5)
                                        Text("remove this read notification?")
                                            .font(.title3)
                                            .foregroundStyle(Color("pastel red foreground"))
                                    }
                                    HStack(alignment: .center) {
                                        Spacer()
                                        Button {
                                            if let me: String = UserDefaultsKeys.userEmail.value() {
                                                injected.interactorContainer.messageInteractor.setReadNotification(
                                                    email: me,
                                                    roomid: currentChatroomid,
                                                    chatid: chatlogViewModel.setReadNotificationChatId,
                                                    audienceList: [],
                                                    chatrooms: $applicationViewModel.userChatrooms,
                                                    activeBell: chatlogViewModel.bell!,
                                                    isPresented: $presentationViewModel.shouldShowReadNotificationSettingView)
                                                    .store(in: &subscriptions)
                                            }
                                        } label: {
                                            HStack(alignment: .center) {
                                                Text("remove")
                                                    .foregroundStyle(Color("pastel red foreground"))
                                            }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal)
                                                .cornerRadius(8)
                                                .background { RoundedRectangle(cornerRadius: 8).foregroundStyle(Color("pastel red")) }
                                        }
                                        Spacer()
                                    }
                                } else {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text("")
                                                .onAppear {
                                                if let me: String = UserDefaultsKeys.userEmail.value() {
                                                    injected.interactorContainer.messageInteractor.getReadNotificatinMemberList(
                                                        email: me, roomid: currentChatroomid, chatid: chatlogViewModel.setReadNotificationChatId, list: $chatlogViewModel.readNotificationSetableMemberList)
                                                }
                                            }
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                case .isLoading:
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(2)
                                .tint(.gray)
                            Spacer()
                        }
                        Spacer()
                    }
                case let .loaded(list):
                    if list.isEmpty {
                        HStack(alignment: .center) {
                            Text("Read Notification")
                                .bold()
                                .font(.title3)
                            Spacer()
                        }
                        VStack(alignment: .center, spacing: 10) {
                            Image(systemName: "checkmark.bubble")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .foregroundStyle(Color("pastel green foreground"))
                                .opacity(0.5)
                            Text("Message read by all members")
                                .font(.title3)
                                .foregroundStyle(Color("pastel gray foreground"))
                        }
                    } else {
                        HStack(alignment: .center) {
                            Text("Read Notification")
                                .bold()
                                .font(.title3)
                            Spacer()
                        }
                        HStack(alignment: .center, spacing: 3) {
                            if chatlogViewModel.setReadNotificationList.isEmpty {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(.gray, lineWidth: 1)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "checkmark.square")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundStyle(.green)
                            }
                            Text("all")
                                .font(.system(size: 13))
                            Spacer()
                        }
                            .padding(.top, 12)
                            .onTapGesture {
                            if chatlogViewModel.setReadNotificationList.isEmpty {
                                list.forEach { chatlogViewModel.setReadNotificationList.append($0.email) }
                            } else {
                                chatlogViewModel.setReadNotificationList = []
                            }
                        }
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 10) {
                                ForEach(list, id: \.self) { member in
                                    Button {
                                        withAnimation(.spring(duration: 0.3)) {
                                            if let idx = chatlogViewModel.setReadNotificationList.firstIndex(where: { $0 == member.email }) {
                                                chatlogViewModel.setReadNotificationList.remove(at: idx)
                                            } else {
                                                chatlogViewModel.setReadNotificationList.append(member.email)
                                            }
                                        }
                                    } label: {
                                        HStack(alignment: .center) {
                                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(member.email)"), options: [.fromCacheOnly])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 34, height: 34)
                                                .clipped()
                                                .cornerRadius(7)
                                                .modifier(RefreshableWebImageProfileModifier(member.email, false))
                                            Text(applicationViewModel.getNickname(member.email))
                                                .foregroundStyle(chatlogViewModel.setReadNotificationList.contains(member.email) ?
                                                Color("pastel blue foreground"): Color("pastel gray foreground"))
                                            Spacer()
                                            if chatlogViewModel.setReadNotificationList.contains(member.email) {
                                                Image(systemName: "bell.circle")
                                                    .resizable()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundStyle(Color("pastel blue foreground"))
                                            }
                                        }
                                            .frame(width: UIScreen.main.bounds.width * 0.5)
                                            .padding(10)
                                            .cornerRadius(10)
                                            .background { Color.gray.opacity(0.2).cornerRadius(10) }
                                    }
                                }
                            }
                        }.frame(maxHeight: 300)

                        HStack(alignment: .center) {
                            Spacer()
                            Button {
                                if let me: String = UserDefaultsKeys.userEmail.value() {
                                    injected.interactorContainer.messageInteractor.setReadNotification(
                                        email: me, roomid: currentChatroomid, chatid: chatlogViewModel.setReadNotificationChatId,
                                        audienceList: chatlogViewModel.setReadNotificationList,
                                        chatrooms: $applicationViewModel.userChatrooms, activeBell: chatlogViewModel.bell!, isPresented: $presentationViewModel.shouldShowReadNotificationSettingView)
                                        .store(in: &subscriptions)
                                }
                            } label: {
                                HStack(alignment: .center) {
                                    Text("done")
                                        .foregroundStyle(Color(chatlogViewModel.setReadNotificationList.isEmpty ? "pastel gray foreground" : "pastel blue foreground"))
                                }
                                    .frame(width: UIScreen.main.bounds.width * 0.2)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .cornerRadius(8)
                                    .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(Color(chatlogViewModel.setReadNotificationList.isEmpty ? "pastel gray" : "pastel blue"))
                                }
                            }.disabled(chatlogViewModel.setReadNotificationList.isEmpty)
                            Spacer()
                        }
                    }
                case .failed:
                    Text("load fail")
                }
            }
                .fixedSize(horizontal: true, vertical: true)
                .padding()
                .cornerRadius(10)
                .background { Color.white.cornerRadius(10) }
        }.ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private var messageView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 5) {
                    HStack { Spacer() }
                        .frame(height: screenHeight * 0.03 + bottomSafeareaHeight)
                        .background {
                        GeometryReader { bottomChatGeo in
                            Color.clear // <- red.opacity(0.5) 바꾸면 빨간바
                            .onAppear { lastMessageGeometryProxy = bottomChatGeo }
                                .onChange(of: bottomChatGeo.frame(in: .global).minY) { _, mostBottomChatMinY in
                                if presentationViewModel.shouldShowNewMessageButton && mostBottomChatMinY < screenHeight - keyboardResponder.currentHeight {
                                    withAnimation(.spring(duration: 0.3)) { presentationViewModel.shouldShowNewMessageButton = false }
                                }
                            }
                        }
                    }.id("MostBottom")

                    if let roomidx = applicationViewModel.userChatrooms[currentChatroomid] {
                        let chatLogs = applicationViewModel.userChatrooms[roomidx].log

                        ForEach(renderChatLog(chatLogs), id: \.self) { idx in
                            ChatMessageView(
                                reactions: $chatReactions,
                                showFriendDetailView: { email in
                                    chatlogViewModel.friendDetailViewTarget = email
                                    presentationViewModel.shouldShowFriendDetailView = true
                                },
                                showReportAlert: { chatid in
                                    chatlogViewModel.reportedChatid = chatid
                                    messageSendingViewModel.activeAlert = .messageReport
                                    messageSendingViewModel.shouldShowAlert = true
                                },
                                showFullScreenPhoto: { chatid in
                                    isFocused = false
                                    fullScreenPhotoId = chatid
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        presentationViewModel.shouldShowFullScreenPhotoView = true
                                    }
                                },
                                showFullScreenVideo: { chatid in
                                    isFocused = false
                                    fullScreenVideoId = chatid
                                    if chatReactions.reactionTable[chatid] == nil {
                                        chatReactions.reactionTable[chatid] = []
                                    }
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        presentationViewModel.shouldShowFullScreenVideoView = true
                                    }
                                },
                                setReadNotification: { email, chatid, bell in
                                    chatlogViewModel.setReadNotificationChatId = chatid
                                    chatlogViewModel.bell = bell
                                    chatlogViewModel.readNotificationSetableMemberList = .notRequested
                                    chatlogViewModel.setReadNotificationList = []
                                    withAnimation(.spring(duration: 0.3)) {
                                        presentationViewModel.shouldShowReadNotificationSettingView = true
                                    }
                                },
                                log: chatLogs[idx], chatroomid: currentChatroomid,
                                prevLog: chatLogs[max(0, idx - 1)], chatroomType: applicationViewModel.userChatrooms[roomidx].roomtype)
                                .rotationEffect(.degrees(180))
                                .zIndex(chatLogs[idx].id == selectedMessageIdForShowContextMenu ? 1 : .zero)
                        }.onAppear {
                            scrollDownUntilMostBottom = {
                                isDisabledScroll = true
                                withAnimation(.spring(duration: 0.3)) {
                                    scrollViewProxy.scrollTo("MostBottom", anchor: .bottom)
                                } completion: { isDisabledScroll = false }
                            }
                            scrollDownUntilMostBottom?()
                        }.onReceive(NotificationCenter.default.publisher(for: .showContextMenu)) {
                            selectedMessageIdForShowContextMenu = $0.userInfo!["chatid"] as? String
                        }
                        LazyVStack { Color.clear.frame(height: 7).onAppear { renderingLimit += 30 } }
                    }
                }.scrollTargetLayout()
            }
                .scrollClipDisabled()
                .ignoresSafeArea(.container, edges: .bottom)
                .rotationEffect(.degrees(180))
                .scrollDisabled(isDisabledScroll)
        }
    }

    @ViewBuilder
    private var chatBottomBar: some View {
        if presentationViewModel.shouldShowNewMessageButton {
            HStack(alignment: .center) {
                Text("More messages below")
                    .foregroundColor(.white)
                    .font(.system(size: 15))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background { BackgroundDarkBlurView().cornerRadius(7) }
                    .onTapGesture {
                    presentationViewModel.shouldShowNewMessageButton = false
                    scrollDownUntilMostBottom?()
                }
            }
                .fixedSize(horizontal: true, vertical: true)
                .zIndex(99)
                .padding(.bottom, 10)
        }

        VStack(alignment: .center, spacing: 0) {
            VStack {
                HStack(alignment: .bottom, spacing: 8) {
                    Button {
                        isFocused = false
                        presentationViewModel.shouldShowMessageSendingPhotoPickerView = true
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .foregroundStyle(Color("pastel blue foreground"))
                            .frame(width: UIScreen.main.bounds.height * 0.1 * 0.4, height: UIScreen.main.bounds.height * 0.1 * 0.4)
                            .aspectRatio(contentMode: .fit)
                    }.onChange(of: messageSendingViewModel.messagePhotosPickerItem) { oldValue, newValue in
                        guard let newValue else { return }

                        if let mimetype = newValue.supportedContentTypes.first {
                            if mimetype.conforms(to: .image) {
                                print("conformed image")
                                Task {
                                    if let data = try await newValue.loadTransferable(type: Data.self) {
                                        if let uiimage = UIImage(data: data) {
                                            messageSendingViewModel.messagePickerUIImage = uiimage.fixedOrientation().clippingImage()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                withAnimation(.spring(duration: 0.3)) {
                                                    messageSendingViewModel.shouldShowDidSendPhotoFullScreenView = true
                                                }
                                            }
                                        } else {
                                            print("uiimage init nil")
                                        }
                                    }
                                }
                            } else if mimetype.conforms(to: .movie) {
                                print("conformed video")
                                videoConvertState = .loading(LocalizationString.videoConverting)
                                presentationViewModel.shouldShowMessageSendingPhotoPickerView = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        messageSendingViewModel.shouldShowDidSendVideoFullScreenView = true
                                    }
                                }
                                Task {
                                    do {
                                        if let movie = try await newValue.loadTransferable(type: Movie.self) {
                                            let convertedMp4Url = URL.documentsDirectory.appending(path: "convertedVideo.mp4")

                                            if FileManager.default.fileExists(atPath: convertedMp4Url.path()) {
                                                try FileManager.default.removeItem(at: convertedMp4Url)
                                            }

                                            self.convertVideoToMP4(inputURL: movie.url, outputURL: convertedMp4Url) { result in
                                                switch result {
                                                case let .success(url):
                                                    let videoData = try? Data(contentsOf: url)
                                                    if let videoData {
                                                        if videoData.count > 200000000 {
                                                            messageSendingViewModel.videoSendingViewAlert = .tooBiggerSizeVideo
                                                            messageSendingViewModel.shouldShowVideoSendingViewAlert = true
                                                        } else {
                                                            videoConvertState = .loading(LocalizationString.thumbnailCreating)
                                                            AVAsset(url: url).generateThumbnail { image in
                                                                DispatchQueue.main.async {
                                                                    if let thumbnail = image {
                                                                        if let thumbnailData = thumbnail.jpegData(compressionQuality: 1.0) {
                                                                            self.messageSendingViewModel.messageVideoThumbnailData = thumbnailData
                                                                            self.messageSendingViewModel.messageVideoData = videoData
                                                                            videoConvertState = .loaded(Movie(url: url))
                                                                        } else {
                                                                            messageSendingViewModel.videoSendingViewAlert = .videoConvertingError
                                                                            messageSendingViewModel.shouldShowVideoSendingViewAlert = true
                                                                        }
                                                                    } else {
                                                                        messageSendingViewModel.videoSendingViewAlert = .videoConvertingError
                                                                        messageSendingViewModel.shouldShowVideoSendingViewAlert = true
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        messageSendingViewModel.videoSendingViewAlert = .videoConvertingError
                                                        messageSendingViewModel.shouldShowVideoSendingViewAlert = true
                                                    }
                                                    print("success : \(url)")
                                                case let .failure(error):
                                                    messageSendingViewModel.videoSendingViewAlert = .unsupportedVideoFormat
                                                    messageSendingViewModel.shouldShowVideoSendingViewAlert = true
                                                    print("fail : \(error.localizedDescription)")
                                                }
                                            }
                                        } else {
                                            videoConvertState = .failed
                                        }
                                    } catch {
                                        videoConvertState = .failed
                                    }
                                }
                            } else {
                                print("is notting")
                            }
                        }
                    }

                    TextField("٩(●'▿'●)۶ *", text: $messageSendingViewModel.userInputText, axis: .vertical)
                        .font(.system(size: 17))
                        .fontDesign(.rounded)
                        .focused($isFocused)
                        .limitInputLength(value: $messageSendingViewModel.userInputText, length: 512)
                        .multilineTextAlignment(.leading)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .lineLimit(5)
                        .frame(minHeight: UIScreen.main.bounds.height * 0.1 * 0.4)
                        .padding(.horizontal, 8)
                        .background {
                        Rectangle()
                            .cornerRadius(7)
                            .shadow(radius: 1)
                            .foregroundStyle(.white)
                    }

                    ZStack {
                        Button {
                            if messageSendingViewModel.userInputText != "" {
                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                    injected.interactorContainer.messageInteractor.sendMessage(
                                        sender: email,
                                        roomid: currentChatroomid,
                                        detail: messageSendingViewModel.userInputText.trimmingCharacters(in: .whitespacesAndNewlines),
                                        chatrooms: $applicationViewModel.userChatrooms,
                                        vm: messageSendingViewModel
                                    ).sink(receiveCompletion: { completion in
                                        switch completion {
                                        case .finished:
                                            print("sendMessage finished")
                                        case .failure(let error):
                                            print("error desc : \(error.errorDescription ?? "")")
                                        }
                                    }, receiveValue: { _ in })
                                        .store(in: &applicationViewModel.cancellableSet)
                                }
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Text("send")
                                    .foregroundStyle(Color(messageSendingViewModel.userInputText == "" ?
                                    "pastel gray foreground": "pastel blue foreground"))
                            }
                                .frame(width: UIScreen.main.bounds.width * 0.17, height: UIScreen.main.bounds.height * 0.1 * 0.4)
                                .background {
                                Rectangle()
                                    .foregroundColor(Color(messageSendingViewModel.userInputText == "" ? "pastel gray" : "pastel blue"))
                                    .cornerRadius(7)
                                    .shadow(radius: 1)
                            }
                        }
                            .opacity(chatlogViewModel.currentButtonInedx == 1 ? 1.0 : 0)
                            .scaleEffect(chatlogViewModel.currentButtonInedx == 1 ? 1.0 : 0.6)
                            .offset(y: CGFloat(1 - chatlogViewModel.currentButtonInedx) * UIScreen.main.bounds.height * 0.1 * 0.4)
                            .disabled(messageSendingViewModel.userInputText == "")

                        Button {
                            if !(messageSendingViewModel.userInputText == "") {
                                withAnimation(.spring(duration: 0.3)) {
                                    messageSendingViewModel.shouldShowWhisperMemberListView = true
                                }
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Text("whisper")
                                    .foregroundStyle(Color(messageSendingViewModel.userInputText == "" ?
                                    "pastel gray foreground": "pastel orange foreground"))
                            }
                                .frame(width: UIScreen.main.bounds.width * 0.17, height: UIScreen.main.bounds.height * 0.1 * 0.4)
                                .background {
                                Rectangle()
                                    .foregroundColor(Color(messageSendingViewModel.userInputText == "" ? "pastel gray" : "pastel orange"))
                                    .cornerRadius(7)
                                    .shadow(radius: 1)
                            }
                        }
                            .opacity(chatlogViewModel.currentButtonInedx == 2 ? 1.0 : 0)
                            .scaleEffect(chatlogViewModel.currentButtonInedx == 2 ? 1.0 : 0.6)
                            .offset(y: CGFloat(2 - chatlogViewModel.currentButtonInedx) * UIScreen.main.bounds.height * 0.1 * 0.4)
                            .disabled(messageSendingViewModel.userInputText == "")
                    }
                        .frame(height: UIScreen.main.bounds.height * 0.1 * 0.4)
                        .gesture(
                        DragGesture()
                            .onEnded({ value in
                            if let idx = self.applicationViewModel.userChatrooms[currentChatroomid] {
                                if applicationViewModel.userChatrooms[idx].roomtype == .group {
                                    let threshold: CGFloat = 20

                                    withAnimation(.spring(duration: 0.3)) {
                                        if value.translation.height > threshold {
                                            chatlogViewModel.currentButtonInedx = max(1, chatlogViewModel.currentButtonInedx - 1)
                                        } else if value.translation.height < -threshold {
                                            chatlogViewModel.currentButtonInedx = min(2, chatlogViewModel.currentButtonInedx + 1)
                                        }
                                    }
                                }
                            }
                        })
                    )
                }
                    .padding(.vertical, 0)
                    .padding(.horizontal, 7)
            }
                .padding(.vertical, 7.5)
                .background { BackgroundBlurView().cornerRadius(10).shadow(radius: 1) }
        }
            .padding(.horizontal, 9)
            .padding(.top, 0)
            .padding(.bottom, 8)
            .onChange(of: keyboardResponder.currentHeight) { _, _ in
            NotificationCenter.default.post(name: .hideContextMenu, object: nil, userInfo: nil)
        }
    }

    @ViewBuilder
    private var aiChatView: some View {
        GeometryReader { geo in
            Spacer()
            VStack {
                ZStack {
                    HStack {
                        Button(action: {
                            presentationViewModel.shouldShowAiChatView = false
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }.padding(7)
                                .background(.clear)
                        }
                        Spacer()
                    }.padding()
                    HStack {
                        Spacer()
                        Text("AI Chat")
                            .font(.title)
                            .appThemeForegroundColor(appSettingModel.appTheme)
                        Spacer()
                    }
                }

                VStack {
                    VStack(alignment: .center) {
                        Spacer()
                        HStack(alignment: .center) {
                            Spacer()
                            switch aiMessage {
                            case .notRequested:
                                Text("not Request")
                            case .isLoading:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(2)
                                    .tint(.black)
                            case let .loaded(res):
                                ScrollView {
                                    Text(res.aiResponse)
                                }
                            case .failed:
                                Text("fail")
                            }
                            Spacer()
                        }
                        Spacer()
                    }.background(Color.white.cornerRadius(15))
                        .padding()

                    HStack(alignment: .center, spacing: 10) {
                        TextField("", text: $aichatText, axis: .vertical)
                            .frame(minHeight: UIScreen.main.bounds.height * 0.1 * 0.4)
                            .padding(.horizontal, 8)
                            .lineLimit(5)
                            .background {
                            Rectangle()
                                .cornerRadius(7)
                                .shadow(radius: 1)
                                .foregroundStyle(.white)
                        }
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                injected.interactorContainer.messageInteractor.aiChatting(email: email, text: aichatText, aiChatresult: $aiMessage)
                                aichatText = ""
                            }
                        } label: {
                            Text("send")
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.pink.cornerRadius(10))
                        }.disabled(aichatText == "")
                    }.padding()
                }
            }
            Spacer()
        }
            .frame(width: UIScreen.main.bounds.width)
            .background {
            if appSettingModel.appTheme {
                BackgroundBlurView().frame(height: UIScreen.main.bounds.height + 120)
            } else {
                BackgroundDarkBlurView().frame(height: UIScreen.main.bounds.height + 120)
            }
        }.onAppear {
            aichatText = ""
        }
    }

    @ViewBuilder
    private var newuserInviteView: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .center) {
                    Button(action: {
                        presentationViewModel.shouldShowNewuserInviteView = false
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .contentShape(Rectangle())
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .padding()
                    }
                    Spacer()
                    Text("Invite")
                        .font(.title)
                        .appThemeForegroundColor(appSettingModel.appTheme)
                    Spacer()
                    Button(action: {
                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            injected.interactorContainer.chatroomInteractor.inviteUser(
                                email: email, audiences: chatlogViewModel.selectedUserList,
                                chatroomid: currentChatroomid, $applicationViewModel.userChatrooms,
                                $presentationViewModel.shouldShowNewuserInviteView)
                                .store(in: &subscriptions)
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .contentShape(Rectangle())
                            .foregroundStyle(chatlogViewModel.selectedUserList.isEmpty ? Color.gray.opacity(0.7) : Color("pastel green foreground"))
                            .padding()
                    }.disabled(chatlogViewModel.selectedUserList.isEmpty)
                }.padding()

                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(self.chatlogViewModel.selectedUserList, id: \.self) { su in
                                VStack(alignment: .center) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(su)"))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipped()
                                        .cornerRadius(19)
                                        .shadow(radius: 5)
                                    Text(applicationViewModel.getNickname(su))
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                        .font(.system(size: 10))
                                }
                                    .frame(maxWidth: 50)
                                    .onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) {
                                        if let idx = self.chatlogViewModel.selectedUserList.firstIndex(of: su) {
                                            self.chatlogViewModel.selectedUserList.remove(at: idx)
                                        }
                                    }
                                }
                            }
                        }.padding()
                    }
                    TextField(text: $chatlogViewModel.searchKeywordInput) {
                        Text("email")
                            .foregroundStyle(appSettingModel.appTheme ? .black.opacity(0.2) : .white.opacity(0.3)) }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.leading)
                        .frame(height: 40)
                        .padding(.leading, 5)
                        .padding(.bottom, 20)
                        .padding(.trailing, 15)
                        .textFieldStyle(LineTextfieldClearStyle())
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(keywordSearchResult(applicationViewModel.invitableFriendlist(currentChatroomid)), id: \.self) { friend in
                                HStack(alignment: .center, spacing: 22) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(friend.email)"))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 54, height: 54)
                                        .clipped()
                                        .cornerRadius(19)
                                        .shadow(radius: 5)
                                    VStack(alignment: .leading) {
                                        (friend.nickname ?? friend.email)
                                            .highlightingText(chatlogViewModel.searchKeywordInput, appSettingModel.appTheme)
                                        HStack(alignment: .center) {
                                            friend.email
                                                .highlightingEmailText(chatlogViewModel.searchKeywordInput, appSettingModel.appTheme)
                                                .foregroundStyle(appSettingModel.appTheme ? Color("pastel blue foreground") : Color("pastel yellow foreground"))
                                        }.padding(0)
                                            .cornerRadius(10)
                                            .if(appSettingModel.appTheme) { view in
                                            view
                                                .background {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .foregroundStyle(Color("pastel blue")) }
                                        }.if(!appSettingModel.appTheme) { view in
                                            view.overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color("pastel yellow foreground"), lineWidth: 1)
                                            )
                                        }
                                    }
                                    Spacer()
                                }
                                    .padding(.vertical, 9)
                                    .padding(.leading, 12)
                                    .background {
                                    Rectangle()
                                        .foregroundStyle(chatlogViewModel.selectedUserList.contains(friend.email) ?
                                        selectedFriendColor: unselectedFriendColor)
                                        .cornerRadius(10)
                                }.onTapGesture {
                                    withAnimation(.spring(duration: 0.3)) {
                                        if chatlogViewModel.selectedUserList.contains(friend.email) {
                                            let idx = chatlogViewModel.selectedUserList.firstIndex(of: friend.email)!
                                            chatlogViewModel.selectedUserList.remove(at: idx)
                                        } else {
                                            chatlogViewModel.selectedUserList.append(friend.email)
                                        }
                                    }
                                }
                            }
                        }.padding()
                    }
                }.onAppear {
                    self.chatlogViewModel.selectedUserList = []
                    self.chatlogViewModel.searchKeywordInput = ""
                }
            }
        }
            .ignoresSafeArea(.keyboard, edges: .all)
            .background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    private var chatroomProfileEditView: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .center) {
                    Button {
                        presentationViewModel.shouldShowChatroomEditView = false
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .contentShape(Rectangle())
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .padding()
                    }
                    Spacer()
                    Text("Chatroom Profile")
                        .font(.title)
                        .appThemeForegroundColor(appSettingModel.appTheme)
                    Spacer()
                    Button {
                        if chatroomTitleTextField != "" && chatroomTitleTextField != chatroomTitle {
                            injected.interactorContainer.chatroomInteractor.modifyChatroomTitle(
                                chatroomid: currentChatroomid,
                                newTitle: chatroomTitleTextField,
                                title: $chatroomTitle,
                                titleTable: $applicationViewModel.userChatroomTitles)
                                .store(in: &subscriptions)
                        }

                        if let selectedBackground = chatlogViewModel.chatroomBackgroundphotosUIImage {
                            injected.interactorContainer.chatroomInteractor.modifyChatroomBackgroundPhoto(
                                chatroomid: currentChatroomid, newPhoto: selectedBackground)
                        }

                        if let selectedPhoto = chatlogViewModel.chatroomProfilephotosUIImage {
                            injected.interactorContainer.chatroomInteractor.modifyChatroomProfilePhoto(
                                chatroomid: currentChatroomid, newPhoto: selectedPhoto)
                        }
                        presentationViewModel.shouldShowChatroomEditView = false
                    } label: {
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .contentShape(Rectangle())
                            .foregroundStyle((chatroomTitleTextField == "" || chatroomTitleTextField == chatroomTitle) && chatlogViewModel.chatroomProfilephotosUIImage == nil && chatlogViewModel.chatroomBackgroundphotosUIImage == nil ?
                            Color.gray.opacity(0.8): Color("pastel green foreground"))
                            .padding()
                    }.disabled((chatroomTitleTextField == "" || chatroomTitleTextField == chatroomTitle) && chatlogViewModel.chatroomProfilephotosUIImage == nil && chatlogViewModel.chatroomBackgroundphotosUIImage == nil)
                }.padding()

                VStack(alignment: .center, spacing: 10) {
                    HStack(alignment: .center) {
                        Spacer()
                        VStack(alignment: .center) {
                            Text("icon")
                                .font(.system(size: 17))
                                .fontDesign(.rounded)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            PhotosPicker(selection: $chatlogViewModel.chatroomProfilephotosPickerItem, matching: .images) {
                                ZStack (alignment: .center) {
                                    if let selectedUIImgae = chatlogViewModel.chatroomProfilephotosUIImage {
                                        Image(uiImage: selectedUIImgae)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ZStack {
                                            Color.white
                                            Image(systemName: "person.3")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 9)
                                                .opacity(successToLoadChatroomProfilePhoto ? 1.0 : 0)
                                        }
                                        WebImage(url: URL(string: "chatroomPhoto\(currentChatroomid)"), options: [.fromCacheOnly])
                                            .onSuccess { _, _, _ in
                                            successToLoadChatroomProfilePhoto = false
                                        }
                                            .resizable()
                                            .scaledToFill()
                                    }
                                }
                                    .frame(width: geo.size.width * 0.36, height: geo.size.width * 0.36)
                                    .cornerRadius(19)
                                    .shadow(radius: 2)
                                    .padding(.top, 8)
                            }
                        }
                        Spacer()
                        VStack(alignment: .center) {
                            Text("background")
                                .font(.system(size: 17))
                                .fontDesign(.rounded)
                                .appThemeForegroundColor(appSettingModel.appTheme)
                            ZStack (alignment: .center) {
                                if let selectedUIImgae = chatlogViewModel.chatroomBackgroundphotosUIImage {
                                    Image(uiImage: selectedUIImgae)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width * 0.36, height: geo.size.width * 0.36)
                                        .clipped()
                                        .cornerRadius(19)
                                        .shadow(radius: 1)
                                        .padding(.top, 8)
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(appSettingModel.appTheme ? "Gradation background start" : "Gradation chatlog background start dark"), Color(appSettingModel.appTheme ? "Gradation background end" : "Gradation chatlog background end dark")]),
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
                                        .frame(width: geo.size.width * 0.36, height: geo.size.width * 0.36)
                                        .clipped()
                                        .cornerRadius(19)
                                        .shadow(radius: 1)
                                        .padding(.top, 8)
                                        .opacity(successToLoadChatroomBackgroundPhoto ? 0 : 1.0)
                                    WebImage(url: URL(string: "chatroomBackground\(currentChatroomid)"), options: [.fromCacheOnly])
                                        .onSuccess { _, _, _ in
                                        successToLoadChatroomBackgroundPhoto = true }
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width * 0.36, height: geo.size.width * 0.36)
                                        .clipped()
                                        .cornerRadius(19)
                                        .shadow(radius: 1)
                                        .padding(.top, 8)
                                }
                            }
                                .onTapGesture {
                                presentationViewModel.shouldShowChatroomBackgroundActionSheet = true
                            }
                        }
                        Spacer()
                    }
                    TextField(text: $chatroomTitleTextField) {
                        Text(chatroomTitleTextField)
                    }.textFieldStyle(LineTextfieldClearStyle())
                    Spacer()
                }.onChange(of: chatlogViewModel.chatroomProfilephotosPickerItem) { _, newImage in
                    Task(priority: .high) {
                        if let data = try? await newImage?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                withAnimation { chatlogViewModel.chatroomProfilephotosUIImage = uiImage }
                            }
                        }
                    }
                }.onChange(of: chatlogViewModel.chatroomBackgroundphotosPickerItem) { _, newBackground in
                    Task(priority: .high) {
                        if let data = try? await newBackground?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                withAnimation { chatlogViewModel.chatroomBackgroundphotosUIImage = uiImage }
                            }
                        }
                    }
                }
                    .padding()
                    .onAppear {
                    chatlogViewModel.chatroomProfilephotosUIImage = nil
                    chatlogViewModel.chatroomProfilephotosPickerItem = nil

                    chatlogViewModel.chatroomBackgroundphotosUIImage = nil
                    chatlogViewModel.chatroomBackgroundphotosPickerItem = nil
                    chatroomTitleTextField = chatroomTitle
                }
                Spacer()
            }
        }
            .ignoresSafeArea(.keyboard, edges: .all)
            .photosPicker(isPresented: $presentationViewModel.shouldShowChatroomBackgroundPhotoPickerView,
            selection: $chatlogViewModel.chatroomBackgroundphotosPickerItem, matching: .images)
            .confirmationDialog("", isPresented: $presentationViewModel.shouldShowChatroomBackgroundActionSheet, titleVisibility: .hidden) {
            Button("Default Photos") {
                presentationViewModel.shouldShowBuiltInBackgroundPhotoSelectionView = true
            }

            Button("Your Gallery") {
                presentationViewModel.shouldShowChatroomBackgroundPhotoPickerView = true
            }
        }.sheet(isPresented: $presentationViewModel.shouldShowBuiltInBackgroundPhotoSelectionView) {
            builtInBackgroundPhotoSelectionView
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
        }.background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    private var builtInBackgroundPhotoSelectionView: some View {
        GeometryReader { geo in
            VStack {
                HStack {
                    Button {
                        presentationViewModel.shouldShowBuiltInBackgroundPhotoSelectionView = false
                    } label: {
                        Text("cancel")
                            .font(.system(.title2))
                            .padding()
                    }
                    Spacer()
                    Button {
                        if let selectedBuiltInBackgroundPhotoName {
                            if let builtinUIImgae = UIImage(named: selectedBuiltInBackgroundPhotoName) {
                                chatlogViewModel.chatroomBackgroundphotosUIImage = builtinUIImgae
                                presentationViewModel.shouldShowBuiltInBackgroundPhotoSelectionView = false
                            } else {
                                // if secret photo
                                SDWebImageManager.shared.loadImage(with: URL(string: selectedBuiltInBackgroundPhotoName),
                                    options: [], progress: nil) { (image, data, error, cacheType, finished, imageURL) in
                                    if let image {
                                        chatlogViewModel.chatroomBackgroundphotosUIImage = image
                                        presentationViewModel.shouldShowBuiltInBackgroundPhotoSelectionView = false
                                    } else {
                                        if let err = error {
                                            debugPrint("can not load image : \(err.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("Done")
                            .font(.system(.title2))
                            .padding()
                    }.disabled(selectedBuiltInBackgroundPhotoName == nil)
                }.padding()

                ScrollView(showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack {
                            ForEach(Array(stride(from: 0, to: built_in_BackgroundPhotoNames.count, by: 3)), id: \.self) { idx in
                                if built_in_BackgroundPhotoNames[idx].contains(serverUrl) {
                                    WebImage(url: URL(string: built_in_BackgroundPhotoNames[idx]))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width * 0.3)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                        selectedBuiltInBackgroundPhotoName = built_in_BackgroundPhotoNames[idx]
                                    }.overlay(selectedBuiltInBackgroundPhotoName == built_in_BackgroundPhotoNames[idx] ?
                                        ZStack(alignment: .center) {
                                            Color.black.opacity(0.4)
                                                .cornerRadius(10)
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .foregroundStyle(.green)
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width * 0.15)
                                        }.onTapGesture { selectedBuiltInBackgroundPhotoName = nil }: nil
                                    )
                                } else {
                                    Image(built_in_BackgroundPhotoNames[idx])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width * 0.3)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                        selectedBuiltInBackgroundPhotoName = built_in_BackgroundPhotoNames[idx]
                                    }.overlay(selectedBuiltInBackgroundPhotoName == built_in_BackgroundPhotoNames[idx] ?
                                        ZStack(alignment: .center) {
                                            Color.black.opacity(0.4)
                                                .cornerRadius(10)
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .foregroundStyle(.green)
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width * 0.15)
                                        }.onTapGesture { selectedBuiltInBackgroundPhotoName = nil }: nil
                                    )
                                }
                            }
                        }
                        VStack {
                            ForEach(Array(stride(from: 1, to: built_in_BackgroundPhotoNames.count, by: 3)), id: \.self) { idx in
                                if built_in_BackgroundPhotoNames[idx].contains(serverUrl) {
                                    WebImage(url: URL(string: built_in_BackgroundPhotoNames[idx]))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width * 0.3)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                        selectedBuiltInBackgroundPhotoName = built_in_BackgroundPhotoNames[idx]
                                    }.overlay(selectedBuiltInBackgroundPhotoName == built_in_BackgroundPhotoNames[idx] ?
                                        ZStack(alignment: .center) {
                                            Color.black.opacity(0.4)
                                                .cornerRadius(10)
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .foregroundStyle(.green)
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width * 0.15)
                                        }.onTapGesture { selectedBuiltInBackgroundPhotoName = nil }: nil
                                    )
                                } else {
                                    Image(built_in_BackgroundPhotoNames[idx])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width * 0.3)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                        selectedBuiltInBackgroundPhotoName = built_in_BackgroundPhotoNames[idx]
                                    }.overlay(selectedBuiltInBackgroundPhotoName == built_in_BackgroundPhotoNames[idx] ?
                                        ZStack(alignment: .center) {
                                            Color.black.opacity(0.4)
                                                .cornerRadius(10)
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .foregroundStyle(.green)
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width * 0.15)
                                        }.onTapGesture { selectedBuiltInBackgroundPhotoName = nil }: nil
                                    )
                                }
                            }
                        }
                        VStack {
                            ForEach(Array(stride(from: 2, to: built_in_BackgroundPhotoNames.count, by: 3)), id: \.self) { idx in
                                if built_in_BackgroundPhotoNames[idx].contains(serverUrl) {
                                    WebImage(url: URL(string: built_in_BackgroundPhotoNames[idx]))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width * 0.3)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                        selectedBuiltInBackgroundPhotoName = built_in_BackgroundPhotoNames[idx]
                                    }.overlay(selectedBuiltInBackgroundPhotoName == built_in_BackgroundPhotoNames[idx] ?
                                        ZStack(alignment: .center) {
                                            Color.black.opacity(0.4)
                                                .cornerRadius(10)
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .foregroundStyle(.green)
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width * 0.15)
                                        }.onTapGesture { selectedBuiltInBackgroundPhotoName = nil }: nil
                                    )
                                } else {
                                    Image(built_in_BackgroundPhotoNames[idx])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width * 0.3)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                        selectedBuiltInBackgroundPhotoName = built_in_BackgroundPhotoNames[idx]
                                    }.overlay(selectedBuiltInBackgroundPhotoName == built_in_BackgroundPhotoNames[idx] ?
                                        ZStack(alignment: .center) {
                                            Color.black.opacity(0.4)
                                                .cornerRadius(10)
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .foregroundStyle(.green)
                                                .scaledToFit()
                                                .frame(width: UIScreen.main.bounds.width * 0.15)
                                        }.onTapGesture { selectedBuiltInBackgroundPhotoName = nil }: nil
                                    )
                                }
                            }
                        }
                    }
                }
            }
                .frame(width: geo.size.width)
                .onAppear {
                selectedBuiltInBackgroundPhotoName = nil
                if sc.isActivedCommand(.background, .hutao) {
                    if !built_in_BackgroundPhotoNames.contains("\(serverUrl)/sec/background/hutao_1") {
                        built_in_BackgroundPhotoNames.append(contentsOf: [
                            "\(serverUrl)/sec/background/hutao_1",
                            "\(serverUrl)/sec/background/hutao_2",
                            "\(serverUrl)/sec/background/hutao_3",
                            "\(serverUrl)/sec/background/hutao_4",
                            "\(serverUrl)/sec/background/hutao_5"
                            ]
                        )
                    }
                }
            }
        }.background(appSettingModel.appTheme ? Color("Sidemenu background light") : Color("Sidemenu background dark"))
    }

    private func renderChatLog(_ logs: [any Logable]) -> [Int] {
        var result: [Int] = []
        var limit = 0

        for idx in logs.indices.reversed() {
            if [.text, .whisper, .blocked].contains(logs[idx].logType) {
                limit += 1
            } else if [.video, .photo].contains(logs[idx].logType) {
                limit += 4
            }

            if renderingLimit >= limit {
                result.append(idx)
            } else {
                return result
            }
        }
        return result
    }

    private func convertVideoToMP4(inputURL: URL, outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "AVAssetExportSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create AVAssetExportSession"])))
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            case .failed:
                if let error = exportSession.error {
                    completion(.failure(error))
                }
            case .cancelled:
                completion(.failure(NSError(domain: "AVAssetExportSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"])))
            default:
                break
            }
        }
    }

    private func keywordSearchResult(_ friendList: [UserFriend]) -> [UserFriend] {
        if chatlogViewModel.searchKeywordInput == "" {
            return friendList
        } else {
            return friendList.filter {
                $0.email.contains(chatlogViewModel.searchKeywordInput) || $0.nickname?.contains(chatlogViewModel.searchKeywordInput) ?? false
            }
        }
    }
}

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

enum VideoConvertState { case unknown, loading(String), loaded(Movie), failed }
