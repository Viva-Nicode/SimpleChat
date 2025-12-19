import Foundation
import Combine
import PhotosUI
import SwiftUI

extension Just where Output == Void {
    static func withErrorType<E>(_ errorType: E.Type) -> AnyPublisher<Void, E> {
        return Just(())
            .setFailureType(to: E.self)
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func asyncMap<T>(_ transform: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

extension Publisher where Output: Sequence {
    func realFlattenMap<T>(_ transform: @escaping (Int, Self.Output.Element) -> T) -> Publishers.Map<Self, [T]> {
        self.map { value in
            value.enumerated().map { i, v in
                transform(i, v)
            }
        }
    }
}

extension String {

    func highlightingText(_ targetKeyword: String, _ appthemeState: Bool) -> some View {
        if let range = self.range(of: targetKeyword) {
            return AnyView(
                HStack(alignment: .center, spacing: 0) {
                    Text(self[..<range.lowerBound])
                        .font(.system(size: 17, weight: .bold))
                        .appThemeForegroundColor(appthemeState)
                    Text(self[range])
                        .font(.system(size: 17, weight: .bold))
                        .appThemeForegroundColor(appthemeState)
                        .background {
                        if appthemeState {
                            Color.yellow
                                .cornerRadius(5)
                        } else {
                            Color.indigo
                                .cornerRadius(5)
                        }
                    }
                    Text(self[range.upperBound...])
                        .font(.system(size: 17, weight: .bold))
                        .appThemeForegroundColor(appthemeState)
                }.background(TransparentBackgroundView())
            )
        } else {
            return AnyView(
                HStack(alignment: .center, spacing: 0) {
                    Text(self)
                        .font(.system(size: 17, weight: .bold))
                        .appThemeForegroundColor(appthemeState)
                }.background(TransparentBackgroundView())
            )
        }
    }

    func highlightingEmailText(_ targetKeyword: String, _ appthemeState: Bool) -> some View {
        if let range = self.range(of: targetKeyword) {
            return AnyView(
                HStack(alignment: .center, spacing: 0) {
                    Text(self[..<range.lowerBound])
                        .font(.system(size: 12))
                    Text(self[range])
                        .font(.system(size: 12))
                        .background {
                        if appthemeState {
                            Color.yellow
                                .cornerRadius(5)
                        } else {
                            Color.indigo
                                .cornerRadius(5)
                        }
                    }
                    Text(self[range.upperBound...])
                        .font(.system(size: 12))
                }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
            )
        } else {
            return AnyView(
                HStack(alignment: .center, spacing: 0) {
                    Text(self)
                        .font(.system(size: 12))
                }.padding(.horizontal, 5)
                    .padding(.vertical, 2)
            )
        }
    }

    func stringToData() -> Data? {
        return self.data(using: .utf8)
    }

    func stringToDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: self)
    }
}

extension PhotosPickerItem {

    func transformToJpegdataWithClosure(completeHandler: @escaping (Data) -> Void, errorHandler: @escaping () -> Void) {
        self.loadTransferable(type: Data.self) { result in
            switch result {
            case let .success(data):
                if let unwrapedData = data {
                    if let uiImage = UIImage(data: unwrapedData) {
                        if let imagedata = uiImage.jpegData(compressionQuality: 1.0) {
                            completeHandler(imagedata)
                        } else { errorHandler() }
                    } else { errorHandler() }
                } else { errorHandler() }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func transformToJpegdata() async -> Data? {
        if let data = try? await self.loadTransferable(type: Data.self) {
            if let uiImage = UIImage(data: data) {
                if let imagedata = uiImage.jpegData(compressionQuality: 1.0) {
                    return imagedata
                }
            }
        }
        return nil
    }
}

extension Date {
    func dateToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }

    func showableTimestamp() -> String {
        let secondsElaped = Int(Date().timeIntervalSince(self))

        let timeConvertConsts: [Int] = [31536000, 2592000, 86400, 3600, 60, 1]
        let timeConvertUnits: [String] = [
            LocalizationString.year,
            LocalizationString.month,
            LocalizationString.day,
            LocalizationString.hour,
            LocalizationString.minutes,
            LocalizationString.seconds
        ]

        for idx in 0..<timeConvertConsts.count {
            if secondsElaped / timeConvertConsts[idx] > 0 {
                return String(secondsElaped / timeConvertConsts[idx]) + timeConvertUnits[idx]
            }
        }
        return LocalizationString.now
    }
}

extension View {

    func appThemeBackgroundColor (_ appTheme: Bool) -> some View {
        self.background(appTheme ? Color.white : Color.black)
    }

    func appThemeForegroundColor (_ appTheme: Bool) -> some View {
        self.foregroundStyle(appTheme ? Color.black : Color.white)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func safeareaBottomPadding() -> some View {
        self.padding(.bottom, UIApplication
                .shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? bottomSafeareaHeight)
    }

    var bottomSafeareaHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 40 }
        return windowScene.keyWindow?.safeAreaInsets.bottom ?? 40
    }

    @ViewBuilder
    func safeareaTopPadding() -> some View {
        self.padding(.top, UIApplication
                .shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.safeAreaInsets.top ?? statusBarHeight)
    }

    var statusBarHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 40 }
        return windowScene.statusBarManager?.statusBarFrame.height ?? 40
    }
}

class KeyboardResponder: ObservableObject {
    private var _center: NotificationCenter
    @Published var currentHeight: CGFloat = 0
    var keyboardDuration: TimeInterval = 0

    init(center: NotificationCenter = .default) {
        _center = center
        _center.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        _center.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        _center.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

            guard let duration: TimeInterval = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
            keyboardDuration = duration
            currentHeight = keyboardSize.height
        }
    }

    @objc func keyBoardWillHide(notification: Notification) {
        guard let duration: TimeInterval = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        keyboardDuration = duration
        currentHeight = 0
    }
}
