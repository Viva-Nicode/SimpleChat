import SwiftUI
import WebRTC
import SDWebImageSwiftUI

struct VoiceChatroomView: View {
    @EnvironmentObject var appSettingModel: AppSettingModel
    @StateObject var mediaViewModel: MediaViewModel
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @Environment(\.injected) private var injected: DIContainer

    @Binding var shouldShowVoiceChatroomView: Bool

    @State private var shouldShowVideoView = false
    @State private var isFlowCallTimer = false

    @State private var localCheckAnimation = false
    @State private var remoteCheckAnimation = false
    @State private var showLocalOfferOverlay = true
    @State private var showRemoteOfferOverlay = true

    @State private var beckonCoolTime: Int = .zero
    @State private var beckonCoolTimer: Timer?

    @State private var tapCall = false
    @State private var tapBeckon = false

    var roomid: String
    var audience: String

    init(shouldShowVoiceChatroomView: Binding<Bool>, roomid: String, audience: String) {
        self._shouldShowVoiceChatroomView = shouldShowVoiceChatroomView
        self.roomid = roomid
        self._mediaViewModel = StateObject(wrappedValue: MediaViewModel(roomid: roomid))
        self.audience = audience
    }

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 10) {
                VStack(alignment: .center, spacing: 3) {
                    HStack(alignment: .center) {
                        Circle()
                            .fill(mediaViewModel.signalingConnected ? .green : .gray)
                            .frame(width: 18, height: 18)
                            .shadow(radius: 1)

                        switch mediaViewModel.webRTCStatus {
                        case "new":
                            Text("Waiting for \(applicationViewModel.getNickname(audience))...")
                                .font(.system(size: 16))
                                .bold()
                                .foregroundStyle(appSettingModel.appTheme ? .black : .white)

                        case "checking", "count":
                            Text("Connecting...")
                                .font(.system(size: 16))
                                .bold()
                                .foregroundStyle(appSettingModel.appTheme ? .black : .white)

                        case "completed", "connected":
                            Text("Connected")
                                .font(.system(size: 16))
                                .bold()
                                .foregroundStyle(appSettingModel.appTheme ? .black : .white)

                        case "closed", "failed":
                            Text("Failed")
                                .font(.system(size: 16))
                                .bold()
                                .foregroundStyle(appSettingModel.appTheme ? .black : .white)
                                .onAppear {
                                isFlowCallTimer = false
                                stopBeckonTimer()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { shouldShowVoiceChatroomView = false }
                            }

                        case "disconnected":
                            Text("Disconnected")
                                .font(.system(size: 16))
                                .bold()
                                .foregroundStyle(appSettingModel.appTheme ? .black : .white)
                                .onAppear {
                                isFlowCallTimer = false
                                stopBeckonTimer()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { shouldShowVoiceChatroomView = false }
                            }

                        default:
                            Text("Failed")
                                .font(.system(size: 16))
                                .bold()
                                .foregroundStyle(appSettingModel.appTheme ? .black : .white)
                                .onAppear {
                                isFlowCallTimer = false
                                stopBeckonTimer()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { shouldShowVoiceChatroomView = false }
                            }
                        }
                    }
                    if mediaViewModel.webRTCStatus == "connected" || mediaViewModel.webRTCStatus == "disconnected" {
                        TimerView(isFlowTimer: $isFlowCallTimer)
                    } else {
                        Text(" ")
                    }
                }.padding(.bottom)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 30) {
                        Spacer()
                        if let email: String = UserDefaultsKeys.userEmail.value() {
                            VStack(alignment: .center, spacing: 7) {
                                WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(email)"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width * 0.3, height: geo.size.width * 0.3)
                                    .clipped()
                                    .cornerRadius(geo.size.width * 0.3)
                                    .overlay(alignment: .center) {
                                    if mediaViewModel.hasLocalSdp {
                                        if showLocalOfferOverlay {
                                            Circle()
                                                .foregroundStyle(Color.black.opacity(0.5))
                                                .overlay(alignment: .center) {
                                                Image(systemName: "checkmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: geo.size.width * 0.1)
                                                    .foregroundStyle(Color("OptionalButton3-1"))
                                                    .symbolEffect(.bounce, value: localCheckAnimation)
                                            }.onAppear {
                                                localCheckAnimation.toggle()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                    withAnimation(.spring(duration: 0.3)) {
                                                        showLocalOfferOverlay = false
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        Circle()
                                            .foregroundStyle(Color.black.opacity(0.5))
                                            .overlay(alignment: .center) { LoadingDonutView(width: geo.size.width * 0.15) }
                                    }
                                }

                                Text(UserDefaultsKeys.userNickname.value() ?? email)
                                    .font(.system(size: 19))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .appThemeForegroundColor(appSettingModel.appTheme)
                            }

                            ForEach(mediaViewModel.joinedMembers.filter { $0 != email }, id: \.self) { member in
                                VStack(alignment: .center, spacing: 7) {
                                    WebImage(url: URL(string: "\(serverUrl)/rest/get-thumbnail/\(member)"))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width * 0.3, height: geo.size.width * 0.3)
                                        .clipped()
                                        .cornerRadius(geo.size.width * 0.3)
                                        .overlay(alignment: .center) {
                                        if mediaViewModel.hasRemoteSdp {
                                            if showRemoteOfferOverlay {
                                                Circle()
                                                    .foregroundStyle(Color.black.opacity(0.5))
                                                    .overlay(alignment: .center) {
                                                    Image(systemName: "checkmark")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: geo.size.width * 0.1)
                                                        .foregroundStyle(Color("OptionalButton3-1"))
                                                        .symbolEffect(.bounce, value: remoteCheckAnimation)
                                                }.onAppear {
                                                    remoteCheckAnimation.toggle()
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        withAnimation(.spring(duration: 0.3)) {
                                                            showRemoteOfferOverlay = false
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            Circle()
                                                .foregroundStyle(Color.black.opacity(0.5))
                                                .overlay(alignment: .center) { LoadingDonutView(width: geo.size.width * 0.15) }
                                        }
                                    }
                                    Text(applicationViewModel.userfriends.first { $0.email == member }?.nickname ?? member)
                                        .font(.system(size: 19))
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                        }
                        Spacer()
                    }
                        .frame(width: geo.size.width)
                        .animation(.spring(duration: 0.3), value: mediaViewModel.joinedMembers.count)
                }

                Spacer()

                Grid(verticalSpacing: 19) {
                    GridRow {
                        HStack(alignment: .center, spacing: 25) {
                            Button(action: {
                                mediaViewModel.toggleSpeaker()
                            }) {
                                VStack(alignment: .center, spacing: 6) {
                                    ZStack {
                                        Image(systemName: "speaker.wave.3.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .appThemeForegroundColor(!appSettingModel.appTheme)
                                            .padding(24)
                                    }
                                        .frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                        .contentShape(Circle())
                                        .background {
                                        Circle()
                                            .foregroundStyle(
                                            mediaViewModel.speakerOn ? Color("Gradation background start dark2"):
                                                (appSettingModel.appTheme ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
                                        ).shadow(radius: 5)
                                    }
                                    Text("Speaker")
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                                .disabled(["closed", "disconnected", "failed"].contains(mediaViewModel.webRTCStatus))
                                .opacity(["closed", "disconnected", "failed"].contains(mediaViewModel.webRTCStatus) ? 0.5 : 1)

                            Button(action: {
                                mediaViewModel.toggleMute()
                            }) {
                                VStack(alignment: .center, spacing: 6) {
                                    ZStack {
                                        Image(systemName: "mic.slash.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .appThemeForegroundColor(!appSettingModel.appTheme)
                                            .padding(24)
                                    }.frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                        .contentShape(Circle())
                                        .background {
                                        Circle()
                                            .foregroundStyle(
                                            mediaViewModel.mute ? Color("Gradation background start dark2"):
                                                (appSettingModel.appTheme ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
                                        ).shadow(radius: 5)
                                    }
                                    Text("Mute")
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                                .disabled(["closed", "disconnected", "failed"].contains(mediaViewModel.webRTCStatus))
                                .opacity(["closed", "disconnected", "failed"].contains(mediaViewModel.webRTCStatus) ? 0.5 : 1)

                            ZStack(alignment: .center) {
                                Button(action: {
                                    if let email: String = UserDefaultsKeys.userEmail.value() {
                                        injected.interactorContainer.notificationInteractor.knellVoiceChat(email, audience)
                                            .store(in: &applicationViewModel.cancellableSet)
                                        startBeckonTimer()
                                    }
                                }) {
                                    VStack(alignment: .center, spacing: 6) {
                                        ZStack {
                                            Image(systemName: "person.wave.2.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .appThemeForegroundColor(!appSettingModel.appTheme)
                                                .padding(24)
                                        }
                                            .frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                            .contentShape(Circle())
                                            .background {
                                            Circle()
                                                .foregroundStyle(appSettingModel.appTheme ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
                                                .shadow(radius: 5)
                                        }
                                        Text("beckon")
                                            .appThemeForegroundColor(appSettingModel.appTheme)
                                    }
                                }
                                    .disabled(mediaViewModel.joinedMembers.count >= 2)
                                    .disabled(tapBeckon)
                                    .disabled(mediaViewModel.webRTCStatus == "disconnected")
                                    .opacity(mediaViewModel.joinedMembers.count >= 2 ? 0.5 : 1)
                                    .opacity(tapBeckon ? 0.5 : 1)
                                    .opacity(mediaViewModel.webRTCStatus == "disconnected" ? 0.5 : 1)

                                VStack(alignment: .center, spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .trim(from: 0, to: CGFloat(Double(beckonCoolTime) * 0.1))
                                            .rotation(Angle(degrees: -90))
                                            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .square))
                                            .padding(1)
                                    }.frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                    Text(" ")
                                }
                            }
                        }
                    }

                    GridRow {
                        HStack(alignment: .center, spacing: 25) {
                            Button {
                                shouldShowVideoView = true
                            } label: {
                                VStack(alignment: .center, spacing: 6) {
                                    ZStack(alignment: .center) {
                                        Image(systemName: "video.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .appThemeForegroundColor(!appSettingModel.appTheme)
                                            .padding(24)
                                    }
                                        .frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                        .contentShape(Circle())
                                        .background {
                                        Circle()
                                            .foregroundStyle(appSettingModel.appTheme ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
                                            .shadow(radius: 5)
                                    }
                                    Text("Video")
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                                .disabled(mediaViewModel.webRTCStatus != "connected")
                                .opacity(mediaViewModel.webRTCStatus != "connected" ? 0.5 : 1)

                            Button {
                                if mediaViewModel.hasRemoteSdp {
                                    mediaViewModel.answer()
                                } else {
                                    mediaViewModel.offer()
                                }
                                tapCall = true
                            } label: {
                                VStack(alignment: .center, spacing: 6) {
                                    ZStack {
                                        Image(systemName: "phone.fill.badge.checkmark")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.white)
                                            .padding(24)
                                    }
                                        .frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                        .contentShape(Circle())
                                        .background {
                                        Circle()
                                            .foregroundStyle(.green.opacity(0.8))
                                            .shadow(radius: 5)
                                    }
                                    Text("Connect")
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                                .disabled(!mediaViewModel.signalingConnected || tapCall)
                                .disabled(mediaViewModel.joinedMembers.count <= 1)
                                .opacity(!mediaViewModel.signalingConnected || tapCall ? 0.5 : 1)
                                .opacity(mediaViewModel.joinedMembers.count <= 1 ? 0.5 : 1)

                            Button {
                                shouldShowVoiceChatroomView = false
                            } label: {
                                VStack(alignment: .center, spacing: 6) {
                                    ZStack {
                                        Image(systemName: "phone.down.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.white)
                                            .padding(24)
                                    }
                                        .frame(width: geo.size.width * 0.2, height: geo.size.width * 0.2)
                                        .contentShape(Circle())
                                        .background {
                                        Circle()
                                            .foregroundStyle(.red.opacity(0.8))
                                            .shadow(radius: 5)
                                    }
                                    Text("End")
                                        .appThemeForegroundColor(appSettingModel.appTheme)
                                }
                            }
                        }
                    }
                }.padding(.bottom, geo.size.height * 0.1)
            }.padding(.top, geo.size.height * 0.15)
                .onAppear {
                mediaViewModel.chatroomid = roomid
                mediaViewModel.connectSignalClient()
            }.onDisappear {
                isFlowCallTimer = false
                stopBeckonTimer()
                mediaViewModel.signalClient.disconnect()
                configureAudioSession()
            }
        }
            .fullScreenCover(isPresented: $shouldShowVideoView) { VideoView(webRTCClient: mediaViewModel.webRTCClient) }
            .background {
            if appSettingModel.appTheme {
                BackgroundBlurView().ignoresSafeArea(.all)
            } else {
                BackgroundDarkBlurView().ignoresSafeArea(.all)
            }
        }
    }

    private func startBeckonTimer() {
        tapBeckon = true
        beckonCoolTime = .zero
        if beckonCoolTimer == nil {
            beckonCoolTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
                if beckonCoolTime == 10 {
                    timer.invalidate()
                    self.beckonCoolTimer = nil
                    tapBeckon = false
                    beckonCoolTime = .zero
                } else {
                    withAnimation(.linear(duration: 1.0)) { beckonCoolTime += 1 }
                }
            })
        }
    }

    private func stopBeckonTimer() {
        if let timer = self.beckonCoolTimer {
            timer.invalidate()
            self.beckonCoolTimer = nil
        }
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
}

struct TimerView: View {
    @EnvironmentObject var appSettingModel: AppSettingModel
    @Binding var isFlowTimer: Bool
    @State private var callTimer = 0
    @State private var timer: Timer?

    var body: some View {
        Text(formatTime)
            .appThemeForegroundColor(appSettingModel.appTheme)
            .onAppear { isFlowTimer = true }
            .onChange(of: isFlowTimer) { _, nv in
            if nv {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }

    private func startTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
                callTimer += 1
            })
        }
    }

    private func stopTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    private var formatTime: String {
        let hours = callTimer / 3600
        let minutes = (callTimer % 3600) / 60
        let seconds = callTimer % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

