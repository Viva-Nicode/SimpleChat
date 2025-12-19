import SwiftUI
import SDWebImageSwiftUI
import AVKit

extension Notification.Name {
    static let showContextMenu = Notification.Name("showContextMenu")
    static let hideContextMenu = Notification.Name("hideContextMenu")
}

typealias TaskStatusSubject = Binding<TaskStatus>

enum TaskStatus {
    case notRequested
    case processing
    case complete
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    @ViewBuilder
    func configureMessageAlignment(isme: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            isme ? Spacer() : nil
            self
            isme ? nil : Spacer()
        }.padding(0)
    }
}

struct ChatMessageView: View {

    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var appSettingModel: AppSettingModel
    @Environment(\.injected) private var injected: DIContainer
    @State private var isReadNotificationChat = false
    @State private var videoConvertingAnimate = false
    @State private var photoConvertingAnimate = false
    @State private var shouldShowReactions = false
    @State private var timestampFormat = false

    @Binding var reactions: MessageReactions
    @State private var myReaction: Reaction?
    @State private var taskStatus: TaskStatus = .notRequested

    @State private var loadCompletePhoto = false

    @State private var shouldShowContextMenu = false
    @State private var shouldRenderingGeoMetryForContextMenu = false

    @State private var upOrDown = false
    @State private var selectedMessageHeight: CGFloat = .zero

    let showFriendDetailView: (String) -> ()
    let showReportAlert: (String) -> ()
    let showFullScreenPhoto: (String) -> ()
    let showFullScreenVideo: (String) -> ()
    let setReadNotification: (String, String, Binding<Bool>) -> ()
    let log: any Logable
    let chatroomid: String
    let prevLog: any Logable
    let chatroomType: ChatroomType

