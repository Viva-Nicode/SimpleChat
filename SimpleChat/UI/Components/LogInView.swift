
import SwiftUI
import Alamofire
import Combine

// 관심사의 분리
// 의존성의 방향
// 내부 레이어는 상위 레이어를 몰라야 한다.
// 이 코드는 어느 레이어의 어느 모듈의 책임인가? 책임 소재 분명히 하기.

class LoginViewModel: ObservableObject, UserInteractionFeedback {
    func setErrorMessage(_ message: LocalizedStringKey) {
        failReason = message
        isError = true
    }
    
    @Published var email = ""
    @Published var password = ""
    @Published var isError = false
    @Published var failReason:LocalizedStringKey = ""

    var getEmail: String { email }
    var getPassword: String { password }
    var getProfileData: Data? { nil }

    func clearTextField() {
        email = ""
        password = ""
    }
}

struct LoginView: View {
    @EnvironmentObject var applicationViewModel: ApplicationViewModel
    @Environment(\.injected) private var injected: DIContainer
    @State private var subscriptions: Set<AnyCancellable> = []
    @Binding var loginSuccessedEmail: String
    @Binding var isLogined: Bool
    @Binding var shouldShowEULAagreePopUpView: Bool
    @StateObject var lvm = LoginViewModel()

    var body: some View {
        VStack {
            Text("Sign In").font(.system(size: 40)).frame(maxWidth: 200, alignment: .leading).padding(.trailing, 120)
            TextField("", text: $lvm.email, prompt: Text("Email")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.3)))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(CommonTextfieldStyle())
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .font(.system(size: 10))
                .limitInputLength(value: $lvm.email, length: 64)
            Spacer().frame(height: 10)
            SecureField("", text: $lvm.password, prompt: Text("Password")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.3)))
                .textFieldStyle(CommonTextfieldStyle())
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .font(.system(size: 22))
                .limitInputLength(value: $lvm.password, length: 32)
            Spacer().frame(height: 30)
            Button(action: signIn) {
                Text("Join") }
                .buttonStyle(CommonButtonStyle(scaledAmount: 0.9))
        }.alert(isPresented: $lvm.isError) {
            Alert(title: Text("login failed"), message: Text(lvm.failReason))
        }
    }

    private func signIn() {
        injected.interactorContainer.userInteractor.signin(lvm, $shouldShowEULAagreePopUpView, $loginSuccessedEmail, $subscriptions)
    }
}
