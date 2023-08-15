import SwiftUI

// SwiftUI에서 UIkit의 UIViewController를 사용하기위해 UIViewControllerRepresentable 프로토콜을 준수하는 구조체를 생성한다.
struct ImagePicker: UIViewControllerRepresentable {
    
    // 사용하고자 하는 UIkit의 컨트롤러 타입을 지정해준다.
    // 이는 UIViewControllerRepresentable protocol에 의해 준수해주어야 하는 조건이다.
    typealias UIViewControllerType = UIImagePickerController
    
    // 선택된 이미지를 저장하기 위한 변수이다.
    @Binding var image: UIImage?
    
    // SwiftUI에서 사용하고자 하는 컨트롤러이다.
    private let controller = UIImagePickerController()
    
    // 이는 UIViewControllerRepresentable protocol에 의해 필수로 구현해주어야 하는 함수이다.
    // 인자는 Context인데 이는 typealias Context = UIViewControllerRepresentableContext<Self>이다.
    // 사용하고자 하는 컨트롤러의 타입을 반환한다.
    // 함수 바디에는 일반적으로 컨트롤러 객체를 생성하고 초기화 하거나, delegate를 설정하는등의 로직이 기술된다.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        // delegate란 controller 즉 UIImagePickerController의 동작을 다른 객체에게 위임한다.(떠넘긴다.)
        // 아래 경우 coordinator객체에게 위임하는데, UIImagePIckerController의 동작을 위임 받기위해서 Coordinator객체는
        // UIImagePickerControllerDelegate, UINavigationControllerDelegate protocol을 준수하고 있다.
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context){}
    
    // 어떤 Coordinator에게 동작을 위임하고자 할 때, 해당 coordinator객체를 생성하고 반환하는 함수이다.
    // 이 함수도 UIViewControllerRepresentable protocol에 의해 구현해주어야 한다.
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    // 컨트롤러의 동작을 위임받기 위해 UIImagePickerControllerDelegate, UINavigationControllerDelegate를 준수한다.
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
        let parent: ImagePicker
        
        init(parent: ImagePicker){
            self.parent = parent
        }
        
        // 이미지 피커 컨트롤러에서 미디어 선택이 완료되었을 때 호출된다.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info : [UIImagePickerController.InfoKey : Any]){
            parent.image = info[.originalImage] as? UIImage
            // 애니메이션 효과를 주며 이전 화면으로 돌아간다.
            picker.dismiss(animated: true)
        }
    }
}
