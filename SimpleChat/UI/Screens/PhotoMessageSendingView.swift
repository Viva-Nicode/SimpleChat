//
//  PhotoMessageSendingView.swift
//  SimpleChat
//
//  Created by Nicode . on 9/24/24.
//

import SwiftUI
import PhotosUI


struct PhotoMessageSendingView: View {

    @Environment(\.injected) private var injected: DIContainer
    @EnvironmentObject var appSettingModel: AppSettingModel
    @EnvironmentObject var applicationViewModel: ApplicationViewModel

    @State private var photoMessageSendDragOffset = CGFloat.zero
    @State private var photoRotateDegree = Double.zero

    @State private var rotateScale: Double = 1
    @State private var photoSize: CGSize = .zero

    @Binding var shouldShowDidSendPhotoFullScreenView: Bool
    @Binding var messagePickerUIImage: UIImage?
    @Binding var messagePhotosPickerItem: PhotosPickerItem?

    //MARK: usage view properties
    @State private var shouldShowUsageView = false
    @State private var usageViewArrowAnimation = false

    let currentChatroomid: String
    let sendPhotoMessage: () -> ()

    var body: some View {
        ZStack {
            BackgroundBlurView()
            if let pickedUIImage = messagePickerUIImage {
                Image(uiImage: pickedUIImage)
                    .resizable()
                    .cornerRadius(10)
                    .padding()
                    .shadow(color: appSettingModel.appTheme ? .black.opacity(0.4) : .white, radius: 3)
                    .scaledToFit()
                    .onTapGesture {
                    withAnimation(.linear(duration: 0.2)) {
                        let photoRatio = photoSize.width / photoSize.height
                        let minimumPhotoScale = UIScreen.main.bounds.width / photoSize.height
                        let maximumPhotoScale = (UIScreen.main.bounds.height - 40) / photoSize.width

                        rotateScale = rotateScale == 1 ? photoRatio < 1 ? max(minimumPhotoScale, photoRatio) : min(maximumPhotoScale, photoRatio): 1
                        photoRotateDegree += 90
                    }
                }.background {
                    GeometryReader { geo in
                        ZStack { Color.clear }.onAppear { photoSize = geo.size }
                    }
                }.overlay { photoMessageSendDragOffset >= 200 ?
                    GeometryReader { geo in
                        ZStack {
                            Color.red.opacity(0.55)
                            Image(systemName: "trash.circle")
                                .resizable()
                                .rotationEffect(Angle(degrees: -photoRotateDegree))
                                .scaledToFit()
                                .foregroundStyle(.white)
                                .frame(width: geo.size.width >= geo.size.height ? geo.size.height * 0.3 : nil,
                                height: geo.size.width < geo.size.height ? geo.size.width * 0.3 : nil)
                                .padding()
                        }.cornerRadius(10).padding()
                    }: nil
                }.overlay { photoMessageSendDragOffset <= -200 ?
                    GeometryReader { geo in
                        ZStack {
                            Color.blue.opacity(0.55)
                            Image(systemName: "paperplane.circle")
                                .resizable()
                                .rotationEffect(Angle(degrees: -photoRotateDegree))
                                .scaledToFit()
                                .foregroundStyle(.white)
                                .frame(width: geo.size.width >= geo.size.height ? geo.size.height * 0.3 : nil,
                                height: geo.size.width < geo.size.height ? geo.size.width * 0.3 : nil)
                                .padding()
                        }.cornerRadius(10).padding()
                    }: nil
                }
                    .rotationEffect(Angle(degrees: photoRotateDegree))
                    .offset(y: photoMessageSendDragOffset)
                    .scaleEffect(rotateScale)
                    .scaleEffect(1 - abs(photoMessageSendDragOffset) / UIScreen.main.bounds.height)
                    .opacity(CGFloat(1 - abs(photoMessageSendDragOffset) / UIScreen.main.bounds.height))
                    .gesture(DragGesture(minimumDistance: .zero, coordinateSpace: .global)
                        .onChanged { v in
                        photoMessageSendDragOffset = v.translation.height
                    }.onEnded { v in
                        if v.translation.height >= 200 {
                            withAnimation(.spring(duration: 0.5)) {
                                photoMessageSendDragOffset += UIScreen.main.bounds.height
                            } completion: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    shouldShowDidSendPhotoFullScreenView = false
                                }
                            }
                        } else if v.translation.height <= -200 {
                            withAnimation(.spring(duration: 0.5)) {
                                photoMessageSendDragOffset -= UIScreen.main.bounds.height
                            } completion: {
                                withAnimation(.spring(duration: 0.3)) {
                                    messagePickerUIImage = messagePickerUIImage?.rotate(degrees: photoRotateDegree.truncatingRemainder(dividingBy: 360))
                                    sendPhotoMessage()
                                }
                            }
                        } else {
                            withAnimation(.spring(duration: 0.3)) {
                                photoMessageSendDragOffset = .zero
                            }
                        }
                    }
                )
            } else { Text("photo load fail.\nplease select other photo.\nso sorry...").appThemeForegroundColor(appSettingModel.appTheme) }
        }
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay { shouldShowUsageView ?
            ZStack {
                Color.black
                VStack(alignment: .center, spacing: 10) {
                    Spacer()
                    Image(systemName: "arrowshape.up")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.2)
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: usageViewArrowAnimation)
                    Text("Send")
                        .foregroundStyle(.white)
                        .font(.title)
                    Spacer()
                    Text("Cancel")
                        .foregroundStyle(.white)
                        .font(.title)
                    Image(systemName: "arrowshape.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.2)
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: usageViewArrowAnimation)
                    Spacer()
                }
            }
                .opacity(0.7)
                .ignoresSafeArea(.container, edges: .bottom): nil }
            .onAppear {
            withAnimation(.spring(duration: 0.3)) {
                shouldShowUsageView = true
            }
            usageViewArrowAnimation.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.spring(duration: 0.3)) {
                    shouldShowUsageView = false
                }
            }
        }.onDisappear {
            messagePickerUIImage = nil
            messagePhotosPickerItem = nil
        }
    }
}

