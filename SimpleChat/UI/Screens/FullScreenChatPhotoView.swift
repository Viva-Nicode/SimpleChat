import SwiftUI
import SDWebImageSwiftUI
import Photos

extension Array where Element == Bool {

    enum kindOfControlButton: Int {
        case download = 0
        case reaction = 1
        case readusers = 2
        case report = 3
    }

    subscript(koc: kindOfControlButton) -> Bool? {
        get { return self[koc.rawValue] }
        set { self[koc.rawValue] = newValue ?? false }
    }
}

struct PresentablePhoto {
    var photoLog: UserChatLog
    var isPresented: Bool
}

struct FullScreenChatPhotoView: View {

    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @Environment(\.injected) private var injected: DIContainer
    @State private var shouldShowPermissionAlert = false
    @State private var shouldShowControlbar = true

    @Binding var shouldShowFullScreenPhotoView: Bool

    //MARK: photo control
    @State private var photoScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = .zero

    @State private var selfOffset: CGFloat = .zero

    @State private var isCompletePhotoDownload = false
    @State private var photoDownloadCompleteCheckImageAnimation = false
    @State var shouldShowDownloadView = false
    @State private var timestampFormat = false
    @State private var shouldShowReadUserList = false

    @State var imagePath: String?
    let currentChatroomid: String
    @State private var currentPhotoLog: UserChatLog?

    //MARK: reactions control
    @State private var myReaction: Reaction?
    @State private var taskStatus: TaskStatus = .notRequested

    @State private var isActiveControlButtons = [false, false, false, false]
    @State private var isAnimationControlButtons = [false, false, false, false]

    @Binding var reactions: MessageReactions

    @State var chatPhotos: [PresentablePhoto] = []

    @State var scrollPosition: Int? = 0

