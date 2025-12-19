import Foundation
import UIKit
import AVKit

extension UIImage {

    /// 세로로 긴 사진이라면, 사잔의 너비를 보고 너비가 스크린 너비보다 크다면 스크린 너비와 같게 만들어준다.
    /// 같은 비율로 높이도 줄인다.
    /// 가로로 긴 사진이라면 또는 정사각형이라면, 사진의 높이를 보고 높이가 스크린의 높이보다 크다면 스크린의 높이와 같게 만들어준다.
    /// 같은 비율로 너비도 줄인다.

    func clippingImage() -> UIImage {

        var resizingRatio: CGFloat = .zero

        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        if self.size.width > self.size.height {
            if self.size.height > screenHeight {
                resizingRatio = screenHeight / self.size.height
            } else {
                resizingRatio = 1.0
            }
        } else {
            if self.size.width > screenWidth {
                resizingRatio = screenWidth / self.size.width
            } else {
                resizingRatio = 1.0
            }
        }
        return self.resize(multiplier: resizingRatio)
    }

    private func resize(multiplier: CGFloat) -> UIImage {

        let newWidth = trunc(self.size.width * multiplier) - 1
        let newheight = trunc(self.size.height * multiplier) - 1

        let size = CGSize(width: newWidth, height: newheight)

        let render = UIGraphicsImageRenderer(size: size)
        let renderImage = render.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
        return renderImage
    }

    func rotate(degrees: CGFloat) -> UIImage {

        /// context에 그려질 크기를 구하기 위해서 최종 회전되었을때의 전체 크기 획득
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let affineTransform: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = affineTransform

        /// 회전된 크기
        let rotatedSize: CGSize = rotatedViewBox.frame.size

        /// 회전한 만큼의 크기가 있을때, 필요없는 여백 부분을 제거하는 작업
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        /// 원점을 이미지의 가운데로 평행 이동
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        /// 회전
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        /// 상하 대칭 변환 후 context에 원본 이미지 그림 그리는 작업
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))

        /// 그려진 context로 부터 이미지 획득
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }

    func fixedOrientation() -> UIImage {
        guard let cgImage = self.cgImage else { return self }

        if self.imageOrientation == .up { return self }

        var transform = CGAffineTransform.identity

        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }

        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }

        guard let colorSpace = cgImage.colorSpace else { return self }
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return self }

        context.concatenate(transform)

        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }

        guard let newCGImage = context.makeImage() else { return self }

        return UIImage(cgImage: newCGImage)
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
}

extension AVAsset {
    func generateThumbnail(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let imageGenerator = AVAssetImageGenerator(asset: self)
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let times = [NSValue(time: time)]
            imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { _, image, _, _, _ in
                if let image = image {
                    completion(UIImage(cgImage: image))
                } else {
                    completion(nil)
                }
            })
        }
    }
}
