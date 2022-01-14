import Foundation
import UIKit
import AVFoundation
import Capacitor

@objc public class BarcodeScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    public class CameraView: UIView {
        var videoPreviewLayer: AVCaptureVideoPreviewLayer?
        
        func interfaceOrientationToVideoOrientation(_ orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
            switch (orientation) {
            case UIInterfaceOrientation.portrait:
                return AVCaptureVideoOrientation.portrait;
            case UIInterfaceOrientation.portraitUpsideDown:
                return AVCaptureVideoOrientation.portraitUpsideDown;
            case UIInterfaceOrientation.landscapeLeft:
                return AVCaptureVideoOrientation.landscapeLeft;
            case UIInterfaceOrientation.landscapeRight:
                return AVCaptureVideoOrientation.landscapeRight;
            default:
                return AVCaptureVideoOrientation.portraitUpsideDown;
            }
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            if let sublayers = self.layer.sublayers {
                for layer in sublayers {
                    layer.frame = self.bounds;
                }
            }
            self.videoPreviewLayer?.connection?.videoOrientation = interfaceOrientationToVideoOrientation(UIApplication.shared.statusBarOrientation);
        }
        
        func addPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer?) {
            previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer!.frame = self.bounds
            self.layer.addSublayer(previewLayer!)
            self.videoPreviewLayer = previewLayer
        }
        
        func removePreviewLayer() {
            if self.videoPreviewLayer != nil {
                self.videoPreviewLayer!.removeFromSuperlayer()
                self.videoPreviewLayer = nil
            }
        }
    }
    
    public var cameraView: CameraView!
    var capatureSession: AVCaptureSession?
    var capatureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    var metaOutput: AVCaptureMetadataOutput?
    
    var currentCamera: Int = 0
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    
    var isScanning: Bool = false
    var shouldRunScan: Bool = false
    var didRunCameraSetup: Bool = false
    var didRunCameraPrepare: Bool = false
    var isBackgroundHidden: Bool = false
    
    enum SupportedFormat: String, CaseIterable {
        // 1D Product
        //!\ UPC_A is part of EAN_13 according to Apple docs
        case UPC_E
        //!\ UPC_EAN_EXTENSION is not supported by AVFoundation
        case EAN_8
        case EAN_13
        // 1D Industrial
        case CODE_39
        case CODE_39_MOD_43
        case CODE_93
        case CODE_128
        //!\ CODABAR is not supported by AVFoundation
        case ITF
        case ITF_14
        // 2D
        case AZTEC
        case DATA_MATRIX
        //!\ MAXICODE is not supported by AVFoundation
        case PDF_417
        case QR_CODE
        //!\ RSS_14 is not supported by AVFoundation
        //!\ RSS_EXPANDED is not supported by AVFoundation
        
        var value: AVMetadataObject.ObjectType {
            switch self {
            // 1D Product
            case .UPC_E: return AVMetadataObject.ObjectType.upce
            case .EAN_8: return AVMetadataObject.ObjectType.ean8
            case .EAN_13: return AVMetadataObject.ObjectType.ean13
            // 1D Industrial
            case .CODE_39: return AVMetadataObject.ObjectType.code39
            case .CODE_39_MOD_43: return AVMetadataObject.ObjectType.code39Mod43
            case .CODE_93: return AVMetadataObject.ObjectType.code93
            case .CODE_128: return AVMetadataObject.ObjectType.code128
            case .ITF: return AVMetadataObject.ObjectType.interleaved2of5
            case .ITF_14: return AVMetadataObject.ObjectType.itf14
            // 2D
            case .AZTEC: return AVMetadataObject.ObjectType.aztec
            case .DATA_MATRIX: return AVMetadataObject.ObjectType.dataMatrix
            case .PDF_417: return AVMetadataObject.ObjectType.pdf417
            case .QR_CODE: return AVMetadataObject.ObjectType.qr
            }
        }
    }
    
    var targetedFormats = [AVMetadataObject.ObjectType]()
    
    enum CaptureError: Error {
        case backCameraUnavailable
        case frontCameraUnavailable
        case couldNotCaptureInput(error: NSError)
    }
    
    public func load() {
        self.cameraView = CameraView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        self.cameraView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func hasCameraPermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if (status == AVAuthorizationStatus.authorized) {
            return true
        }
        return false
    }
    
    @available(swift, deprecated: 5.6, message: "New Xcode? Check if `AVCaptureDevice.DeviceType` has new types and add them accordingly.")
    private func discoverCaptureDevices() -> [AVCaptureDevice] {
        if #available(iOS 13.0, *) {
            return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera], mediaType: .video, position: .front).devices
        } else {
            return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera], mediaType: .video, position: .front).devices
        }
    }
    
    func createCaptureDeviceInput() throws -> AVCaptureDeviceInput {
        var captureDevice: AVCaptureDevice
        if (currentCamera == 0) {
            if (backCamera != nil) {
                captureDevice = backCamera!
            } else {
                throw CaptureError.backCameraUnavailable
            }
        } else {
            if (frontCamera != nil) {
                captureDevice = frontCamera!
            } else {
                throw CaptureError.frontCameraUnavailable
            }
        }
        let captureDeviceInput: AVCaptureDeviceInput
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            throw CaptureError.couldNotCaptureInput(error: error)
        }
        return captureDeviceInput
    }
    
    private func setupCamera() -> Bool {
        do {
            cameraView.backgroundColor = UIColor.clear
            let availableVideoDevices = discoverCaptureDevices()
            for device in availableVideoDevices {
                if device.position == AVCaptureDevice.Position.back {
                    backCamera = device
                }
                else if device.position == AVCaptureDevice.Position.front {
                    frontCamera = device
                }
            }
            // older iPods have no back camera
            if (backCamera == nil) {
                currentCamera = 1
            }
            let input: AVCaptureDeviceInput
            input = try self.createCaptureDeviceInput()
            capatureSession = AVCaptureSession()
            capatureSession!.addInput(input)
            metaOutput = AVCaptureMetadataOutput()
            capatureSession!.addOutput(metaOutput!)
            metaOutput!.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            capatureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: capatureSession!)
            cameraView.addPreviewLayer(capatureVideoPreviewLayer)
            self.didRunCameraSetup = true
        } catch CaptureError.backCameraUnavailable {
            
        } catch CaptureError.frontCameraUnavailable {
            
        } catch CaptureError.couldNotCaptureInput {
            
        } catch {
            
        }
        return false
    }
    
    func dismantleCamera() {
        // opposite of setupCamera
        if (self.capatureSession != nil) {
            DispatchQueue.main.sync {
                self.capatureSession!.stopRunning()
                self.cameraView.removePreviewLayer()
                self.capatureVideoPreviewLayer = nil
                self.metaOutput = nil
                self.capatureSession = nil
                self.currentCamera = 0
                self.frontCamera = nil
                self.backCamera = nil
            }
        }
        
        self.isScanning = false
        self.didRunCameraSetup = false
        self.didRunCameraPrepare = false
        
        
    }
    
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
    
    @objc public func prepare() {
        
    }
}