    var body: some View {
        ZStack {
            BackgroundBlurView()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(chatPhotos.indices, id: \.self) { photoIndex in
                        if chatPhotos[photoIndex].isPresented {
                            ScrollView([.vertical, .horizontal], showsIndicators: false) {
                                WebImage(url: URL(string: "\(serverUrl)/chat/get-chatphoto/\(chatPhotos[photoIndex].photoLog.id)"))
                                    .resizable()
                                    .cornerRadius(10)
                                    .padding(10)
                                    .scaledToFit()
                                    .frame(width: UIScreen.main.bounds.width * photoScale)
                                    .shadow(color: appSettingModel.appTheme ? .black.opacity(0.4) : .white, radius: 3)
                                    .highPriorityGesture(MagnifyGesture(minimumScaleDelta: .zero)
                                        .onChanged { value in
                                        if value.magnification > 1 {
                                            photoScale = min(4.8, (lastScale == .zero ? .zero : lastScale - 1) + value.magnification)
                                        } else {
                                            photoScale = max(0.7, lastScale * value.magnification)
                                        }
                                    }.onEnded { _ in
                                        withAnimation(.spring(duration: 0.3)) {
                                            if photoScale < 1.0 {
                                                photoScale = 1.0
                                            } else if photoScale > 4 {
                                                photoScale = 4
                                            }
                                        }
                                        lastScale = photoScale
                                    }.simultaneously(with: TapGesture().onEnded {
                                            shouldShowControlbar.toggle()
                                            isActiveControlButtons = isActiveControlButtons.map { _ in false }
                                        }
                                    ).simultaneously(with: TapGesture(count: 2).onEnded {
                                            withAnimation(.spring(duration: 0.2)) {
                                                photoScale = 1.0
                                                lastScale = .zero
                                            }
                                        }
                                    )
                                )
                            }
                                .scrollDisabled(photoScale == 1.0)
                                .frame(width: screenWidth, height: screenHeight + 15)
                                .clipped()
                                .scrollTransition(.animated.animation(.spring(duration: 0.3))) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.3)
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.3)
                                    .rotation3DEffect(.radians(phase.value), axis: (1, 1, 1))
                            }
                        } else {
                            LazyVStack {
                                Image(systemName: "photo")
                                    .resizable()
                                    .cornerRadius(10)
                                    .padding(10)
                                    .scaledToFit()
                                    .opacity(0.3)
                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                            }.frame(height: UIScreen.main.bounds.height + 15)
                        }
                    }
                }
                    .scrollTargetLayout()
                    .simultaneousGesture(photoScale == 1.0 ? DragGesture(minimumDistance: 50, coordinateSpace: .global)
                        .onChanged { value in
                        if value.translation.height > 0 {
                            selfOffset = value.translation.height - 50
                        }
                    }.onEnded { v in
                        if v.translation.height - 50 > 200 {
                            withAnimation(.linear(duration: 0.3)) {
                                selfOffset += UIScreen.main.bounds.height
                            } completion: { shouldShowFullScreenPhotoView = false }
                        } else {
                            withAnimation(.spring(duration: 0.3)) {
                                selfOffset = .zero
                            }
                        }
                    }: nil
                ).onAppear {
                    if let email: String = UserDefaultsKeys.userEmail.value() {
                        self.myReaction = (reactions.reactionTable[imagePath!] ?? []).filter { $0.email == email }.first
                    }

                    if let idx = applicationViewModel.userChatrooms[currentChatroomid] {
                        let photos: [UserChatLog] = applicationViewModel.userChatrooms[idx].log
                            .compactMap { $0 as? UserChatLog }
                            .filter { $0.logType == .photo }
                            .sorted(by: { $0.timestamp > $1.timestamp })

                        let photoIndex = photos.firstIndex(where: { $0.id == imagePath })

                        if let photoIndex {
                            currentPhotoLog = photos[photoIndex]
                            chatPhotos = photos.enumerated().map { (index, photo) in
                                if photoIndex - 3...photoIndex + 3 ~= index {
                                    return PresentablePhoto(photoLog: photo, isPresented: true)
                                } else {
                                    return PresentablePhoto(photoLog: photo, isPresented: false)
                                }
                            }
                            scrollPosition = photoIndex
                        }
                    }
                }.onChange(of: scrollPosition) { _, newScrollPosition in
                    if let newScrollPosition {
                        chatPhotos.enumerated().forEach { (index, photo) in
                            chatPhotos[index].isPresented = newScrollPosition - 3...newScrollPosition + 3 ~= index
                        }
                        currentPhotoLog = chatPhotos[newScrollPosition].photoLog
                        imagePath = chatPhotos[newScrollPosition].photoLog.id
                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            myReaction = (reactions.reactionTable[imagePath!] ?? []).filter { $0.email == email }.first
                        }
                    }
                }
            }
                .contentMargins(0, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $scrollPosition)
                .scrollDisabled(photoScale != 1.0)

            if shouldShowControlbar { controlBar }
        }
            .offset(y: selfOffset)
            .ignoresSafeArea(.all)
            .overlay { shouldShowDownloadView ? downloadView : nil }
            .overlay { isActiveControlButtons[.report]! ? reportPhotoView : nil }
            .onTapGesture {
            shouldShowControlbar.toggle()
            isActiveControlButtons = isActiveControlButtons.map { _ in false }
        }.alert(isPresented: $shouldShowPermissionAlert) {
            Alert(title: Text("Permission required"), message: Text("Please allow photo permissions in in-app settings"))
        }.onChange(of: reactions) { ov, nv in
            if let email: String = UserDefaultsKeys.userEmail.value() {
                self.myReaction = (nv.reactionTable[imagePath!] ?? []).filter { $0.email == email }.first
            }
        }
    }

    @ViewBuilder
    var controlBar: some View {
        VStack(alignment: .center) {
            HStack(alignment: .bottom) {
                Spacer()
                VStack {
                    if let email: String = UserDefaultsKeys.userEmail.value(), let currentPhotoLog {
                        if currentPhotoLog.writer == email {
                            Text(UserDefaultsKeys.userNickname.value() ?? email).foregroundStyle(.white)
                        } else {
                            Text(applicationViewModel.getNickname(currentPhotoLog.writer)).foregroundStyle(.white)
                        }

                        if timestampFormat {
                            Text(currentPhotoLog.timestamp.dateToString()).foregroundStyle(.white)
                        } else {
                            Text("\(currentPhotoLog.showableTimestamp) ago").foregroundStyle(.white)
                        }
                    }
                }
                    .safeareaTopPadding()
                    .padding(.bottom, 5)
                Spacer()
            }
                .background(BackgroundDarkBlurView())
                .highPriorityGesture(TapGesture().onEnded { timestampFormat.toggle() })

            Spacer()

            VStack(alignment: .center) {
                HStack(alignment: .top) {
                    HStack {
                        Image(systemName: "arrow.down.to.line.alt")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, value: isAnimationControlButtons[.download])
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 8)

                    }
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded {
                            isActiveControlButtons[.download]?.toggle()
                            isAnimationControlButtons[.download]?.toggle()

                            for (index, _) in isActiveControlButtons.enumerated() {
                                if isActiveControlButtons[index] && Array<Bool>.kindOfControlButton.download.rawValue != index {
                                    withAnimation(.spring(duration: 0.3)) {
                                        isActiveControlButtons[index] = false
                                    }
                                }
                            }

                            let permisionState = Permissions.checkPhotosAuthorizationStatus()
                            if permisionState == .allowed {
                                withAnimation(.spring(duration: 0.3)) {
                                    shouldShowDownloadView = true
                                }
                                let imageSaver = ImageSaver()
                                guard let imagePath else { return }
                                if let url = URL(string: "\(serverUrl)/chat/get-chatphoto/\(imagePath)") {
                                    SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, finished in
                                        if let error = error {
                                            print("Error downloading image: \(error.localizedDescription)")
                                        } else {
                                            imageSaver.writeToPhotoAlbum(image: image!)
                                            withAnimation(.easeInOut(duration: 0.25)) { isCompletePhotoDownload = true }
                                        }
                                    }
                                }
                            } else {
                                shouldShowPermissionAlert = true
                            }
                        })
                    Spacer()
                    HStack {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            .foregroundStyle(
                            [.read, .good, .happy, .question, .bad].contains(myReaction?.reaction ?? .undefined) ? .red : .white)
                            .symbolEffect(.bounce, value: isAnimationControlButtons[.reaction])
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 8)
                    }
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded {
                            withAnimation(.spring(duration: 0.3)) {
                                isActiveControlButtons[.reaction]?.toggle()
                            }
                            isAnimationControlButtons[.reaction]?.toggle()
                            for (index, _) in isActiveControlButtons.enumerated() {
                                if isActiveControlButtons[index] && [Bool].kindOfControlButton.reaction.rawValue != index {
                                    withAnimation(.spring(duration: 0.3)) {
                                        isActiveControlButtons[index] = false
                                    }
                                }
                            }
                        })
                    Spacer()
                    ZStack {
                        HStack {
                            Image(systemName: "person.fill.checkmark")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 22)
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: isAnimationControlButtons[.readusers])
                                .padding(.horizontal)
                                .padding(.top)
                                .padding(.bottom, 8)
                        }
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottom) { isActiveControlButtons[.readusers] ?? false ? readusersBubble : nil }
                            .highPriorityGesture(TapGesture().onEnded {
                                isAnimationControlButtons[.readusers]?.toggle()
                                withAnimation(.spring(duration: 0.3)) {
                                    isActiveControlButtons[.readusers]?.toggle()
                                }
                                for (index, _) in isActiveControlButtons.enumerated() {
                                    if isActiveControlButtons[index] && [Bool].kindOfControlButton.readusers.rawValue != index {
                                        withAnimation(.spring(duration: 0.3)) {
                                            isActiveControlButtons[index] = false
                                        }
                                    }
                                }
                            }
                        )
                    }

                    Spacer()
                    HStack {
                        Image(systemName: "flag")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, value: isAnimationControlButtons[.report])
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 8)
                    }
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded {
                            isAnimationControlButtons[.report]?.toggle()
                            withAnimation(.spring(duration: 0.3)) {
                                isActiveControlButtons[.report]?.toggle()
                            }
                            for (index, _) in isActiveControlButtons.enumerated() {
                                if isActiveControlButtons[index] && [Bool].kindOfControlButton.report.rawValue != index {
                                    withAnimation(.spring(duration: 0.3)) {
                                        isActiveControlButtons[index] = false
                                    }
                                }
                            }
                        })
                }
                if isActiveControlButtons[.reaction]! {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 15) {
                            ForEach(reactions.reactionTable[imagePath!] ?? [], id: \.self) { reaction in
                                VStack(alignment: .center, spacing: 6) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(reaction.email)"), options: [.refreshCached])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 38, height: 38)
                                        .cornerRadius(9)
                                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                                        Text(applicationViewModel.getNickname(reaction.email))
                                            .font(.system(size: 14))
                                            .lineLimit(1)
                                            .frame(maxWidth: 49)
                                            .foregroundStyle(.white)
                                        switch reaction.reaction {

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
                                    Text("\(reaction.timestamp.showableTimestamp()) ago")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }.padding(.horizontal)

                    HStack(alignment: .top) {
                        ZStack {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .read ? .green : .white)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                if taskStatus != .processing {
                                    if let email: String = UserDefaultsKeys.userEmail.value() {
                                        injected.interactorContainer.messageInteractor.setReaction(
                                            roomid: currentChatroomid, chatid: imagePath!,
                                            reaction: Reaction(email: email,
                                                reaction: myReaction?.reaction == .read ? .cancel : .read, timestamp: Date()),
                                            taskStatus: $taskStatus,
                                            reactions: $reactions)
                                            .store(in: &applicationViewModel.cancellableSet)
                                    }
                                }
                            })
                        ZStack {
                            Image(systemName: "hand.thumbsup.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .good ? .blue : .white)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                if taskStatus != .processing {
                                    if let email: String = UserDefaultsKeys.userEmail.value() {
                                        injected.interactorContainer.messageInteractor.setReaction(
                                            roomid: currentChatroomid, chatid: imagePath!,
                                            reaction: Reaction(email: email,
                                                reaction: myReaction?.reaction == .good ? .cancel : .good, timestamp: Date()),
                                            taskStatus: $taskStatus,
                                            reactions: $reactions)
                                            .store(in: &applicationViewModel.cancellableSet)
                                    }
                                }
                            })
                        ZStack {
                            Image(systemName: "hand.thumbsdown.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .bad ? .blue : .white)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                if taskStatus != .processing {
                                    if let email: String = UserDefaultsKeys.userEmail.value() {
                                        injected.interactorContainer.messageInteractor.setReaction(
                                            roomid: currentChatroomid, chatid: imagePath!,
                                            reaction: Reaction(email: email,
                                                reaction: myReaction?.reaction == .bad ? .cancel : .bad, timestamp: Date()),
                                            taskStatus: $taskStatus,
                                            reactions: $reactions)
                                            .store(in: &applicationViewModel.cancellableSet)
                                    }
                                }
                            })
                        ZStack {
                            Image(systemName: "face.smiling")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .happy ? .yellow : .white)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                if taskStatus != .processing {
                                    if let email: String = UserDefaultsKeys.userEmail.value() {
                                        injected.interactorContainer.messageInteractor.setReaction(
                                            roomid: currentChatroomid, chatid: imagePath!,
                                            reaction: Reaction(email: email,
                                                reaction: myReaction?.reaction == .happy ? .cancel : .happy, timestamp: Date()),
                                            taskStatus: $taskStatus,
                                            reactions: $reactions)
                                            .store(in: &applicationViewModel.cancellableSet)
                                    }
                                }
                            })
                        ZStack {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                                .foregroundStyle(myReaction?.reaction == .question ? .yellow : .white)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                if taskStatus != .processing {
                                    if let email: String = UserDefaultsKeys.userEmail.value() {
                                        injected.interactorContainer.messageInteractor.setReaction(
                                            roomid: currentChatroomid, chatid: imagePath!,
                                            reaction: Reaction(email: email,
                                                reaction: myReaction?.reaction == .question ? .cancel : .question, timestamp: Date()),
                                            taskStatus: $taskStatus,
                                            reactions: $reactions)
                                            .store(in: &applicationViewModel.cancellableSet)
                                    }
                                }
                            })
                    }.padding(.horizontal)
                }
            }
                .safeareaBottomPadding()
                .padding(.horizontal)
                .background(BackgroundDarkBlurView())
        }
    }

    @ViewBuilder
    var readusersBubble: some View {
        let me: String = UserDefaultsKeys.userEmail.value()!

        if let currentPhotoLog {
            let readusers = currentPhotoLog.readusers.filter({ $0 != me && $0 != currentPhotoLog.writer })

            VStack(alignment: .leading) {
                if readusers.count > 0 {
                    HStack(alignment: .center) {
                        Text("\(readusers.count) people read it")
                            .font(.system(size: 14))
                            .bold()
                        Spacer()
                    }
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading) {
                            ForEach(currentPhotoLog.readusers.filter({ $0 != me && $0 != currentPhotoLog.writer }), id: \.self) { user in
                                HStack {
                                    Text(applicationViewModel.getNickname(user))
                                        .foregroundStyle(.black)
                                    Spacer()
                                }
                            }
                        }
                    }
                } else {
                    Text("Nobody has read it")
                        .font(.system(size: 14))
                        .bold()
                }
            }
                .frame(height: 100)
                .fixedSize(horizontal: true, vertical: false)
                .padding()
                .background(Color.white.cornerRadius(10).shadow(radius: 2))
                .offset(y: -58)
        }
    }

    @ViewBuilder
    var downloadView: some View {
        ZStack(alignment: .center) {
            Color.black.opacity(0.7)
            if isCompletePhotoDownload {
                ZStack(alignment: .center) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .symbolEffect(.bounce, value: photoDownloadCompleteCheckImageAnimation)
                        .frame(width: UIScreen.main.bounds.width * 0.15)
                        .foregroundStyle(.white)
                        .onAppear {
                        photoDownloadCompleteCheckImageAnimation.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.spring(duration: 0.3)) {
                                shouldShowDownloadView = false
                            }
                        }
                    }
                }
            } else { LoadingDonutView(width: UIScreen.main.bounds.width * 0.2) }
        }.onDisappear {
            isCompletePhotoDownload = false
        }.ignoresSafeArea(.all)
    }

    @ViewBuilder
    private var reportPhotoView: some View {
        ZStack {
            Color.black.opacity(0.7).onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    isActiveControlButtons[.report]! = false
                }
            }
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Report Photo")
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
                                email: email, roomid: currentChatroomid, chatid: imagePath!,
                                shouldShowFullScreenVideoView: $shouldShowFullScreenPhotoView,
                                chatrooms: $applicationViewModel.userChatrooms)
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
}

