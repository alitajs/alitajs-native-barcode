import Foundation
import Capacitor
import AVFoundation


@objc(BarcodeScannerPlugin)
public class BarcodeScannerPlugin: CAPPlugin {
    private let implementation = BarcodeScanner()
    var savedCall: CAPPluginCall? = nil
    var originalBackgroundColor = UIColor.white
    
    public override func load() {
        self.implementation.createCameraView()
        self.implementation.completion = { result in
            var jsObject = PluginCallResultData()
            
            if (result != nil) {
                jsObject["hasContent"] = true
                jsObject["content"] = result
            } else {
                jsObject["hasContent"] = false
            }
            
            if (self.savedCall != nil) {
                self.savedCall?.resolve(jsObject)
                self.savedCall = nil
            }
            
            self.destroy()
        };
    }
    
    private func hideBackground() {
        DispatchQueue.main.async {
            self.bridge?.webView!.isOpaque = false
            self.originalBackgroundColor = self.bridge?.webView!.backgroundColor ?? UIColor.white
            self.bridge?.webView!.backgroundColor = UIColor.clear
            self.bridge?.webView?.scrollView.backgroundColor = UIColor.clear
            
            let javascript = "document.documentElement.style.backgroundColor = 'transparent'"
            
            self.bridge?.webView!.evaluateJavaScript(javascript)
            self.bridge?.webView?.superview?.bringSubviewToFront(self.implementation.cameraView)
        }
    }
    
    private func showBackground() {
        DispatchQueue.main.async {
            let javascript = "document.documentElement.style.backgroundColor = ''"
            
            self.bridge?.webView!.evaluateJavaScript(javascript, completionHandler: { result, error in
                self.bridge?.webView!.isOpaque = true
                self.bridge?.webView!.backgroundColor = self.originalBackgroundColor
                self.bridge?.webView!.scrollView.backgroundColor = self.originalBackgroundColor
                self.bridge?.webView?.superview?.bringSubviewToFront(self.webView!)
            })
        }
    }
    
    private func destroy() {
        implementation.dismantleCamera()
        self.showBackground()
    }
    
    @objc func prepare(_ call: CAPPluginCall) {
        implementation.prepare(nil)
        call.resolve()
    }
    
    @objc func hideBackground(_ call: CAPPluginCall) {
        self.hideBackground()
        call.resolve()
    }
    
    @objc func showBackground(_ call: CAPPluginCall) {
        self.showBackground()
        call.resolve()
    }
    
    @objc func startScan(_ call: CAPPluginCall) {
        self.savedCall = call;
        DispatchQueue.main.async {
            self.bridge?.webView?.superview!.insertSubview(self.implementation.cameraView, belowSubview: self.webView!)
            self.implementation.scan(call.getArray("targetedFormats", String.self))
            self.hideBackground()
        }
    }
    
    @objc func stopScan(_ call: CAPPluginCall) {
        if ((call.getBool("resolveScan") ?? false) && self.savedCall != nil) {
            var jsObject = PluginCallResultData();
            jsObject["hasContent"] = false
            
            savedCall?.resolve(jsObject)
            savedCall = nil
        }
        
        self.destroy()
        call.resolve()
    }
    
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
        self.savedCall = call
        var authorization = SGAuthorization()
        authorization.openLog = true
        authorization.avAuthorizationBlock { authorization, status in
            if (status == SGAuthorizationStatusSuccess) {
                
            }
        }
        let scanCode = SGScanCode()
        DispatchQueue.main.async {
            scanCode.scan(with: self.bridge?.viewController) { scanCode, result in
                var jsObject = PluginCallResultData()
                jsObject["content"] = result;
                call.resolve(jsObject)
            }
            scanCode.startRunningWith {
                
            } completion: {
                
            }

        }
    }
}
