import SwiftUI
import AVKit
import Foundation

struct VideoPlayerView: UIViewControllerRepresentable {

    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
