
import SwiftUI
import AVKit

struct VideoMessageSendingView: View {

    @Environment(\.injected) private var injected: DIContainer
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var messageSendingViewModel: MessageSendingViewModel

    @State private var VideoConvertingAnimate = false
    @State private var willSendingVideoPlayer: AVPlayer?

    @FocusState private var isFocused: Bool

    let videoConvertState: VideoConvertState
    let roomid: String

    var body: some View {
        ZStack {
            Color.black.onTapGesture { isFocused = false }
            VStack(alignment: .center) {
                switch videoConvertState {
                case .unknown:
                    HStack(alignment: .center) {
                        Spacer()
                        Image(systemName: "video.bubble")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                            .foregroundStyle(.blue, .yellow)
                        Spacer()
                    }
                case let .loading(state):
                    HStack(alignment: .center) {
                        Spacer()
                        VStack(alignment: .center, spacing: 7) {
                            Image(systemName: "video.bubble")
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width * 0.3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.blue, .yellow)
                                .symbolEffect(.bounce, options: .repeating, value: VideoConvertingAnimate)
                                .onAppear { VideoConvertingAnimate.toggle() }
                            Text(state)
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                case .loaded(let movie):
                    if let willSendingVideoPlayer {
                        VideoPlayer(player: willSendingVideoPlayer)
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width)
                        VStack(alignment: .center) {
                            TextField("", text: $messageSendingViewModel.videoTitleText, prompt: Text("title").foregroundStyle(.gray), axis: .vertical)
                                .fontDesign(.rounded)
                                .limitInputLength(value: $messageSendingViewModel.videoTitleText, length: 32)
                                .multilineTextAlignment(.leading)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .lineLimit(3)
                                .focused($isFocused)
                                .textFieldStyle(WhiteLineTextfieldStyle())
                            HStack(alignment: .center) {
                                Spacer()
                                Text("\(messageSendingViewModel.videoTitleText.count) / 32")
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                            }
                        }.padding()
                        Spacer()
                    } else { Text("").onAppear { willSendingVideoPlayer = AVPlayer(url: movie.url) } }
                case .failed:
                    Text("Import failed")
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(duration: 0.3)) {
                            messageSendingViewModel.shouldShowDidSendVideoFullScreenView = false
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "trash.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width * 0.06)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .padding(.leading)
                            Text("Cancel")
                                .foregroundStyle(.white)
                                .padding(.trailing)
                        }
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 2))
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    switch videoConvertState {
                    case .loaded:
                        Button {
                            if let email: String = UserDefaultsKeys.userEmail.value() {
                                if let videoData = messageSendingViewModel.messageVideoData {
                                    if let thumbnailData = messageSendingViewModel.messageVideoThumbnailData {
                                        withAnimation(.spring(duration: 0.3)) {
                                            injected.interactorContainer.messageInteractor.sendVideoMessage(
                                                sender: email, roomid: roomid,
                                                title: messageSendingViewModel.videoTitleText.trimmingCharacters(in: .whitespacesAndNewlines),
                                                videoData: videoData, thumbnail: thumbnailData, chatrooms: $applicationViewModel.userChatrooms,
                                                vm: messageSendingViewModel).store(in: &applicationViewModel.cancellableSet)
//                                                .replacingOccurrences(of: "\n", with: "")
//                                                .replacingOccurrences(of: "\r", with: "")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: "paperplane.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: UIScreen.main.bounds.width * 0.06)
                                    .padding(.vertical, 8)
                                    .padding(.leading)
                                    .foregroundStyle(.white)
                                Text("Send")
                                    .foregroundStyle(.white)
                                    .padding(.trailing)
                            }
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 2))
                                .contentShape(Rectangle())
                        }
                        Spacer()
                    default:
                        EmptyView()
                    }
                }
                    .padding(.top, self.bottomSafeareaHeight)
                    .safeareaBottomPadding()
            }
        }.onDisappear {
            messageSendingViewModel.messagePhotosPickerItem = nil
            messageSendingViewModel.messageVideoData = nil
            messageSendingViewModel.videoTitleText = ""
            willSendingVideoPlayer = nil
        }.alert(isPresented: $messageSendingViewModel.shouldShowVideoSendingViewAlert) {
            let yes = Alert.Button.default(Text("OK")) {
                withAnimation(.spring(duration: 0.3)) {
                    messageSendingViewModel.shouldShowDidSendVideoFullScreenView = false
                }
            }

            switch messageSendingViewModel.videoSendingViewAlert {
            case .tooBiggerSizeVideo:
                return Alert(title: Text("Video Send Fail"),
                    message: Text("The video size cannot exceed 200 MB."), dismissButton: yes)
            case .videoConvertingError:
                return Alert(title: Text("Video Send Fail"),
                    message: Text("The video cannot be converted. Please select a different video."), dismissButton: yes)
            case .unsupportedVideoFormat:
                return Alert(title: Text("Video Send Fail"),
                    message: Text("The video format is not supported. Please select a different video."), dismissButton: yes)
            }
        }.ignoresSafeArea(.container, edges: .bottom)
    }
}
