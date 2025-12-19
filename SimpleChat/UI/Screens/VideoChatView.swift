import SwiftUI
import AVKit
import SDWebImageSwiftUI
import Photos
import AVFoundation

enum VideoChatViewAlert {
    case deleteVideoAlert
    case photosPermissionAlert
}

struct VideoChatView: View {

    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @Environment(\.injected) private var injected: DIContainer

    @State var videoMessage: Loadable<URL> = .notRequested
    @State var videoDegree: CGFloat = .zero
    @State private var isPlaying: Bool = false
    @State private var player: AVPlayer?
    @State private var showPlayerControls: Bool = false
    @State private var videoUpScale: CGFloat = 1.0
    @State private var videoViewSize = CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width / 16) * 9)
    @State private var videoViewYOffset: CGFloat = .zero
    @State private var videoCurrentTime: Double = .zero
    @State private var isEditingSlider = false

    @State private var leftDisappearFastWind: DispatchWorkItem?
    @State private var rightDisappearFastWind: DispatchWorkItem?

    @State private var leftTapFastWind = false
    @State private var rightTapFastWind = false

    @State var fullScreenVideoId: String
    @State private var acitveFastWindArrowAnimation = false

    @Binding var shouldShowFullScreenVideoView: Bool
    @State var shouldShowDownloadView = false
    @State var shouldShowReportVideoView = false

    @State private var leftFastWindSeconds: Int = 3
    @State private var rightFastWindSeconds: Int = 3

    @State private var timestampFormat: Bool = false

    @State private var tappedLocation: CGPoint = .zero

    @State private var selfOffset: CGFloat = .zero
    @State private var activeAlert: VideoChatViewAlert = .deleteVideoAlert
    @State private var shouldShowAlert = false

    @State private var isActiveLeftFastWindView = false
    @State private var isActiveRightFastWindView = false

    @State private var isCompleteVideoDownload = false
    @State private var videoDownloadCompleteCheckImageAnimation = false
    @State private var taskStatus: TaskStatus = .notRequested

    @Binding var reactions: MessageReactions

    @State private var shouldShowReactionList = false
    @State private var isPresentReactionMenu = false
    @State private var myReaction: Reaction?

    let currentChatroomid: String

    var body: some View {
        ZStack {
            Color.black
            VStack {
                if videoDegree != .zero { Spacer() }
                videoView
                if videoDegree == .zero {
                    if let roomidx = applicationViewModel.userChatrooms[currentChatroomid] {
                        if let logidx = applicationViewModel.userChatrooms[roomidx].log.firstIndex(where: { $0.id == fullScreenVideoId }) {
                            if let log = applicationViewModel.userChatrooms[roomidx].log[logidx] as? UserChatLog {
                                ScrollView(.vertical, showsIndicators: false) {
                                    VStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(log.detail == "No Title Video" ? LocalizationString.noTitleVideo : log.detail)
                                                .font(.title)
                                                .lineSpacing(0)
                                                .bold()
                                                .lineLimit(3)
                                                .foregroundStyle(.white)
                                            HStack(alignment: .center) {
                                                if timestampFormat {
                                                    Text(log.timestamp.dateToString())
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(.white)
                                                } else {
                                                    Text("\(log.showableTimestamp) ago")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(.white)
                                                }
                                                Spacer()
                                            }
                                        }
                                            .padding(.horizontal)
                                            .padding(.vertical, 7)
                                            .onTapGesture { timestampFormat.toggle() }

                                        HStack(alignment: .center, spacing: 15) {
                                            Circle()
                                                .foregroundStyle(.white)
                                                .frame(width: 55, height: 55)
                                                .overlay {
                                                ZStack(alignment: .center) {
                                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(log.writer)"), options: [.refreshCached])
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 52, height: 52)
                                                        .cornerRadius(52)
                                                }.padding(0)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(applicationViewModel.getNickname(log.writer))
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.white)
                                                    .padding(.leading, 3)

                                                Text(log.writer)
                                                    .padding(.vertical, 3)
                                                    .padding(.horizontal, 6)
                                                    .cornerRadius(20)
                                                    .font(.system(size: 11))
                                                    .background {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .foregroundStyle(Color("pastel blue"))
                                                }
                                            }
                                            Spacer()
                                        }
                                            .padding(.horizontal)
                                            .padding(.vertical, 7)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(alignment: .top, spacing: 10) {
                                                VStack {
                                                    HStack(alignment: .center, spacing: 6) {
                                                        Button {
                                                            withAnimation(.spring(duration: 0.3)) {
                                                                isPresentReactionMenu.toggle()
                                                            }
                                                        } label: {
                                                            Image(systemName: "heart.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 15)
                                                                .foregroundStyle(
                                                                [.read, .good, .happy, .question].contains(myReaction?.reaction ?? .undefined) ? .red : .white)
                                                                .padding(.vertical, 3)
                                                                .padding(.leading, 6)
                                                        }

                                                        if isPresentReactionMenu {
                                                            Button {
                                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                                    injected.interactorContainer.messageInteractor.setReaction(
                                                                        roomid: currentChatroomid, chatid: fullScreenVideoId,
                                                                        reaction: Reaction(email: email,
                                                                            reaction: myReaction?.reaction == .question ? .cancel : .question, timestamp: Date()),
                                                                        taskStatus: $taskStatus, reactions: $reactions)
                                                                        .store(in: &applicationViewModel.cancellableSet)
                                                                    withAnimation(.spring(duration: 0.3)) {
                                                                        isPresentReactionMenu = false
                                                                    }
                                                                }
                                                            } label: {
                                                                Image(systemName: "questionmark.circle")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(height: 15)
                                                                    .foregroundStyle(myReaction?.reaction == .question ? .yellow : .white)
                                                                    .padding(.horizontal, 6)
                                                            }.disabled(taskStatus == .processing)

                                                            Button {
                                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                                    injected.interactorContainer.messageInteractor.setReaction(
                                                                        roomid: currentChatroomid, chatid: fullScreenVideoId,
                                                                        reaction: Reaction(email: email,
                                                                            reaction: myReaction?.reaction == .happy ? .cancel : .happy, timestamp: Date()),
                                                                        taskStatus: $taskStatus, reactions: $reactions)
                                                                        .store(in: &applicationViewModel.cancellableSet)
                                                                    withAnimation(.spring(duration: 0.3)) {
                                                                        isPresentReactionMenu = false
                                                                    }
                                                                }
                                                            } label: {
                                                                Image(systemName: "face.smiling")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(height: 15)
                                                                    .foregroundStyle(myReaction?.reaction == .happy ? .yellow : .white)
                                                                    .padding(.horizontal, 6)
                                                            }.disabled(taskStatus == .processing)

                                                            Button {
                                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                                    injected.interactorContainer.messageInteractor.setReaction(
                                                                        roomid: currentChatroomid, chatid: fullScreenVideoId,
                                                                        reaction: Reaction(
                                                                            email: email,
                                                                            reaction: myReaction?.reaction == .read ? .cancel : .read,
                                                                            timestamp: Date()),
                                                                        taskStatus: $taskStatus, reactions: $reactions)
                                                                        .store(in: &applicationViewModel.cancellableSet)
                                                                    withAnimation(.spring(duration: 0.3)) {
                                                                        isPresentReactionMenu = false
                                                                    }
                                                                }
                                                            } label: {
                                                                Image(systemName: "checkmark.circle")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(height: 15)
                                                                    .foregroundStyle(myReaction?.reaction == .read ? .green : .white)
                                                                    .padding(.horizontal, 6)
                                                            }.disabled(taskStatus == .processing)

                                                            Button {
                                                                if let email: String = UserDefaultsKeys.userEmail.value() {
                                                                    injected.interactorContainer.messageInteractor.setReaction(
                                                                        roomid: currentChatroomid, chatid: fullScreenVideoId,
                                                                        reaction: Reaction(email: email,
                                                                            reaction: myReaction?.reaction == .good ? .cancel : .good, timestamp: Date()),
                                                                        taskStatus: $taskStatus, reactions: $reactions)
                                                                        .store(in: &applicationViewModel.cancellableSet)
                                                                    withAnimation(.spring(duration: 0.3)) {
                                                                        isPresentReactionMenu = false
                                                                    }
                                                                }
                                                            } label: {
                                                                Image(systemName: "hand.thumbsup.fill")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(height: 15)
                                                                    .foregroundStyle(myReaction?.reaction == .good ? .blue : .white)
                                                                    .padding(.leading, 6)
                                                            }.disabled(taskStatus == .processing)
                                                        }

                                                        Image(systemName: "poweron")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(height: 15)
                                                            .foregroundStyle(.white)
                                                            .padding(.horizontal, 8)

                                                        Button {
                                                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                                                injected.interactorContainer.messageInteractor.setReaction(
                                                                    roomid: currentChatroomid, chatid: fullScreenVideoId,
                                                                    reaction: Reaction(email: email,
                                                                        reaction: myReaction?.reaction == .bad ? .cancel : .bad, timestamp: Date()),
                                                                    taskStatus: $taskStatus, reactions: $reactions)
                                                                    .store(in: &applicationViewModel.cancellableSet)
                                                                withAnimation(.spring(duration: 0.3)) {
                                                                    isPresentReactionMenu = false
                                                                }
                                                            }
                                                        } label: {
                                                            Image(systemName: "hand.thumbsdown")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 15)
                                                                .foregroundStyle(myReaction?.reaction == .bad ? .blue : .white)
                                                                .padding(.vertical, 3)
                                                                .padding(.trailing, 6)
                                                        }.disabled(taskStatus == .processing)
                                                    }
                                                        .cornerRadius(30)
                                                        .padding(.horizontal, 9)
                                                        .padding(.vertical, 6)
                                                        .background { Color.white.opacity(0.3).cornerRadius(30) }
                                                    Spacer()
                                                }

                                                VStack(alignment: .leading) {
                                                    Button {
                                                        withAnimation(.spring(duration: 0.3)) {
                                                            if !shouldShowReactionList {
                                                                if (reactions.reactionTable[fullScreenVideoId] ?? []).count > 0 {
                                                                    shouldShowReactionList.toggle()
                                                                }
                                                            } else {
                                                                shouldShowReactionList.toggle()
                                                            }
                                                        }
                                                    } label: {
                                                        HStack(spacing: 6) {
                                                            Image(systemName: "face.smiling")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 15)
                                                                .foregroundStyle(.white)
                                                                .padding(.vertical, 3)
                                                                .padding(.leading, 3)
                                                            Text("Reaction")
                                                                .font(.system(size: 11))
                                                                .foregroundStyle(.white)
                                                                .padding(.horizontal, 3)
                                                            Text("\(reactions.reactionTable[fullScreenVideoId]?.count ?? 0)")
                                                                .font(.system(size: 11))
                                                                .foregroundStyle(.white)
                                                                .padding(.trailing, 6)
                                                        }
                                                    }
                                                    if shouldShowReactionList {
                                                        ScrollView(showsIndicators: false) {
                                                            VStack(alignment: .leading, spacing: 3) {
                                                                ForEach(reactions.reactionTable[fullScreenVideoId] ?? [], id: \.self) { reaction in
                                                                    HStack(alignment: .center, spacing: 6) {
                                                                        if [.good, .bad, .happy, .read, .question].contains(reaction.reaction) {
                                                                            Text(applicationViewModel.getNickname(reaction.email))
                                                                                .minimumScaleFactor(0.5)
                                                                                .font(.system(size: 13))
                                                                                .foregroundStyle(.white)
                                                                                .lineLimit(1)
                                                                                .padding(.leading, 6)

                                                                            switch reaction.reaction {

                                                                            case .read:
                                                                                Image(systemName: "checkmark.circle")
                                                                                    .resizable()
                                                                                    .scaledToFit()
                                                                                    .frame(height: 15)
                                                                                    .foregroundStyle(.green)
                                                                                    .padding(.trailing, 6)
                                                                                    .padding(.vertical, 3)

                                                                            case .good:
                                                                                Image(systemName: "hand.thumbsup.fill")
                                                                                    .resizable()
                                                                                    .scaledToFit()
                                                                                    .frame(height: 15)
                                                                                    .foregroundStyle(.blue)
                                                                                    .padding(.trailing, 6)
                                                                                    .padding(.vertical, 3)

                                                                            case .bad:
                                                                                Image(systemName: "hand.thumbsdown.fill")
                                                                                    .resizable()
                                                                                    .scaledToFit()
                                                                                    .frame(height: 15)
                                                                                    .foregroundStyle(.blue)
                                                                                    .padding(.trailing, 6)
                                                                                    .padding(.vertical, 3)

                                                                            case .happy:
                                                                                Image(systemName: "face.smiling")
                                                                                    .resizable()
                                                                                    .scaledToFit()
                                                                                    .frame(height: 15)
                                                                                    .foregroundStyle(.yellow)
                                                                                    .padding(.trailing, 6)
                                                                                    .padding(.vertical, 3)

                                                                            case .question:
                                                                                Image(systemName: "questionmark.circle")
                                                                                    .resizable()
                                                                                    .scaledToFit()
                                                                                    .frame(height: 15)
                                                                                    .foregroundStyle(.yellow)
                                                                                    .padding(.trailing, 6)
                                                                                    .padding(.vertical, 3)

                                                                            default:
                                                                                EmptyView()
                                                                            }

                                                                            Text("\(reaction.timestamp.showableTimestamp()) ago")
                                                                                .minimumScaleFactor(0.5)
                                                                                .font(.system(size: 11))
                                                                                .foregroundStyle(.white)
                                                                                .lineLimit(1)
                                                                                .padding(.trailing, 6)
                                                                        }
                                                                    }
                                                                }
                                                            }.frame(maxWidth: .infinity)
                                                        }.frame(maxWidth: .infinity, maxHeight: 70)
                                                    }
                                                }
                                                    .cornerRadius(9)
                                                    .padding(.horizontal, 9)
                                                    .padding(.vertical, 6)
                                                    .background { Color.white.opacity(0.3).cornerRadius(9) }

                                                VStack {
                                                    Button {
                                                        if Permissions.checkPhotosAuthorizationStatus() == .allowed {
                                                            withAnimation(.spring(duration: 0.3)) {
                                                                shouldShowDownloadView = true
                                                            }
                                                            let copy = URL.documentsDirectory.appending(path: "chatvideos/\(fullScreenVideoId).mp4")

                                                            if FileManager.default.fileExists(atPath: copy.path()) {
                                                                PHPhotoLibrary.shared().performChanges({
                                                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: copy)
                                                                }) { success, error in
                                                                    if success {
                                                                        withAnimation(.easeInOut(duration: 0.25)) { isCompleteVideoDownload = true }
                                                                    } else {
                                                                        print("Error saving video to Photos: \(String(describing: error))")
                                                                    }
                                                                }
                                                            } else {
                                                                print("\(fullScreenVideoId).mp4 can not found")
                                                            }
                                                        } else {
                                                            isPlaying = false
                                                            player?.pause()
                                                            activeAlert = .photosPermissionAlert
                                                            shouldShowAlert = true
                                                        }
                                                    } label: {
                                                        HStack(spacing: 6) {
                                                            Image(systemName: "arrow.down.to.line.alt")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 15)
                                                                .foregroundStyle(.white)
                                                                .padding(.vertical, 3)
                                                                .padding(.leading, 6)
                                                            Text("Download")
                                                                .font(.system(size: 11))
                                                                .foregroundStyle(.white)
                                                                .padding(.trailing, 6)
                                                        }
                                                            .cornerRadius(30)
                                                            .padding(.horizontal, 9)
                                                            .padding(.vertical, 6)
                                                            .background { Color.white.opacity(0.3).cornerRadius(30) }
                                                    }
                                                    Spacer()
                                                }

                                                VStack {
                                                    Button {
                                                        isPlaying = false
                                                        player?.pause()
                                                        activeAlert = .deleteVideoAlert
                                                        shouldShowAlert = true
                                                    } label: {
                                                        HStack(spacing: 6) {
                                                            Image(systemName: "trash")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 15)
                                                                .foregroundStyle(.white)
                                                                .padding(.vertical, 3)
                                                                .padding(.leading, 6)
                                                            Text("Delete")
                                                                .font(.system(size: 11))
                                                                .foregroundStyle(.white)
                                                                .padding(.trailing, 6)
                                                        }
                                                            .cornerRadius(30)
                                                            .padding(.horizontal, 9)
                                                            .padding(.vertical, 6)
                                                            .background { Color.white.opacity(0.3).cornerRadius(30) }
                                                    }
                                                    Spacer()
                                                }

                                                VStack {
                                                    Button {
                                                        withAnimation(.spring(duration: 0.3)) {
                                                            shouldShowReportVideoView.toggle()
                                                        }
                                                    } label: {
                                                        HStack(spacing: 6) {
                                                            Image(systemName: "flag")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 15)
                                                                .foregroundStyle(.white)
                                                                .padding(.vertical, 3)
                                                                .padding(.leading, 6)
                                                            Text("Report")
                                                                .font(.system(size: 11))
                                                                .foregroundStyle(.white)
                                                                .padding(.trailing, 6)
                                                        }
                                                            .cornerRadius(30)
                                                            .padding(.horizontal, 9)
                                                            .padding(.vertical, 6)
                                                            .background { Color.white.opacity(0.3).cornerRadius(30) }
                                                    }
                                                    Spacer()
                                                }
                                            }.padding(.horizontal)
                                        }
                                        if let me: String = UserDefaultsKeys.userEmail.value() {
                                            CollapsibleReadUserListView(theme: false, readusers: log.readusers.filter { $0 != me && $0 != log.writer })
                                                .padding(.top, 5)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                if videoDegree != .zero { Spacer() }
            }
        }
            .offset(y: selfOffset)
            .ignoresSafeArea(.all)
            .overlay { shouldShowDownloadView ? downloadView : nil }
            .overlay { shouldShowReportVideoView ? reportVideoView : nil }
            .onAppear {
            self.leftDisappearFastWind = DispatchWorkItem(qos: .userInteractive) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    leftTapFastWind = false
                    leftFastWindSeconds = 3
                }
            }
            self.rightDisappearFastWind = DispatchWorkItem(qos: .userInteractive) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    rightTapFastWind = false
                    rightFastWindSeconds = 3
                }
            }
            if let email: String = UserDefaultsKeys.userEmail.value() {
                self.myReaction = (reactions.reactionTable[fullScreenVideoId] ?? []).filter { $0.email == email }.first
            }
            configureAudioSession()
        }.onChange(of: reactions) { ov, nv in
            if let email: String = UserDefaultsKeys.userEmail.value() {
                self.myReaction = (nv.reactionTable[fullScreenVideoId] ?? []).filter { $0.email == email }.first
            }
        }.onDisappear {
            videoMessage = .notRequested
            fullScreenVideoId = ""
            player?.pause()
            isPlaying = false
            showPlayerControls = false
            isEditingSlider = false
            player = nil
            videoDegree = .zero
            videoCurrentTime = .zero
            videoViewSize = CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width / 16) * 9)
        }.alert(isPresented: $shouldShowAlert) {
            switch activeAlert {
            case .deleteVideoAlert:
                let yes = Alert.Button.destructive(Text("delete")) {
                    let copy = URL.documentsDirectory.appending(path: "chatvideos/\(fullScreenVideoId).mp4")
                    if FileManager.default.fileExists(atPath: copy.path()) {
                        do {
                            try FileManager.default.removeItem(at: copy)
                        } catch {
                            debugPrint("error during the remove video")
                        }
                        withAnimation(.interactiveSpring(duration: 0.3)) {
                            shouldShowFullScreenVideoView = false
                        }
                    } else {
                        print("\(fullScreenVideoId).mp4 is not exist already")
                        withAnimation(.interactiveSpring(duration: 0.3)) {
                            shouldShowFullScreenVideoView = false
                        }
                    }
                }
                let no = Alert.Button.cancel(Text("cancel"))
                return Alert(title: Text("Delete Video"),
                    message: Text("Are you sure you want to delete to this video in this device?"),
                    primaryButton: no, secondaryButton: yes)

            case .photosPermissionAlert:
                return Alert(title: Text("Permission required"), message: Text("Please allow photo permissions in in-app settings"))
            }
        }
    }

    @ViewBuilder
    private var reportVideoView: some View {
        ZStack {
            Color.black.opacity(0.7).onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    shouldShowReportVideoView = false
                }
            }
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Report Video")
                        .foregroundStyle(.white)
                        .bold()
                        .font(.system(size: 18))
                    Spacer()
                }.padding()

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .center, spacing: 7) {
                        Text("""
                             Do you want to declare that content?
                             If you report, users who review the content and create the content within 24 hours may be restricted from using the service.
                             """)
                            .foregroundStyle(.white)
                    }
                }.padding(.vertical)

                HStack(alignment: .bottom) {
                    Spacer()
                    Button {
                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            injected.interactorContainer.messageInteractor.reportMessage(
                                email: email, roomid: currentChatroomid, chatid: fullScreenVideoId,
                                shouldShowFullScreenVideoView: $shouldShowFullScreenVideoView, chatrooms: $applicationViewModel.userChatrooms)
                                .store(in: &applicationViewModel.cancellableSet)
                        }
                    } label: {
                        Rectangle()
                            .foregroundStyle(.blue)
                            .frame(width: 100, height: 40)
                            .cornerRadius(9)
                            .overlay(
                            Text("Report")
                                .foregroundStyle(.white)
                        )
                    }
                }
            }
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .padding()
                .cornerRadius(10.0)
                .background {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color.gray)
            }
        }.ignoresSafeArea(.all)
    }

    @ViewBuilder
    private var videoView: some View {
        switch videoMessage {
        case .notRequested:
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    LoadingDonutView(width: UIScreen.main.bounds.width * 0.15)
                    Spacer()
                }
                Spacer()
            }
                .background(.black)
                .frame(height: videoViewSize.height)
                .padding(.top, videoDegree == .zero ? statusBarHeight : 0)
                .onAppear {
                let copy = URL.documentsDirectory.appending(path: "chatvideos/\(fullScreenVideoId).mp4")
                if FileManager.default.fileExists(atPath: copy.path()) {
                    print("\(fullScreenVideoId).mp4 exist already")
                    self.videoMessage = .loaded(copy)
                } else {
                    print("load \(fullScreenVideoId).mp4")
                    injected.interactorContainer.messageInteractor.loadVideo(videoid: fullScreenVideoId, avplayer: $videoMessage)
                }
            }
        case .isLoading(_, _):
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    LoadingDonutView(width: UIScreen.main.bounds.width * 0.15)
                    Spacer()
                }
                Spacer()
            }
                .background(.black)
                .frame(height: videoViewSize.height)
                .padding(.top, videoDegree == .zero ? statusBarHeight : 0)
        case let .loaded(videoURL):
            if let player {
                VStack(alignment: .center) {
                    VideoPlayerView(player: player)
                        .padding(.top, videoDegree == .zero ? statusBarHeight : 0)
                        .rotationEffect(.degrees(videoDegree))
                        .offset(x: videoViewYOffset)
                        .scaleEffect(videoUpScale, anchor: .bottom)
                        .onTapGesture(coordinateSpace: .global) { tappedLocation = $0
                        withAnimation(.easeInOut(duration: 0.2)) { showPlayerControls = true } }
                        .overlay(sliderView)
                        .overlay { fastwindView.padding(.top, videoDegree == .zero ? statusBarHeight : 0) }
                        .overlay { showPlayerControls ?
                        ZStack { playbackControlView.padding(.top, videoDegree == .zero ? statusBarHeight : 0) }
                            .background { Color.black.opacity(0.45).padding(.top, videoDegree == .zero ? statusBarHeight : 0) }
                            .onTapGesture(coordinateSpace: .global) { tappedLocation = $0
                            withAnimation(.easeInOut(duration: 0.2)) { showPlayerControls = false }
                        }.rotationEffect(.degrees(videoDegree)): nil
                    }
                        .simultaneousGesture(SpatialTapGesture(count: 2, coordinateSpace: .global).onEnded {
                            withAnimation(.easeInOut(duration: 0.2)) { showPlayerControls = false }
                            let location = $0.location
                            if let videoLength = self.player?.currentItem?.duration.seconds {
                                if videoLength != videoCurrentTime {
                                    if videoDegree == .zero {
                                        if (UIScreen.main.bounds.width / 2) > location.x && (UIScreen.main.bounds.width / 2) > tappedLocation.x {
                                            if !leftTapFastWind {
                                                withAnimation(.easeInOut(duration: 0.1)) { leftTapFastWind = true }
                                                videoCurrentTime = max(.zero, videoCurrentTime - 3)
                                                player.seek(to: CMTime(seconds: videoCurrentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: leftDisappearFastWind!)
                                            }
                                        } else if (UIScreen.main.bounds.width / 2) < location.x && (UIScreen.main.bounds.width / 2) < tappedLocation.x {
                                            if !rightTapFastWind {
                                                withAnimation(.easeInOut(duration: 0.1)) { rightTapFastWind = true }
                                                videoCurrentTime = min(videoLength, videoCurrentTime + 3)
                                                player.seek(to: CMTime(seconds: videoCurrentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: rightDisappearFastWind!)
                                            }
                                        }
                                    } else {
                                        if (UIScreen.main.bounds.height / 2) > location.y && (UIScreen.main.bounds.height / 2) > tappedLocation.y {
                                            if !leftTapFastWind {
                                                withAnimation(.easeInOut(duration: 0.1)) { leftTapFastWind = true }
                                                videoCurrentTime = max(.zero, videoCurrentTime - 3)
                                                player.seek(to: CMTime(seconds: videoCurrentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: leftDisappearFastWind!)
                                            }
                                        } else if (UIScreen.main.bounds.height / 2) < location.y && (UIScreen.main.bounds.height / 2) < tappedLocation.y {
                                            if !rightTapFastWind {
                                                withAnimation(.easeInOut(duration: 0.1)) { rightTapFastWind = true }
                                                videoCurrentTime = min(videoLength, videoCurrentTime + 3)
                                                player.seek(to: CMTime(seconds: videoCurrentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: rightDisappearFastWind!)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                            .simultaneously(with: isEditingSlider ? nil : DragGesture(coordinateSpace: .global)
                                .onChanged { v in
                                if videoDegree == .zero {
                                    let h = v.translation.height
                                    if h < 0 {
                                        if showPlayerControls {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                showPlayerControls = false
                                            }
                                        }
                                        withAnimation(.linear(duration: 0.1)) {
                                            videoUpScale = min(1.3, 1.0 + (abs(h) * 0.003))
                                        }
                                    } else {
                                        self.selfOffset = h
                                    }
                                } else {
                                    if showPlayerControls {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            showPlayerControls = false
                                        }
                                    }
                                    withAnimation(.linear(duration: 0.1)) {
                                        videoViewYOffset = min(v.translation.width, 0)
                                    }
                                }
                            }.onEnded { v in
                                if videoDegree == .zero {
                                    if v.translation.height > 200 {
                                        withAnimation(.linear(duration: 0.3)) {
                                            selfOffset += UIScreen.main.bounds.height
                                        } completion: { shouldShowFullScreenVideoView = false }
                                    } else if v.translation.height <= -100 {
                                        withAnimation(.spring(duration: 0.3)) {
                                            videoDegree = 90
                                            videoUpScale = 1.0
                                            videoViewSize = CGSize(width: (UIScreen.main.bounds.width / 9) * 16, height: UIScreen.main.bounds.width)
                                        }
                                    } else {
                                        withAnimation(.spring(duration: 0.3)) {
                                            videoUpScale = 1.0
                                            selfOffset = .zero
                                        }
                                    }
                                } else {
                                    if v.translation.width <= -100 {
                                        withAnimation(.spring(duration: 0.3)) {
                                            videoDegree = .zero
                                            videoViewYOffset = .zero
                                            videoViewSize = CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width / 16) * 9)
                                        }
                                    } else {
                                        withAnimation(.spring(duration: 0.3)) { videoViewYOffset = .zero }
                                    }
                                }
                            })
                    )
                }.frame(width: videoViewSize.width, height: videoDegree == .zero ? nil : videoViewSize.height)
            } else {
                VStack(alignment: .center) {
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2)
                            .tint(.white)
                        Spacer()
                    }
                    Spacer()
                }
                    .background(.black)
                    .frame(height: videoViewSize.height)
                    .padding(.top, videoDegree == .zero ? statusBarHeight : 0)
                    .onAppear {
                    self.player = AVPlayer(url: videoURL)
                    let interval = CMTime(seconds: 0.001, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { currentTime in
                        videoCurrentTime = currentTime.seconds
                    })
                    isPlaying = true
                    self.player?.play()
                }
            }
        case .failed:
            Text("load fail")
        }
    }

    @ViewBuilder
    private var playbackControlView: some View {
        ZStack(alignment: .center) {
            HStack(spacing: 25) {
                if self.player?.currentItem?.duration.seconds == videoCurrentTime {
                    Button {
                        videoCurrentTime = .zero
                        player?.seek(to: CMTime(seconds: .zero, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                        self.player?.play()
                    } label: {
                        Image(systemName: "gobackward")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(15)
                            .background { Circle().fill(.black.opacity(0.35)) }
                    }.scaleEffect(videoDegree == .zero ? 1.15 : 1.5)
                } else {
                    Button {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPlaying.toggle()
                        }
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(15)
                            .background { Circle().fill(.black.opacity(0.35)) }
                    }.scaleEffect(videoDegree == .zero ? 1.3 : 1.65)
                }
            }
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    VStack {
                        Text("\(formatTimeInt(Int(videoCurrentTime))) / \(formatTimeInt(Int(self.player?.currentItem?.duration.seconds ?? .zero)))")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }.padding()

                    Spacer()

                    Button {
                        if videoDegree == .zero {
                            withAnimation(.spring(duration: 0.3)) {
                                videoDegree = 90
                                videoUpScale = 1.0
                                videoViewSize = CGSize(width: (UIScreen.main.bounds.width / 9) * 16, height: UIScreen.main.bounds.width)
                            }
                        } else {
                            withAnimation(.spring(duration: 0.3)) {
                                videoDegree = .zero
                                videoViewYOffset = .zero
                                videoViewSize = CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width / 16) * 9)
                            }
                        }
                    } label: {
                        ZStack(alignment: .center) {
                            Image(videoDegree == .zero ? "ms" : "fs")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.white)
                        }.padding()
                    }
                }
                    .padding(.top, 7)
                    .padding(.bottom, videoDegree == .zero ? .zero : 15)
                    .padding(.horizontal, 9)
            }
            VStack {
                Spacer()
                Slider(value: $videoCurrentTime, in: 0...(self.player?.currentItem?.duration.seconds ?? .zero),
                    onEditingChanged: {
                        isEditingSlider = $0
                        if $0 {
                            player?.pause()
                            isPlaying = false
                        } else {
                            player?.play()
                            isPlaying = true
                        }
                    })
                    .accentColor(Color("pastel red foreground"))
                    .animation(.linear(duration: 1), value: videoCurrentTime)
                    .offset(y: videoDegree == .zero ? 15 : 0)
                    .onChange(of: videoCurrentTime) { _, nv in
                    if isEditingSlider {
                        withAnimation(.linear(duration: 1)) {
                            videoCurrentTime = nv
                            player?.seek(to: CMTime(seconds: nv, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                        }
                    }
                }.onAppear {
                    let progressCircleConfig = UIImage.SymbolConfiguration(scale: .small)
                    UISlider.appearance()
                        .setThumbImage(UIImage(systemName: "circle.fill", withConfiguration: progressCircleConfig), for: .normal)
                }
            }
        }.padding(0)
    }

    @ViewBuilder
    private var fastwindView: some View {
        HStack {
            HStack {
                Spacer()
                if leftTapFastWind {
                    VStack(alignment: .center, spacing: 7) {
                        Spacer()
                        Image(systemName: "backward.end.alt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width / 2 * 0.25)
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, options: .repeat(1), value: acitveFastWindArrowAnimation)
                        Text("\(leftFastWindSeconds) seconds")
                            .font(.title3)
                            .foregroundStyle(.white)
                        Spacer()
                    }.onAppear { acitveFastWindArrowAnimation.toggle() }
                }
                Spacer()
            }.background {
                Circle()
                    .foregroundStyle(.black.opacity(0.3))
                    .scaleEffect(2.5, anchor: .trailing)
                    .offset(x: -(UIScreen.main.bounds.width / 2 * 0.2))
            }.onTapGesture(count: 2) {
                acitveFastWindArrowAnimation.toggle()
                leftFastWindSeconds += 3
                videoCurrentTime = max(.zero, videoCurrentTime - 3)
                self.player?.seek(to: CMTime(seconds: videoCurrentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                leftDisappearFastWind?.cancel()
                self.leftDisappearFastWind = DispatchWorkItem(qos: .userInteractive) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        leftTapFastWind = false
                        leftFastWindSeconds = 3
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: leftDisappearFastWind!)
            }.clipped()

            HStack {
                Spacer()
                if rightTapFastWind {
                    VStack(alignment: .center, spacing: 7) {
                        Spacer()
                        Image(systemName: "forward.end.alt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width / 2 * 0.25)
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, options: .repeat(1), value: acitveFastWindArrowAnimation)
                        Text("\(rightFastWindSeconds) seconds")
                            .font(.title3)
                            .foregroundStyle(.white)
                        Spacer()
                    }.onAppear { acitveFastWindArrowAnimation.toggle() }
                }
                Spacer()
            }.background {
                Circle()
                    .foregroundStyle(.black.opacity(0.3))
                    .scaleEffect(2.5, anchor: .leading)
                    .offset(x: (UIScreen.main.bounds.width / 2 * 0.2))
            }.onTapGesture(count: 2) {
                acitveFastWindArrowAnimation.toggle()
                if let videoLength = self.player?.currentItem?.duration.seconds {
                    rightFastWindSeconds += 3
                    videoCurrentTime = min(videoLength, videoCurrentTime + 3)
                    player?.seek(to: CMTime(seconds: videoCurrentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                }
                rightDisappearFastWind?.cancel()
                self.rightDisappearFastWind = DispatchWorkItem(qos: .userInteractive) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        rightTapFastWind = false
                        rightFastWindSeconds = 3
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: rightDisappearFastWind!)
            }.clipped()
        }.rotationEffect(.degrees(videoDegree))
    }

    @ViewBuilder
    private var sliderView: some View {
        if let total = self.player?.currentItem?.duration.seconds {
            if !total.isNaN {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                    }.overlay {
                        ProgressView(value: videoCurrentTime, total: total)
                            .tint(.white)
                            .background(.black.opacity(0.4))
                    }
                }
                    .opacity(videoDegree == .zero && !showPlayerControls ? 1 : 0)
                    .rotationEffect(.degrees(videoDegree))
            }
        }
    }

    @ViewBuilder
    private var downloadView: some View {
        ZStack(alignment: .center) {
            Color.black.opacity(0.7)

            if isCompleteVideoDownload {
                ZStack(alignment: .center) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .symbolEffect(.bounce, value: videoDownloadCompleteCheckImageAnimation)
                        .frame(width: UIScreen.main.bounds.width * 0.15)
                        .foregroundStyle(.white)
                        .onAppear {
                        videoDownloadCompleteCheckImageAnimation.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.spring(duration: 0.3)) {
                                shouldShowDownloadView = false
                            }
                        }
                    }
                }
            } else { LoadingDonutView(width: UIScreen.main.bounds.width * 0.2) }
        }.onDisappear { isCompleteVideoDownload = false }.ignoresSafeArea(.all)
    }

    private func formatTimeInt(_ seconds: Int) -> String {
        var result = ""
        let h = seconds / 3600
        result.append(h > 0 ? "\(h):" : "")
        var n = seconds % 3600
        let m = n / 60
        result.append("\(m):")
        n = n % 60
        result.append(n < 10 ? "0\(n)" : "\(n)")
        return result
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    private var statusBarHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        return windowScene.statusBarManager?.statusBarFrame.height ?? 0
    }

    private var bottomSafeareaHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        return windowScene.keyWindow?.safeAreaInsets.bottom ?? 0
    }
}