//struct SpeechBubblePath: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//
//        let cornerRadius: CGFloat = 9
//        let arrowWidth: CGFloat = 14
//        let arrowHeight: CGFloat = 14
//
//        path.move(to: CGPoint(x: cornerRadius, y: 0))
//        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
//        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
//        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius - arrowHeight))
//        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius - arrowHeight), radius: cornerRadius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
//        path.addLine(to: CGPoint(x: rect.width / 2 + arrowWidth / 2, y: rect.height - arrowHeight))
//        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
//        path.addLine(to: CGPoint(x: rect.width / 2 - arrowWidth / 2, y: rect.height - arrowHeight))
//        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - arrowHeight))
//        path.addArc(center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius - arrowHeight), radius: cornerRadius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
//        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
//        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
//
//        return path
//    }
//}

//struct FullScreenChatPhotoViewDemo: View {
//
//    @EnvironmentObject var appSettingModel: AppSettingModel
//    @EnvironmentObject var applicationViewModel: ApplicationViewModel
//    @Environment(\.injected) private var injected: DIContainer
//    @State private var shouldShowPermissionAlert = false
//    @State private var shouldShowControlbar = true
//
//    @Binding var shouldShowFullScreenPhotoView: Bool
//
//    //MARK: photo control
//    @State private var photoScale: CGFloat = 1.0
//    @State private var lastScale: CGFloat = .zero
//    @State private var photoOffset: CGSize = .zero
//    @State private var lastOffset: CGSize = .zero
//    @State private var selfOffset: CGFloat = .zero
//    @State private var photoGeo: GeometryProxy?
//
//    @State private var isCompletePhotoDownload = false
//    @State private var photoDownloadCompleteCheckImageAnimation = false
//    @State var shouldShowDownloadView = false
//    @State private var timestampFormat = false
//    @State private var shouldShowReadUserList = false
//
//    @State var imagePath: String?
//    let currentChatroomid: String
//    @State private var currentPhotoLog: UserChatLog?
//
//    //MARK: reactions control
//    @State private var myReaction: Reaction?
//    @State private var taskStatus: TaskStatus = .notRequested
//
//    @State private var isActiveControlButtons = [false, false, false, false]
//    @State private var isAnimationControlButtons = [false, false, false, false]
//
//    @Binding var reactions: MessageReactions
//
//    @State var chatPhotos: [PresentablePhoto] = []
//
//    @State var scrollPosition: Int? = 0
//
//    var body: some View {
//        ZStack {
//            appSettingModel.appTheme ? Color.white : Color.black
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack {
//                    ForEach(chatPhotos.indices, id: \.self) { photoIndex in
//                        if chatPhotos[photoIndex].isPresented {
//                            LazyVStack {
//                                WebImage(url: URL(string: "\(serverUrl)/chat/get-chatphoto/\(chatPhotos[photoIndex].photoLog.id)"))
//                                    .resizable()
//                                    .cornerRadius(10)
//                                    .padding(10)
//                                    .scaledToFit()
//                                    .offset(photoOffset)
//                                    .scaleEffect(photoScale)
//                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
//                                    .scrollTransition { content, phase in
//                                    content.opacity(phase.isIdentity ? 1.0 : 0.0)
//                                        .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3, y: phase.isIdentity ? 1.0 : 0.3)
//                                        .offset(y: phase.isIdentity ? 0 : 50)
//                                }
//                                    .shadow(color: appSettingModel.appTheme ? .black.opacity(0.4) : .white, radius: 3)
//                                    .overlay {
//                                    photoIndex == scrollPosition ?
//                                    GeometryReader { photoGeo in
//                                        Color.white.opacity(0.001).onAppear { self.photoGeo = photoGeo }
//                                    }
//                                        .cornerRadius(10)
//                                        .padding(10)
//                                        .id(photoIndex)
//                                        .shadow(color: appSettingModel.appTheme ? .black.opacity(0.4) : .white, radius: 3)
//                                        .offset(photoOffset)
//                                        .scaleEffect(photoScale): nil
//                                }.simultaneousGesture(MagnifyGesture(minimumScaleDelta: .zero)
//                                        .onChanged { value in
//                                        if value.magnification > 1 {
//                                            let w = UIScreen.main.bounds.width
//                                            let h = UIScreen.main.bounds.height
//
//                                            let anchor = value.startAnchor
//                                            // padding(10)은 4방향에 각각 10씩을 추가하는것 적용되는 패딩의 총량은 40이된다.
//
//                                            // 중심의 로컬 좌표
//                                            let centerPoint: CGPoint = .init(x: w / 2, y: h / 2)
//
//                                            // 드래그 지점의 로컬 중심 좌표
//                                            let dragPoint: CGPoint = .init(x: w * anchor.x, y: h * anchor.y)
//
//                                            // scale이 커졋다고 w, h가 커지진 않는다.
//                                            let xdif = -(dragPoint.x - centerPoint.x)
//                                            let ydif = -(dragPoint.y - centerPoint.y)
//
//                                            photoScale = min(4.8, (lastScale == .zero ? .zero : lastScale - 1) + value.magnification)
//
//                                            if photoScale <= 4 {
//                                                photoOffset = CGSize(
//                                                    width: (lastOffset.width + xdif * (photoScale - 1)) / photoScale,
//                                                    height: (lastOffset.height + ydif * (photoScale - 1)) / photoScale)
//                                            }
//                                        } else {
//                                            photoScale = max(0.7, lastScale * value.magnification)
//                                            photoOffset = CGSize(width: photoOffset.width * value.magnification, height: photoOffset.height * value.magnification)
//                                            lastOffset = photoOffset
//                                        }
//                                    }.onEnded { _ in
//                                        withAnimation(.spring(duration: 0.3)) {
//                                            if photoScale < 1.0 {
//                                                photoScale = 1.0
//                                            } else if photoScale > 4 {
//                                                photoScale = 4
//                                            }
//                                        }
//                                        lastScale = photoScale
//                                        lastOffset = CGSize(width: photoOffset.width * photoScale, height: photoOffset.height * photoScale)
//                                    }.simultaneously(with: photoScale != 1.0 ? DragGesture(minimumDistance: .zero, coordinateSpace: .global)
//                                            .onChanged { value in
//                                            photoOffset = CGSize(
//                                                width: (lastOffset.width + value.translation.width) / lastScale,
//                                                height: (lastOffset.height + value.translation.height) / lastScale)
//                                        }.onEnded { v in
//                                            guard let photoGeo else { return }
//                                            withAnimation(.spring(duration: 0.3)) {
//                                                if photoGeo.frame(in: .global).minX < 0 && photoGeo.frame(in: .global).maxX < UIScreen.main.bounds.width {
//                                                    if abs(photoGeo.frame(in: .global).minX) > UIScreen.main.bounds.width - photoGeo.frame(in: .global).maxX {
//                                                        photoOffset.width = photoOffset.width + (UIScreen.main.bounds.width - photoGeo.frame(in: .global).maxX) / lastScale
//                                                    } else {
//                                                        photoOffset.width = photoOffset.width - photoGeo.frame(in: .global).minX / lastScale
//                                                    }
//                                                } else if photoGeo.frame(in: .global).minX > 0 && photoGeo.frame(in: .global).maxX > UIScreen.main.bounds.width {
//                                                    if photoGeo.frame(in: .global).minX < photoGeo.frame(in: .global).maxX - UIScreen.main.bounds.width {
//                                                        photoOffset.width = photoOffset.width - photoGeo.frame(in: .global).minX / lastScale
//                                                    } else {
//                                                        photoOffset.width = photoOffset.width - (photoGeo.frame(in: .global).maxX - UIScreen.main.bounds.width) / lastScale
//                                                    }
//                                                }
//
//                                                if photoGeo.frame(in: .global).minY > 0 && photoGeo.frame(in: .global).maxY > UIScreen.main.bounds.height {
//                                                    if photoGeo.frame(in: .global).minY > photoGeo.frame(in: .global).maxY - UIScreen.main.bounds.height {
//                                                        photoOffset.height = photoOffset.height - (photoGeo.frame(in: .global).maxY - UIScreen.main.bounds.height) / lastScale
//                                                    } else {
//                                                        photoOffset.height = photoOffset.height - photoGeo.frame(in: .global).minY / lastScale
//                                                    }
//                                                } else if photoGeo.frame(in: .global).maxY < UIScreen.main.bounds.height && photoGeo.frame(in: .global).minY < 0 {
//                                                    if UIScreen.main.bounds.height - photoGeo.frame(in: .global).maxY > abs(photoGeo.frame(in: .global).minY) {
//                                                        photoOffset.height = photoOffset.height - photoGeo.frame(in: .global).minY / lastScale
//                                                    } else {
//                                                        photoOffset.height = photoOffset.height + (UIScreen.main.bounds.height - photoGeo.frame(in: .global).maxY) / lastScale
//                                                    }
//                                                }
//                                            }
//                                            lastOffset = CGSize(width: photoOffset.width * lastScale, height: photoOffset.height * lastScale)
//                                        }: nil
//                                    ).simultaneously(with: TapGesture().onEnded {
//                                            shouldShowControlbar.toggle()
//                                            isActiveControlButtons = isActiveControlButtons.map { _ in false }
//                                        }
//                                    ).simultaneously(with: TapGesture(count: 2).onEnded {
//                                            withAnimation(.spring(duration: 0.2)) {
//                                                photoScale = 1.0
//                                                lastScale = 1.0
//                                                photoOffset = .zero
//                                                lastOffset = .zero
//                                            }
//                                        }
//                                    )
//                                )
//                            }.frame(height: UIScreen.main.bounds.height + 15)
//                        } else {
//                            LazyVStack {
//                                Image(systemName: "photo")
//                                    .resizable()
//                                    .cornerRadius(10)
//                                    .padding(10)
//                                    .scaledToFit()
//                                    .opacity(0.3)
//                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
//                            }.frame(height: UIScreen.main.bounds.height + 15)
//                        }
//                    }
//                }
//                    .scrollTargetLayout()
//                    .simultaneousGesture(photoScale == 1.0 ? DragGesture(minimumDistance: 30, coordinateSpace: .global)
//                        .onChanged { value in
//                        if value.translation.height > 0 {
//                            selfOffset = value.translation.height - 30
//                        }
//                    }.onEnded { v in
//                        if v.translation.height - 30 > 200 {
//                            withAnimation(.linear(duration: 0.3)) {
//                                selfOffset += UIScreen.main.bounds.height
//                            } completion: { shouldShowFullScreenPhotoView = false }
//                        } else {
//                            withAnimation(.spring(duration: 0.3)) {
//                                selfOffset = .zero
//                                photoOffset = .zero
//                                lastOffset = .zero
//                            }
//                        }
//                    }: nil
//                ).onAppear {
//                    if let email: String = UserDefaultsKeys.userEmail.value() {
//                        self.myReaction = (reactions.reactionTable[imagePath!] ?? []).filter { $0.email == email }.first
//                    }
//
//                    if let idx = applicationViewModel.userChatrooms[currentChatroomid] {
//
//                        let photos: [UserChatLog] = applicationViewModel.userChatrooms[idx].log
//                            .compactMap { $0 as? UserChatLog }
//                            .filter { $0.logType == .photo }
//                            .sorted(by: { $0.timestamp > $1.timestamp })
//
//                        let photoIndex = photos.firstIndex(where: { $0.id == imagePath })
//
//                        if let photoIndex {
//                            currentPhotoLog = photos[photoIndex]
//                            chatPhotos = photos.enumerated().map { (index, photo) in
//                                if photoIndex - 3...photoIndex + 3 ~= index {
//                                    return PresentablePhoto(photoLog: photo, isPresented: true)
//                                } else {
//                                    return PresentablePhoto(photoLog: photo, isPresented: false)
//                                }
//                            }
//                            scrollPosition = photoIndex
//                        }
//                    }
//                }.onChange(of: scrollPosition) { _, newScrollPosition in
//                    if let newScrollPosition {
//                        chatPhotos.enumerated().forEach { (index, photo) in
//                            chatPhotos[index].isPresented = newScrollPosition - 3...newScrollPosition + 3 ~= index
//                        }
//                        currentPhotoLog = chatPhotos[newScrollPosition].photoLog
//                        imagePath = chatPhotos[newScrollPosition].photoLog.id
//                        if let email: String = UserDefaultsKeys.userEmail.value() {
//                            myReaction = (reactions.reactionTable[imagePath!] ?? []).filter { $0.email == email }.first
//                        }
//                    }
//                }
//            }
//                .contentMargins(0, for: .scrollContent)
//                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
//                .scrollPosition(id: $scrollPosition)
//                .scrollDisabled(photoScale != 1.0)
//
//            if shouldShowControlbar { controlBar }
//        }
//            .offset(y: selfOffset)
//            .ignoresSafeArea(.all)
//            .overlay { shouldShowDownloadView ? downloadView : nil }
//            .overlay { isActiveControlButtons[.report]! ? reportPhotoView : nil }
//            .onTapGesture {
//            shouldShowControlbar.toggle()
//            isActiveControlButtons = isActiveControlButtons.map { _ in false }
//        }.alert(isPresented: $shouldShowPermissionAlert) {
//            Alert(title: Text("Permission required"), message: Text("Please allow photo permissions in in-app settings"))
//        }.onChange(of: reactions) { ov, nv in
//            if let email: String = UserDefaultsKeys.userEmail.value() {
//                self.myReaction = (nv.reactionTable[imagePath!] ?? []).filter { $0.email == email }.first
//            }
//        }
//    }
//
//    @ViewBuilder
//    var controlBar: some View {
//        VStack(alignment: .center) {
//            HStack(alignment: .bottom) {
//                Spacer()
//                VStack {
//                    if let email: String = UserDefaultsKeys.userEmail.value(), let currentPhotoLog {
//                        if currentPhotoLog.writer == email {
//                            Text(UserDefaultsKeys.userNickname.value() ?? email).foregroundStyle(.white)
//                        } else {
//                            Text(applicationViewModel.getNickname(currentPhotoLog.writer)).foregroundStyle(.white)
//                        }
//
//                        if timestampFormat {
//                            Text(currentPhotoLog.timestamp.dateToString()).foregroundStyle(.white)
//                        } else {
//                            Text("\(currentPhotoLog.showableTimestamp) ago").foregroundStyle(.white)
//                        }
//                    }
//                }
//                    .safeareaTopPadding()
//                    .padding(.bottom, 5)
//                Spacer()
//            }
//                .background(BackgroundDarkBlurView())
//                .highPriorityGesture(TapGesture().onEnded { timestampFormat.toggle() })
//
//            Spacer()
//
//            VStack(alignment: .center) {
//                HStack(alignment: .top) {
//                    HStack {
//                        Image(systemName: "arrow.down.to.line.alt")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 22)
//                            .foregroundStyle(.white)
//                            .symbolEffect(.bounce, value: isAnimationControlButtons[.download])
//                            .padding()
//                    }
//                        .contentShape(Rectangle())
//                        .highPriorityGesture(TapGesture().onEnded {
//                            isActiveControlButtons[.download]?.toggle()
//                            isAnimationControlButtons[.download]?.toggle()
//
//                            for (index, _) in isActiveControlButtons.enumerated() {
//                                if isActiveControlButtons[index] && Array<Bool>.kindOfControlButton.download.rawValue != index {
//                                    withAnimation(.spring(duration: 0.3)) {
//                                        isActiveControlButtons[index] = false
//                                    }
//                                }
//                            }
//
//                            let permisionState = Permissions.checkPhotosAuthorizationStatus()
//                            if permisionState == .allowed {
//                                withAnimation(.spring(duration: 0.3)) {
//                                    shouldShowDownloadView = true
//                                }
//                                let imageSaver = ImageSaver()
//                                guard let imagePath else { return }
//                                if let url = URL(string: "\(serverUrl)/chat/get-chatphoto/\(imagePath)") {
//                                    SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, finished in
//                                        if let error = error {
//                                            print("Error downloading image: \(error.localizedDescription)")
//                                        } else {
//                                            imageSaver.writeToPhotoAlbum(image: image!)
//                                            withAnimation(.easeInOut(duration: 0.25)) { isCompletePhotoDownload = true }
//                                        }
//                                    }
//                                }
//                            } else {
//                                shouldShowPermissionAlert = true
//                            }
//                        })
//                    Spacer()
//                    HStack {
//                        Image(systemName: "heart.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 22)
//                            .foregroundStyle(
//                            [.read, .good, .happy, .question, .bad].contains(myReaction?.reaction ?? .undefined) ? .red : .white)
//                            .symbolEffect(.bounce, value: isAnimationControlButtons[.reaction])
//                            .padding()
//                    }
//                        .contentShape(Rectangle())
//                        .highPriorityGesture(TapGesture().onEnded {
//                            withAnimation(.spring(duration: 0.3)) {
//                                isActiveControlButtons[.reaction]?.toggle()
//                            }
//                            isAnimationControlButtons[.reaction]?.toggle()
//                            for (index, _) in isActiveControlButtons.enumerated() {
//                                if isActiveControlButtons[index] && [Bool].kindOfControlButton.reaction.rawValue != index {
//                                    withAnimation(.spring(duration: 0.3)) {
//                                        isActiveControlButtons[index] = false
//                                    }
//                                }
//                            }
//                        })
//                    Spacer()
//                    ZStack {
//                        HStack {
//                            Image(systemName: "person.fill.checkmark")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 22)
//                                .foregroundStyle(.white)
//                                .symbolEffect(.bounce, value: isAnimationControlButtons[.readusers])
//                                .padding()
//                        }
//                            .contentShape(Rectangle())
//                            .overlay { isActiveControlButtons[.readusers] ?? false ? readusersBubble : nil }
//                            .highPriorityGesture(TapGesture().onEnded {
//                                isAnimationControlButtons[.readusers]?.toggle()
//                                withAnimation(.spring(duration: 0.3)) {
//                                    isActiveControlButtons[.readusers]?.toggle()
//                                }
//                                for (index, _) in isActiveControlButtons.enumerated() {
//                                    if isActiveControlButtons[index] && [Bool].kindOfControlButton.readusers.rawValue != index {
//                                        withAnimation(.spring(duration: 0.3)) {
//                                            isActiveControlButtons[index] = false
//                                        }
//                                    }
//                                }
//                            })
//                    }
//
//                    Spacer()
//                    HStack {
//                        Image(systemName: "flag")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 22)
//                            .foregroundStyle(.white)
//                            .symbolEffect(.bounce, value: isAnimationControlButtons[.report])
//                            .padding()
//                    }
//                        .contentShape(Rectangle())
//                        .highPriorityGesture(TapGesture().onEnded {
//                            isAnimationControlButtons[.report]?.toggle()
//                            withAnimation(.spring(duration: 0.3)) {
//                                isActiveControlButtons[.report]?.toggle()
//                            }
//                            for (index, _) in isActiveControlButtons.enumerated() {
//                                if isActiveControlButtons[index] && [Bool].kindOfControlButton.report.rawValue != index {
//                                    withAnimation(.spring(duration: 0.3)) {
//                                        isActiveControlButtons[index] = false
//                                    }
//                                }
//                            }
//                        })
//                }
//                if isActiveControlButtons[.reaction]! {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(alignment: .top, spacing: 15) {
//                            ForEach(reactions.reactionTable[imagePath!] ?? [], id: \.self) { reaction in
//                                VStack(alignment: .center, spacing: 6) {
//                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(reaction.email)"), options: [.refreshCached])
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(width: 38, height: 38)
//                                        .cornerRadius(9)
//                                    HStack(alignment: .firstTextBaseline, spacing: 3) {
//                                        Text(applicationViewModel.getNickname(reaction.email))
//                                            .font(.system(size: 14))
//                                            .lineLimit(1)
//                                            .frame(maxWidth: 49)
//                                            .foregroundStyle(.white)
//                                        switch reaction.reaction {
//
//                                        case .read:
//                                            Image(systemName: "checkmark.circle")
//                                                .resizable()
//                                                .scaledToFit()
//                                                .frame(height: 15)
//                                                .foregroundStyle(.green)
//
//                                        case .good:
//                                            Image(systemName: "hand.thumbsup.fill")
//                                                .resizable()
//                                                .scaledToFit()
//                                                .frame(height: 15)
//                                                .foregroundStyle(.blue)
//
//                                        case .bad:
//                                            Image(systemName: "hand.thumbsdown.fill")
//                                                .resizable()
//                                                .scaledToFit()
//                                                .frame(height: 15)
//                                                .foregroundStyle(.blue)
//
//                                        case .happy:
//                                            Image(systemName: "face.smiling")
//                                                .resizable()
//                                                .scaledToFit()
//                                                .frame(height: 15)
//                                                .foregroundStyle(.yellow)
//
//                                        case .question:
//                                            Image(systemName: "questionmark.circle")
//                                                .resizable()
//                                                .scaledToFit()
//                                                .frame(height: 15)
//                                                .foregroundStyle(.yellow)
//
//                                        default:
//                                            EmptyView()
//                                        }
//                                    }
//                                    Text("\(reaction.timestamp.showableTimestamp()) ago")
//                                        .font(.system(size: 13))
//                                        .foregroundStyle(.white)
//                                }
//                            }
//                        }
//                    }.padding(.horizontal)
//
//                    HStack(alignment: .top) {
//                        ZStack {
//                            Image(systemName: "checkmark.circle")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 20)
//                                .foregroundStyle(myReaction?.reaction == .read ? .green : .white)
//                                .padding()
//                        }
//                            .contentShape(Rectangle())
//                            .highPriorityGesture(TapGesture().onEnded {
//                                if taskStatus != .processing {
//                                    if let email: String = UserDefaultsKeys.userEmail.value() {
//                                        injected.interactorContainer.messageInteractor.setReaction(
//                                            roomid: currentChatroomid, chatid: imagePath!,
//                                            reaction: Reaction(email: email,
//                                                reaction: myReaction?.reaction == .read ? .cancel : .read, timestamp: Date()),
//                                            taskStatus: $taskStatus,
//                                            reactions: $reactions)
//                                            .store(in: &applicationViewModel.cancellableSet)
//                                    }
//                                }
//                            })
//                        ZStack {
//                            Image(systemName: "hand.thumbsup.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 20)
//                                .foregroundStyle(myReaction?.reaction == .good ? .blue : .white)
//                                .padding()
//                        }
//                            .contentShape(Rectangle())
//                            .highPriorityGesture(TapGesture().onEnded {
//                                if taskStatus != .processing {
//                                    if let email: String = UserDefaultsKeys.userEmail.value() {
//                                        injected.interactorContainer.messageInteractor.setReaction(
//                                            roomid: currentChatroomid, chatid: imagePath!,
//                                            reaction: Reaction(email: email,
//                                                reaction: myReaction?.reaction == .good ? .cancel : .good, timestamp: Date()),
//                                            taskStatus: $taskStatus,
//                                            reactions: $reactions)
//                                            .store(in: &applicationViewModel.cancellableSet)
//                                    }
//                                }
//                            })
//                        ZStack {
//                            Image(systemName: "hand.thumbsdown.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 20)
//                                .foregroundStyle(myReaction?.reaction == .bad ? .blue : .white)
//                                .padding()
//                        }
//                            .contentShape(Rectangle())
//                            .highPriorityGesture(TapGesture().onEnded {
//                                if taskStatus != .processing {
//                                    if let email: String = UserDefaultsKeys.userEmail.value() {
//                                        injected.interactorContainer.messageInteractor.setReaction(
//                                            roomid: currentChatroomid, chatid: imagePath!,
//                                            reaction: Reaction(email: email,
//                                                reaction: myReaction?.reaction == .bad ? .cancel : .bad, timestamp: Date()),
//                                            taskStatus: $taskStatus,
//                                            reactions: $reactions)
//                                            .store(in: &applicationViewModel.cancellableSet)
//                                    }
//                                }
//                            })
//                        ZStack {
//                            Image(systemName: "face.smiling")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 20)
//                                .foregroundStyle(myReaction?.reaction == .happy ? .yellow : .white)
//                                .padding()
//                        }
//                            .contentShape(Rectangle())
//                            .highPriorityGesture(TapGesture().onEnded {
//                                if taskStatus != .processing {
//                                    if let email: String = UserDefaultsKeys.userEmail.value() {
//                                        injected.interactorContainer.messageInteractor.setReaction(
//                                            roomid: currentChatroomid, chatid: imagePath!,
//                                            reaction: Reaction(email: email,
//                                                reaction: myReaction?.reaction == .happy ? .cancel : .happy, timestamp: Date()),
//                                            taskStatus: $taskStatus,
//                                            reactions: $reactions)
//                                            .store(in: &applicationViewModel.cancellableSet)
//                                    }
//                                }
//                            })
//                        ZStack {
//                            Image(systemName: "questionmark.circle")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 20)
//                                .foregroundStyle(myReaction?.reaction == .question ? .yellow : .white)
//                                .padding()
//                        }
//                            .contentShape(Rectangle())
//                            .highPriorityGesture(TapGesture().onEnded {
//                                if taskStatus != .processing {
//                                    if let email: String = UserDefaultsKeys.userEmail.value() {
//                                        injected.interactorContainer.messageInteractor.setReaction(
//                                            roomid: currentChatroomid, chatid: imagePath!,
//                                            reaction: Reaction(email: email,
//                                                reaction: myReaction?.reaction == .question ? .cancel : .question, timestamp: Date()),
//                                            taskStatus: $taskStatus,
//                                            reactions: $reactions)
//                                            .store(in: &applicationViewModel.cancellableSet)
//                                    }
//                                }
//                            })
//                    }.padding(.horizontal)
//                }
//            }
//                .safeareaBottomPadding()
//                .padding(.horizontal)
//                .background(BackgroundDarkBlurView())
//        }
//    }
//
//    @ViewBuilder
//    var readusersBubble: some View {
//        let me: String = UserDefaultsKeys.userEmail.value()!
//
//        if let currentPhotoLog {
//            let readusers = currentPhotoLog.readusers.filter({ $0 != me && $0 != currentPhotoLog.writer })
//
//            VStack(alignment: .leading) {
//                if readusers.count > 0 {
//                    HStack(alignment: .center) {
//                        Text("\(readusers.count) people read it")
//                            .font(.system(size: 14))
//                            .bold()
//                        Spacer()
//                    }
//                    ScrollView(showsIndicators: false) {
//                        VStack(alignment: .leading) {
//                            ForEach(currentPhotoLog.readusers.filter({ $0 != me && $0 != currentPhotoLog.writer }), id: \.self) { user in
//                                HStack {
//                                    Text(applicationViewModel.getNickname(user))
//                                        .foregroundStyle(.black)
//                                    Spacer()
//                                }
//                            }
//                        }
//                    }.frame(maxHeight: 75)
//                } else {
//                    Text("Nobody has read it")
//                        .font(.system(size: 14))
//                        .bold()
//                }
//            }
//                .frame(maxHeight: 300)
//                .padding(.horizontal)
//                .padding(.top)
//                .padding(.bottom, 24)
//                .background {
//                SpeechBubblePath()
//                    .fill(Color.white)
////                    .fixedSize(horizontal: true, vertical: true)
//                .shadow(radius: 3)
//            }
//        }
//    }
//
//    @ViewBuilder
//    var downloadView: some View {
//        ZStack(alignment: .center) {
//            Color.black.opacity(0.7)
//            if isCompletePhotoDownload {
//                ZStack(alignment: .center) {
//                    Image(systemName: "checkmark")
//                        .resizable()
//                        .scaledToFit()
//                        .symbolEffect(.bounce, value: photoDownloadCompleteCheckImageAnimation)
//                        .frame(width: UIScreen.main.bounds.width * 0.15)
//                        .foregroundStyle(.white)
//                        .onAppear {
//                        photoDownloadCompleteCheckImageAnimation.toggle()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                            withAnimation(.spring(duration: 0.3)) {
//                                shouldShowDownloadView = false
//                            }
//                        }
//                    }
//                }
//            } else { LoadingDonutView(width: UIScreen.main.bounds.width * 0.2) }
//        }.onDisappear {
//            isCompletePhotoDownload = false
//        }.ignoresSafeArea(.all)
//    }
//
//    @ViewBuilder
//    private var reportPhotoView: some View {
//        ZStack {
//            Color.black.opacity(0.7).onTapGesture {
//                withAnimation(.spring(duration: 0.3)) {
//                    isActiveControlButtons[.report]! = false
//                }
//            }
//            VStack(alignment: .center, spacing: 0) {
//                HStack(alignment: .center) {
//                    Text("Report Photo")
//                        .foregroundStyle(.white)
//                        .bold()
//                        .font(.system(size: 18))
//                    Spacer()
//                }.padding()
//
//                VStack(alignment: .leading, spacing: 7) {
//                    HStack(alignment: .center, spacing: 7) {
//                        Text("""
//                             Do you want to declare that content?
//                             If you report, users who review the content and create the content within 24 hours may be restricted from using the service.
//                             """)
//                            .foregroundStyle(.white)
//                    }
//                }.padding(.vertical)
//
//                HStack(alignment: .bottom) {
//                    Spacer()
//                    Button {
//                        if let email: String = UserDefaultsKeys.userEmail.value() {
//                            injected.interactorContainer.messageInteractor.reportMessage(
//                                email: email, roomid: currentChatroomid, chatid: imagePath!,
//                                shouldShowFullScreenVideoView: $shouldShowFullScreenPhotoView,
//                                chatrooms: $applicationViewModel.userChatrooms)
//                                .store(in: &applicationViewModel.cancellableSet)
//                        }
//                    } label: {
//                        Rectangle()
//                            .foregroundStyle(.blue)
//                            .frame(width: 100, height: 40)
//                            .cornerRadius(9)
//                            .overlay(
//                            Text("Report")
//                                .foregroundStyle(.white)
//                        )
//                    }
//                }
//            }
//                .frame(width: UIScreen.main.bounds.width * 0.8)
//                .padding()
//                .cornerRadius(10.0)
//                .background {
//                RoundedRectangle(cornerRadius: 10.0)
//                    .fill(Color.gray)
//            }
//        }.ignoresSafeArea(.all)
//    }
//}
