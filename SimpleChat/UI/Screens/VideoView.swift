//
//  VideoView.swift
//  SimpleChat
//
//  Created by Nicode . on 8/16/24.
//

import Foundation
import WebRTC
import UIKit
import SwiftUI

struct VideoView: View {
    @ObservedObject private var viewModel: VideoViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var localVideoViewXCoordinate: CGFloat = .zero
    @State private var localVideoViewYCoordinate: CGFloat = .zero
    @State private var localVideoViewXLastCoordinate: CGFloat = .zero
    @State private var localVideoViewYLastCoordinate: CGFloat = .zero

    init(webRTCClient: WebRTCClient) {
        self.viewModel = VideoViewModel(webRTCClient: webRTCClient)
    }

    var body: some View {
        ZStack {
            RemoteVideoView(renderer: viewModel.remoteRenderer)
                .edgesIgnoringSafeArea(.all)
                .onAppear { viewModel.startRendering() }
                .onDisappear { viewModel.stopRendering() }

            VStack {
                HStack {
                    Spacer()
                    LocalVideoView(renderer: viewModel.localRenderer)
                        .frame(width: 150, height: 200)
                        .cornerRadius(8)
                        .padding()
                        .offset(x: localVideoViewXCoordinate, y: localVideoViewYCoordinate)
                        .gesture(
                        DragGesture()
                            .onChanged { offset in
                            localVideoViewXCoordinate = offset.translation.width + localVideoViewXLastCoordinate
                            localVideoViewYCoordinate = offset.translation.height + localVideoViewYLastCoordinate
                        }.onEnded { offset in
                            localVideoViewXLastCoordinate = localVideoViewXCoordinate
                            localVideoViewYLastCoordinate = localVideoViewYCoordinate
                        }
                    )
                }
                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Back")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
            }
        }
    }
}

class VideoViewModel: ObservableObject {
    private let webRTCClient: WebRTCClient
    var localRenderer: RTCMTLVideoView?
    var remoteRenderer: RTCMTLVideoView?

    init(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
        startRendering()
    }

    func startRendering() {
        self.localRenderer = RTCMTLVideoView(frame: .zero)
        self.remoteRenderer = RTCMTLVideoView(frame: .zero)

        localRenderer?.videoContentMode = .scaleAspectFill
        remoteRenderer?.videoContentMode = .scaleAspectFill

        if let localRenderer = localRenderer {
            webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        }

        if let remoteRenderer = remoteRenderer {
            webRTCClient.renderRemoteVideo(to: remoteRenderer)
        }
    }

    func stopRendering() { }
}

struct LocalVideoView: UIViewRepresentable {
    var renderer: RTCMTLVideoView?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if let renderer = renderer {
            view.addSubview(renderer)
            renderer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                renderer.topAnchor.constraint(equalTo: view.topAnchor),
                renderer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                renderer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                renderer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct RemoteVideoView: UIViewRepresentable {
    var renderer: RTCMTLVideoView?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if let renderer = renderer {
            view.addSubview(renderer)
            renderer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                renderer.topAnchor.constraint(equalTo: view.topAnchor),
                renderer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                renderer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                renderer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}
