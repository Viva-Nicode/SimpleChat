//
//  ApplicationPermission.swift
//  SimpleChat
//
//  Created by Nicode . on 8/19/24.
//

import Foundation
import Photos
import SwiftUI

enum PermissionState {
    case denied
    case allowed
    case notDetermined
    case undefined
}
final class Permissions {

    public static func checkLocationAuthorizationStatus() -> PermissionState {
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .allowed

        case .denied, .restricted:
            return .denied

        case .notDetermined:
            return .notDetermined

        @unknown default:
            return .undefined
        }
    }

    public static func checkAudioAuthorizationStatus() -> PermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return .allowed

        case .denied, .restricted:
            return .denied

        case .notDetermined:
            return .notDetermined

        @unknown default:
            return .undefined
        }
    }

    public static func checkCameraAuthorizationStatus() -> PermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return .allowed

        case .denied, .restricted:
            return .denied

        case .notDetermined:
            return .notDetermined

        @unknown default:
            return .undefined
        }
    }

    public static func checkPhotosAuthorizationStatus() -> PermissionState {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return .allowed

        case .restricted:
            print("restricted")
            return .denied

        case .denied:
            print("denied")
            return .denied

        case .notDetermined:
            print("notDetermined")
            return .notDetermined

        @unknown default:
            return .undefined
        }
    }

    public static func requestCameraPermission(completion: @escaping () -> ()) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            completion()
        })
    }

    public static func requestMicrophonePermission(completion: @escaping () -> ()) {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (granted: Bool) in
            completion()
        })
    }

    public static func requestPHPhotoLibraryAuthorization(completion: @escaping () -> Void) {

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { authorizationStatus in
            switch authorizationStatus {
            case .limited:
                completion()
                print("limited authorization granted")
                // 선택한 사진에 한해서 읽기 허용. 쓰기는 무제한 허용
            case .authorized:
                completion()
                print("authorization granted")
                // 그냥 미드 오픈
            default:
                print("Unimplemented")
            }
        }
    }
}