    var body: some View {
        switch log {
        case let chatlog as UserChatLog:
            if let me: String = UserDefaultsKeys.userEmail.value() {
                if me == chatlog.writer {
                    VStack(alignment: .trailing, spacing: 1) {
                        if chatlog.logType == .whisper {
                            HStack(alignment: .center) {
                                Text("Whisper to \(applicationViewModel.whisperTarget(chatlog.id))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color("pastel orange foreground"))
                            }
                                .padding(.vertical, 3)
                                .padding(.horizontal, 7)
                                .cornerRadius(20)
                                .background { Color("pastel orange").cornerRadius(20) }
                        }
                        chatContent(chatlog, me)
                            .onAppear { isReadNotificationChat = chatlog.isSetReadNotification }
                        if isReadNotificationChat {
                            Image("bell")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .background(.clear)
                                .cornerRadius(3)
                        }
                    }
                        .frame(maxWidth: screenWidth * 0.9)
                        .offset(x: 10)
                } else {
                    if isFirstLog {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(alignment: .bottom) {
                                ZStack {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 37, height: 37)
                                        .clipped()
                                        .cornerRadius(9)
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(chatlog.writer)"), options: [.fromCacheOnly])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 37, height: 37)
                                        .clipped()
                                        .cornerRadius(9)
                                        .modifier(RefreshableWebImageProfileModifier(chatlog.writer, false))
                                }
                                Text(writer?.nickname ?? chatlog.writer)
                                    .font(.system(size: 13.5))
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }.onTapGesture { showFriendDetailView(chatlog.writer) }
                            chatContent(chatlog, me)
                        }
                            .frame(maxWidth: screenWidth * 0.9)
                            .offset(x: -10)
                    } else {
                        VStack(alignment: .leading, spacing: 1) {
                            chatContent(chatlog, me)
                        }
                            .frame(maxWidth: screenWidth * 0.9)
                            .offset(x: -10)
                    }
                }
            }

        case let syslog as SystemLog:
            VStack {
                HStack(alignment: .firstTextBaseline) {
                    Spacer()
                    HStack {
                        Text(syslog.getSystemMessage { applicationViewModel.getNickname($0) })
                            .foregroundStyle(appSettingModel.appTheme ? .indigo : .yellow)
                            .font(.system(size: 15))
                    }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background { BackgroundBlurView().cornerRadius(6) }
                        .cornerRadius(6)
                    Spacer()
                }
                    .frame(maxWidth: screenWidth * 0.9)
            }.padding(.vertical, 5)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func chatContent(_ log: UserChatLog, _ me: String) -> some View {
        switch log.logType {
        case .text:
            VStack(alignment: log.writer == me ? .trailing : .leading) {
                Text(log.detail)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .foregroundColor(.white)
                    .font(.system(size: 14.5))
                    .cornerRadius(5, corners: [.bottomLeft, .bottomRight, log.writer == me ? .topLeft : .topRight])
                    .background {
                    if log.writer == me {
                        if chatroomType == .pair && log.readusers.count >= 2 {
                            Color("Gradation orange end light").cornerRadius(5, corners: [.bottomLeft, .bottomRight, .topLeft])
                        } else {
                            Color("pastel gray foreground").cornerRadius(5, corners: [.bottomLeft, .bottomRight, .topLeft])
                        }
                    } else {
                        Color("pastel orange foreground").cornerRadius(5, corners: [.bottomLeft, .bottomRight, .topRight])
                    }
                }.animation(.linear, value: log.readusers)
            }.onAppear {
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    self.myReaction = (reactions.reactionTable[log.id] ?? []).filter { $0.email == email }.first
                }
            }.onChange(of: reactions) { ov, nv in
                if let email: String = UserDefaultsKeys.userEmail.value() {
                    self.myReaction = (nv.reactionTable[log.id] ?? []) .filter { $0.email == email }.first
                }
            }.onReceive(NotificationCenter.default.publisher(for: .showContextMenu)) {
                if log.id != $0.userInfo!["chatid"] as? String {
                    shouldRenderingGeoMetryForContextMenu = false
                    withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                }
            }.onReceive(NotificationCenter.default.publisher(for: .hideContextMenu)) { notificatoin in
                shouldRenderingGeoMetryForContextMenu = false
                withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
            }
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight, log.writer == me ? .topLeft : .topRight])
                .overlay(alignment: log.writer == me ? upOrDown ? .topTrailing : .bottomTrailing: upOrDown ? .topLeading : .bottomLeading) {
                shouldShowContextMenu ? textContextMenuView(log, me) : nil
            }
                .background { shouldRenderingGeoMetryForContextMenu ?
                GeometryReader { geo in
                    Color.clear.onAppear {
                        upOrDown = geo.frame(in: .global).minY < screenHeight * 0.5
                        selectedMessageHeight = geo.size.height
                        withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = true }
                    }
                }: nil }
                .onTapGesture { withAnimation(.spring(duration: 0.3)) { shouldShowReactions.toggle() } }
                .onLongPressGesture(minimumDuration: 0.3) {
                if shouldShowReactions {
                    withAnimation(.spring(duration: 0.3)) { shouldShowReactions = false }
                }
                NotificationCenter.default.post(name: .showContextMenu, object: nil, userInfo: ["chatid": log.id])
                shouldRenderingGeoMetryForContextMenu = true
            }
                .padding(.vertical, 2)
                .padding(.horizontal, 0)
                .scaleEffect(shouldShowContextMenu ? 1.1 : 1.0)
                .offset(x: shouldShowContextMenu ? log.writer == me ? -15 : 15: .zero)
                .configureMessageAlignment(isme: log.writer == me)
            if shouldShowReactions && log.logType == .text {
                VStack(alignment: log.writer == me ? .trailing : .leading, spacing: 7) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Author")
                            .font(.system(size: 14))
                            .bold()
                        HStack(spacing: 9) {
                            WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(log.writer)"), options: [.fromCacheOnly])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 37, height: 37)
                                .cornerRadius(9)
                                .shadow(radius: 3)
                                .padding(3)
                                .clipped()
                            VStack(alignment: .leading) {
                                Text(timestampFormat ? log.writer : applicationViewModel.getNickname(log.writer))
                                if timestampFormat {
                                    Text(log.timestamp.dateToString())
                                        .font(.system(size: 11))
                                } else {
                                    Text("\(log.showableTimestamp) ago")
                                        .font(.system(size: 11))
                                }
                            }
                        }
                    }
                        .onTapGesture { withAnimation(.spring(duration: 0.3)) { timestampFormat.toggle() } }
                        .padding()
                        .cornerRadius(10)
                        .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }

                    if chatroomType == .group {
                        VStack(alignment: .leading, spacing: 6) {
                            if log.readusers.filter({ $0 != me && $0 != log.writer }).count > 0 {
                                Text("\(log.readusers.filter { $0 != me && $0 != log.writer }.count) people read it")
                                    .font(.system(size: 14))
                                    .bold()
                                ScrollView(.vertical, showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        ForEach(log.readusers.filter { $0 != me && $0 != log.writer }, id: \.self) { user in
                                            HStack(alignment: .center, spacing: 5) {
                                                WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(user)"), options: [.fromCacheOnly])
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 35, height: 35)
                                                    .clipped()
                                                    .cornerRadius(9)
                                                    .shadow(radius: 1)
                                                Text(applicationViewModel.getNickname(user))
                                                    .font(.system(size: 14))
                                                    .lineLimit(1)
                                                if let idx = (reactions.reactionTable[log.id] ?? []).firstIndex(where: { $0.email == user }) {

                                                    switch (reactions.reactionTable[log.id] ?? [])[idx].reaction {

                                                    case .read:
                                                        Image(systemName: "checkmark.circle")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(height: 15)
                                                            .foregroundStyle(.green)

                                                    case .good:
                                                        Image(systemName: "hand.thumbsup.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(height: 15)
                                                            .foregroundStyle(.blue)

                                                    case .bad:
                                                        Image(systemName: "hand.thumbsdown.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(height: 15)
                                                            .foregroundStyle(.blue)

                                                    case .happy:
                                                        Image(systemName: "face.smiling")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(height: 15)
                                                            .foregroundStyle(.yellow)

                                                    case .question:
                                                        Image(systemName: "questionmark.circle")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(height: 15)
                                                            .foregroundStyle(.yellow)

                                                    default:
                                                        EmptyView()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }.frame(maxHeight: 120)
                            } else {
                                Text("Nobody has read it")
                                    .font(.system(size: 14))
                                    .bold()
                            }
                        }
                            .cornerRadius(10)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                        }
                    }

                    HStack(alignment: .center, spacing: 18) {
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                injected.interactorContainer.messageInteractor.setReaction(
                                    roomid: chatroomid, chatid: log.id,
                                    reaction: Reaction(
                                        email: email,
                                        reaction: myReaction?.reaction == .read ? .cancel : .read,
                                        timestamp: Date()), taskStatus: $taskStatus,
                                    reactions: $reactions)
                                    .store(in: &applicationViewModel.cancellableSet)
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReactions.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .padding(.top, 4)
                                .padding(.leading, 4)
                                .foregroundStyle(myReaction?.reaction == .read ? .green : .gray.opacity(0.7))
                        }.disabled(taskStatus == .processing)
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                injected.interactorContainer.messageInteractor.setReaction(
                                    roomid: chatroomid, chatid: log.id,
                                    reaction: Reaction(
                                        email: email,
                                        reaction: myReaction?.reaction == .good ? .cancel : .good,
                                        timestamp: Date()), taskStatus: $taskStatus,
                                    reactions: $reactions)
                                    .store(in: &applicationViewModel.cancellableSet)
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReactions.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "hand.thumbsup.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .good ? .blue : .gray.opacity(0.7))
                        }.disabled(taskStatus == .processing)
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                injected.interactorContainer.messageInteractor.setReaction(
                                    roomid: chatroomid, chatid: log.id,
                                    reaction: Reaction(
                                        email: email,
                                        reaction: myReaction?.reaction == .happy ? .cancel : .happy,
                                        timestamp: Date()), taskStatus: $taskStatus,
                                    reactions: $reactions)
                                    .store(in: &applicationViewModel.cancellableSet)
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReactions.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "face.smiling")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .happy ? .yellow : .gray.opacity(0.7))
                        }.disabled(taskStatus == .processing)
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                injected.interactorContainer.messageInteractor.setReaction(
                                    roomid: chatroomid, chatid: log.id,
                                    reaction: Reaction(
                                        email: email,
                                        reaction: myReaction?.reaction == .question ? .cancel : .question,
                                        timestamp: Date()), taskStatus: $taskStatus,
                                    reactions: $reactions)
                                    .store(in: &applicationViewModel.cancellableSet)
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReactions.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .question ? .yellow : .gray.opacity(0.7))
                        }.disabled(taskStatus == .processing)
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                injected.interactorContainer.messageInteractor.setReaction(
                                    roomid: chatroomid, chatid: log.id,
                                    reaction: Reaction(
                                        email: email,
                                        reaction: myReaction?.reaction == .bad ? .cancel : .bad,
                                        timestamp: Date()), taskStatus: $taskStatus,
                                    reactions: $reactions)
                                    .store(in: &applicationViewModel.cancellableSet)
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowReactions.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "hand.thumbsdown.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .padding(.top, 4)
                                .padding(.trailing, 4)
                                .foregroundStyle(myReaction?.reaction == .bad ? .blue : .gray.opacity(0.7))
                        }.disabled(taskStatus == .processing)
                    }
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.vertical, 9)
                        .background(Color.white.cornerRadius(10))
                }
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(.vertical, 5)
                    .padding(log.writer == me ? .trailing : .leading, 4)
                    .padding(log.writer == me ? .leading : .trailing)
            } else {
                if !shouldShowContextMenu { chatReactionsView(log, me) }
            }

        case .photo:
            WebImage(url: URL(string: "\(serverUrl)/chat/get-chatphoto/\(log.id)"), options: [.scaleDownLargeImages])
                .resizable()
                .scaledToFill()
                .frame(maxWidth: screenWidth * 0.7, maxHeight: 600)
                .clipped()
                .cornerRadius(9)
                .shadow(radius: 3)
                .contentShape(Rectangle())
                .onTapGesture { showFullScreenPhoto(log.id) }
                .overlay {
                switch log.mediaState {
                case .loading:
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(alignment: .center) {
                            Image(systemName: "photo.stack")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenWidth * 0.2)
                                .padding(.horizontal)
                                .padding(.top)
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, options: .repeating, value: photoConvertingAnimate)
                                .onAppear { photoConvertingAnimate.toggle() }
                        }
                    }.cornerRadius(10)
                case .complete:
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(alignment: .center) {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenWidth * 0.2)
                                .padding()
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: photoConvertingAnimate)
                                .onAppear { photoConvertingAnimate.toggle() }
                        }
                    }.cornerRadius(10)
                case .end:
                    EmptyView()
                }
            }
                .onReceive(NotificationCenter.default.publisher(for: .showContextMenu)) {
                if log.id != $0.userInfo!["chatid"] as? String {
                    shouldRenderingGeoMetryForContextMenu = false
                    withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                }
            }
                .onReceive(NotificationCenter.default.publisher(for: .hideContextMenu)) { notificatoin in
                shouldRenderingGeoMetryForContextMenu = false
                withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
            }
                .overlay(alignment: log.writer == me ? upOrDown ? .topTrailing : .bottomTrailing: upOrDown ? .topLeading : .bottomLeading) {
                shouldShowContextMenu ? photoContextMenuView(me) : nil
            }
                .background { shouldRenderingGeoMetryForContextMenu ?
                GeometryReader { geo in
                    Color.clear.onAppear {
                        upOrDown = geo.frame(in: .global).minY < screenHeight * 0.5
                        selectedMessageHeight = geo.size.height
                        withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = true }
                    }
                }: nil }
                .gesture(log.writer == me && chatroomType == .group && log.mediaState == .end ? LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in
                    if shouldShowReactions { shouldShowReactions = false }
                    NotificationCenter.default.post(name: .showContextMenu, object: nil, userInfo: ["chatid": log.id])
                    shouldRenderingGeoMetryForContextMenu = true
                }: nil)
                .scaleEffect(shouldShowContextMenu ? 1.1 : 1.0)
                .offset(x: shouldShowContextMenu ? log.writer == me ? -15 : 15: .zero)
                .configureMessageAlignment(isme: log.writer == me)
                .padding(.vertical, 4)
            if !shouldShowContextMenu { chatReactionsView(log, me) }

        case .video:
            WebImage(url: URL(string: "\(serverUrl)/chat/get-thumbnail/\(log.id)"))
                .resizable()
                .scaledToFill()
                .frame(maxWidth: screenWidth * 0.7, maxHeight: 600)
                .clipped()
                .cornerRadius(9)
                .shadow(radius: 3)
                .overlay {
                switch log.mediaState {
                case .loading:
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(alignment: .center) {
                            Image(systemName: "video.bubble")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenWidth * 0.2)
                                .padding()
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, options: .repeating, value: videoConvertingAnimate)
                                .onAppear { videoConvertingAnimate.toggle() }
                        }
                    }.cornerRadius(10)
                case .complete:
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(alignment: .center) {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenWidth * 0.2)
                                .padding()
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: videoConvertingAnimate)
                                .onAppear { videoConvertingAnimate.toggle() }
                        }
                    }.cornerRadius(10)
                case .end:
                    ZStack(alignment: .center) {
                        Color.black.opacity(0.5).cornerRadius(9)
                        Image(systemName: "play.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55)
                            .foregroundStyle(.white)
                    }.onTapGesture { showFullScreenVideo(log.id) }
                }
            }
                .configureMessageAlignment(isme: log.writer == me)
                .padding(.vertical, 4)
            chatReactionsView(log, me)

        case .whisper:
            Text(log.detail)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .foregroundColor(Color("pastel gray foreground"))
                .background(Color("pastel gray"))
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight, log.writer == me ? .topLeft : .topRight])
                .onReceive(NotificationCenter.default.publisher(for: .showContextMenu)) {
                if log.id != $0.userInfo!["chatid"] as? String {
                    shouldRenderingGeoMetryForContextMenu = false
                    withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                }
            }
                .onReceive(NotificationCenter.default.publisher(for: .hideContextMenu)) { notificatoin in
                shouldRenderingGeoMetryForContextMenu = false
                withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
            }
                .overlay(alignment: log.writer == me ? upOrDown ? .topTrailing : .bottomTrailing: upOrDown ? .topLeading : .bottomLeading) {
                shouldShowContextMenu ? whisperContextMenuView(log, me) : nil
            }
                .background { shouldRenderingGeoMetryForContextMenu ?
                GeometryReader { geo in
                    Color.clear.onAppear {
                        upOrDown = geo.frame(in: .global).minY < screenHeight * 0.5
                        selectedMessageHeight = geo.size.height
                        withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = true }
                    }
                }: nil }
                .onTapGesture { /* do notting but must need */ }
                .onLongPressGesture(minimumDuration: 0.3) {
                if shouldShowReactions { shouldShowReactions = false }
                NotificationCenter.default.post(name: .showContextMenu, object: nil, userInfo: ["chatid": log.id])
                shouldRenderingGeoMetryForContextMenu = true
            }
                .scaleEffect(shouldShowContextMenu ? 1.1 : 1.0)
                .offset(x: shouldShowContextMenu ? log.writer == me ? -15 : 15: .zero)
                .configureMessageAlignment(isme: log.writer == me)
                .padding(.top, 5)

        case .blocked:
            Text("⚠️ Blocked Contents")
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .foregroundColor(.white)
                .background(.gray)
                .cornerRadius(8)
                .configureMessageAlignment(isme: log.writer == me)
                .padding(.top, 5)

        default:
            Text("error")
        }
    }

    @ViewBuilder
    private func chatReactionsView(_ log: UserChatLog, _ me: String) -> some View {
        if (reactions.reactionTable[log.id] ?? []).count > 0 {
            HStack(alignment: .center, spacing: 5) {
                ForEach((reactions.reactionTable[log.id] ?? []).prefix(3), id: \.self) { reaction in
                    ZStack(alignment: .center) {
                        reactionImage(reaction.reaction)
                            .scaledToFit()
                            .frame(height: 15)
                    }
                }
                if (reactions.reactionTable[log.id] ?? []).count > 3 {
                    Text("+\((reactions.reactionTable[log.id] ?? []).count - 3)")
                        .foregroundStyle(.black)
                }
            }
                .padding(3)
                .cornerRadius(6)
                .background { Color.white.cornerRadius(6).shadow(radius: 1) }
        } else { EmptyView() }
    }

    @ViewBuilder
    private func whisperContextMenuView(_ log: UserChatLog, _ me: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if log.writer != me {
                HStack(alignment: .center) {
                    Text("Report")
                        .font(.system(size: 12))
                    Spacer()
                    Image(systemName: "light.beacon.max")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 14)
                }
                    .contentShape(Rectangle())
                    .onTapGesture {
                    shouldRenderingGeoMetryForContextMenu = false
                    withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                    showReportAlert(log.id)
                }
            }
            HStack(alignment: .center) {
                Text("Copy")
                    .font(.system(size: 12))
                Spacer()
                Image(systemName: "doc.on.doc")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 14)
            }
                .contentShape(Rectangle())
                .onTapGesture {
                shouldRenderingGeoMetryForContextMenu = false
                withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                UIPasteboard.general.string = log.detail
            }
        }
            .padding(.horizontal)
            .padding(.vertical, 7)
            .background(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
            .frame(width: screenWidth * 0.4)
            .offset(y: upOrDown ? selectedMessageHeight + 7 : -selectedMessageHeight - 7)
    }

    @ViewBuilder
    private func photoContextMenuView(_ me: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center) {
                Text("read notification")
                    .font(.system(size: 12))
                Spacer()
                Image(systemName: "bell.and.waves.left.and.right")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 14)
            }
                .contentShape(Rectangle())
                .onTapGesture {
                shouldRenderingGeoMetryForContextMenu = false
                withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                setReadNotification(me, log.id, $isReadNotificationChat)
            }
        }
            .padding(.horizontal)
            .padding(.vertical, 7)
            .background(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
            .frame(width: screenWidth * 0.4)
            .offset(y: upOrDown ? selectedMessageHeight + 7 : -selectedMessageHeight - 7)
    }

    @ViewBuilder
    private func textContextMenuView(_ log: UserChatLog, _ me: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if log.writer == me && chatroomType == .group {
                HStack(alignment: .center) {
                    Text("read notification")
                        .font(.system(size: 12))
                    Spacer()
                    Image(systemName: "bell.and.waves.left.and.right")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 14)
                }
                    .contentShape(Rectangle())
                    .onTapGesture {
                    shouldRenderingGeoMetryForContextMenu = false
                    withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                    setReadNotification(me, log.id, $isReadNotificationChat)
                }
                Divider()
            }
            if log.writer != me {
                HStack(alignment: .center) {
                    Text("Report")
                        .font(.system(size: 12))
                    Spacer()
                    Image(systemName: "light.beacon.max")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 14)
                }
                    .contentShape(Rectangle())
                    .onTapGesture {
                    shouldRenderingGeoMetryForContextMenu = false
                    withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                    showReportAlert(log.id)
                }
                Divider()
            }
            HStack(alignment: .center) {
                Text("Copy")
                    .font(.system(size: 12))
                Spacer()
                Image(systemName: "doc.on.doc")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 14)
            }
                .contentShape(Rectangle())
                .onTapGesture {
                shouldRenderingGeoMetryForContextMenu = false
                withAnimation(.spring(duration: 0.3)) { shouldShowContextMenu = false }
                UIPasteboard.general.string = log.detail
            }
        }
            .padding(.horizontal)
            .padding(.vertical, 7)
            .background(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
            .frame(width: screenWidth * 0.4)
            .offset(y: upOrDown ? selectedMessageHeight + 7 : -selectedMessageHeight - 7)
    }

    @ViewBuilder
    private func reactionImage(_ react: ReactionState) -> some View {
        switch react {
        case .read:
            Image(systemName: "checkmark.circle")
                .resizable()
                .foregroundStyle(.green)
        case .good:
            Image(systemName: "hand.thumbsup.fill")
                .resizable()
                .foregroundStyle(.blue)
        case .bad:
            Image(systemName: "hand.thumbsdown.fill")
                .resizable()
                .foregroundStyle(.blue)
        case .happy:
            Image(systemName: "face.smiling")
                .resizable()
                .foregroundStyle(.yellow)
        case .question:
            Image(systemName: "questionmark.circle")
                .resizable()
                .foregroundStyle(.yellow)
        default:
            EmptyView()
        }
    }

    private var isFirstLog: Bool {
        if let ucl = prevLog as? UserChatLog, let ccl = log as? UserChatLog {
            return !(ucl.id != ccl.id && ucl.writer == ccl.writer)
        } else {
            return true
        }
    }

    private var writer: UserFriend? {
        if let chatlog = log as? UserChatLog {
            return applicationViewModel.userfriends.first { $0.email == chatlog.writer }
        } else {
            return nil
        }
    }
}
