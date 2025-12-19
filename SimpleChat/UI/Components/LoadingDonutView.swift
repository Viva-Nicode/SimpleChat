import SwiftUI

struct LoadingDonutView: View {

    @State private var loadingDonutProgress: Double = 0.1
    @State private var loadingDonutDegree: Double = .zero
    @State private var timer: DispatchSourceTimer?
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .trim(from: 0, to: loadingDonutProgress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .butt))
                .rotationEffect(.degrees(loadingDonutDegree))
                .animation(.interactiveSpring(duration: 1), value: loadingDonutProgress)
                .animation(.interactiveSpring(duration: 1), value: loadingDonutDegree)
                .frame(width: width)
        }.onAppear {
            timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
            timer?.schedule(deadline: .now(), repeating: 0.8)
            timer?.setEventHandler {
                loadingDonutProgress = loadingDonutProgress == 0.1 ? 0.9 : 0.1
                loadingDonutDegree += 324
            }
            timer?.resume()
        }.onDisappear {
            timer?.cancel()
            timer = nil
        }
    }
}
