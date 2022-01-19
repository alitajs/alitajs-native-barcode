import Foundation
import Capacitor
import AVFoundation


@objc(BarcodeScannerPlugin)
public class BarcodeScannerPlugin: CAPPlugin {
    
    @objc func checkPermission(_ call: CAPPluginCall) {
        let force = call.getBool("force") ?? false
        
        var savedResultObject = PluginCallResultData()
        
        DispatchQueue.main.async {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                savedResultObject["granted"] = true
            case .denied:
                savedResultObject["denied"] = true
            case .notDetermined:
                savedResultObject["neverAsked"] = true
            case .restricted:
                savedResultObject["restricted"] = true
            @unknown default:
                savedResultObject["unknown"] = true
            }
            
            if (force && savedResultObject["neverAsked"] != nil) {
                savedResultObject["asked"] = true
                
                AVCaptureDevice.requestAccess(for: .video) { authorized in
                    if (authorized) {
                        savedResultObject["granted"] = true
                    } else {
                        savedResultObject["denied"] = true
                    }
                    call.resolve(savedResultObject)
                }
            } else {
                call.resolve(savedResultObject)
            }
        }
    }
    
    @objc func openAppSettings(_ call: CAPPluginCall) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl) { success in
                    call.resolve()
                }
            }
        }
    }
    
    @objc func scanCode(_ call: CAPPluginCall) {
        let authorization = SGAuthorization()
        authorization.openLog = true
        authorization.avAuthorizationBlock { [weak self] (authorization, status) in
            if (status == SGAuthorizationStatusSuccess) {
                DispatchQueue.main.async {
                    let barcodeVC = BarcodeVC()
                    barcodeVC.completion = { result, isCancel in
                        if (!isCancel) {
                            var resultData = PluginCallResultData()
                            resultData["hasContent"] = result == nil ? false : true
                            resultData["content"] = result
                            call.resolve(resultData)
                        } else {
                            call.reject("取消", "cancel")
                        }
                        self?.bridge?.dismissVC(animated: true, completion: nil)
                    }
                    self?.bridge?.presentVC(barcodeVC, animated: true, completion: nil)
                }
            } else {
                call.reject("没有摄像头权限", "cameraDenied")
            }
        }
    }
}
