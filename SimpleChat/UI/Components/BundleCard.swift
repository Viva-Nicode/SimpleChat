import SwiftUI
import Combine
import SDWebImageSwiftUI

struct BundleCard: View {
    var bundle: ChatroomBundle
    var geo: GeometryProxy
    @State private var filpBackground = false
    @State private var isFlipped = false
    @State private var subscriptions: Set<AnyCancellable> = []
    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @Environment(\.injected) private var injected: DIContainer
    let namespace: Namespace.ID

    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            ZStack {
                VStack {
                    HStack(alignment: .center) {
                        Text("Bundle")
                            .font(.system(size: 11.3))
                            .foregroundStyle(Color.purple)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.purple)
                        )
                        Text("\(bundle.bundleChatroomList.count)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.purple)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isFlipped = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    filpBackground = true
                                }
                            }
                        } label: {
                            ZStack {
                                Color.clear
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.purple)
                            }
                                .frame(width: geo.size.width * 0.5 * 0.15)
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                        }
                    }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 7)
                        .padding(.horizontal, 8)

                    ZStack(alignment: .topTrailing) {
                        if let bundleURL = bundle.bundleProfileURL {
                            WebImage(url: URL(string: bundleURL))
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width * 0.5 * 0.5, height: geo.size.width * 0.5 * 0.5)
                                .clipped()
                                .cornerRadius(19)
                                .shadow(radius: 2)
                                .padding(.top, 8)
                                .matchedGeometryEffect(id: "\(bundle.bundleID)/photo", in: namespace)
                        } else {
                            ZStack {
                                Image(systemName: "tray.full")
                                    .resizable()
                                    .foregroundStyle(.blue.opacity(0.8))
                                    .padding()
                                    .background { Color.white.cornerRadius(19).shadow(radius: 2) }
                                    .matchedGeometryEffect(id: "\(bundle.bundleID)/photo", in: namespace)
                            }
                                .frame(width: geo.size.width * 0.5 * 0.5, height: geo.size.width * 0.5 * 0.5)
                                .padding(.top, 8)
                        }

                        if let count = applicationViewModel.bundleUnreadCount(self.bundle.bundleID) {
                            if count != .zero {
                                Text("\(count)")
                                    .foregroundStyle(Color("pastel blue foreground"))
                                    .padding(.horizontal, 5)
                                    .font(.system(size: 16, weight: .semibold))
                                    .background {
                                    RoundedRectangle(cornerRadius: .infinity)
                                        .foregroundStyle(Color("pastel blue"))
                                }
                            }
                        }
                    }

                    Text(bundle.bundleName)
                        .appThemeForegroundColor(appSettingModel.appTheme)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                        .padding(.horizontal)
                        .matchedGeometryEffect(id: "\(bundle.bundleID)/name", in: namespace)
                        .minimumScaleFactor(0.4)

                    VStack(alignment: .center) {
                        Spacer()
                        Text(verbatim: applicationViewModel.bundleRecentMessage(self.bundle.bundleID))
                            .font(.system(size: 13))
                            .appThemeForegroundColor(appSettingModel.appTheme)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }.padding(9)

                    HStack(alignment: .center) {
                        if let timeStamp = applicationViewModel.bundleRecentShowableDate(self.bundle.bundleID) {
                            Text("\(timeStamp) ago")
                                .font(.system(size: 14, weight: .semibold))
                                .appThemeForegroundColor(appSettingModel.appTheme)
                        }
                        Spacer()
                    }
                        .padding(.leading)
                        .padding(.bottom)
                }.opacity(filpBackground ? 0.0001 : 1)

                VStack {
                    HStack(alignment: .center) {
                        Text("Bundle")
                            .font(.system(size: 11.3))
                            .foregroundStyle(Color.purple)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.purple)
                        ).hidden()
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isFlipped = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    filpBackground = false
                                }
                            }
                        } label: {
                            ZStack {
                                Color.clear
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.purple)
                            }
                                .frame(width: geo.size.width * 0.5 * 0.15)
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                        }
                    }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 7)
                        .padding(.horizontal, 8)
                    Button {
                        injected.interactorContainer.chatroomInteractor.removeChatroomBundle(bundle: self.bundle,
                            chatroomBundles: $applicationViewModel.userChatroomBundles).store(in: &subscriptions)
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "trash")
                                .resizable()
                                .foregroundStyle(.white)
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 15.5)
                            Text("Remove")
                                .font(.system(size: 15.5))
                                .foregroundStyle(.white)
                        }
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background {
                            RoundedRectangle(cornerRadius: .infinity)
                                .foregroundStyle(Color("pastel red foreground"))
                        }
                    }
                    Spacer()
                }
                    .opacity(filpBackground ? 1 : 0.0001)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }.background {
            if appSettingModel.appTheme {
                if filpBackground {
                    Color("pastel yellow").cornerRadius(10)
                } else {
                    BackgroundBlurView().cornerRadius(10)
                }
            } else {
                if filpBackground {
                    Color("pastel yellow").cornerRadius(10)
                } else {
                    BackgroundDarkBlurView().cornerRadius(10)
                }
            }
        }.rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .gesture(
            DragGesture()
                .onEnded({ value in
                if isFlipped {
                    if value.translation.width < geo.size.width * 0.5 * -0.2 {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isFlipped = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                filpBackground = false
                            }
                        }
                    }
                } else {
                    if value.translation.width > geo.size.width * 0.5 * 0.2 {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isFlipped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                filpBackground = true
                            }
                        }
                    }
                }
            })
        )
    }
}
