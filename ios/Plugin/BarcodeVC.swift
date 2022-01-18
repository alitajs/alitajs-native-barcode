//
//  BarcodeVC.swift
//  Plugin
//
//  Created by ashoka on 2022/1/18.
//  Copyright © 2022 Max Lynch. All rights reserved.
//

import UIKit

@objc(BarcodeVC)
class BarcodeVC : UIViewController {
    var scanCode: SGScanCode?
    lazy var scanView: SGScanView = {
        let scanView = SGScanView.init(frame: self.view.bounds)
        scanView.scanLineName = "scanLine"
        scanView.scanStyle = ScanStyleDefault
        scanView.cornerLocation = CornerLoactionOutside
        return scanView
    }()
    lazy var flashlightBtn: UIButton = {
        let button = UIButton(type: .custom)
        let btnW: CGFloat = 30.0
        let btnH: CGFloat = 30.0
        let btnX: CGFloat = 0.5 * (self.view.bounds.size.width - btnW)
        let btnY: CGFloat = 0.55 * self.view.bounds.size.height
        button.frame = CGRect(x: btnX, y: btnY, width: btnW, height: btnH)
        button.setBackgroundImage(BarcodeHelper.image("flashOpen"), for: .normal)
        button.setBackgroundImage(BarcodeHelper.image("flashClose"), for: .selected)
        button.addTarget(self, action: #selector(handleFlashlightBtnClick(_:)), for: .touchUpInside)
        return button
    }()
    lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        let labelX: CGFloat = 0
        let labelY = 0.73 * self.view.bounds.size.height
        let labelW = self.view.bounds.size.width
        let labelH: CGFloat = 25
        label.frame = CGRect(x: labelX, y: labelY, width: labelW, height: labelH)
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 13.0)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.text = "将二维码/条码放入框内, 即可自动扫描"
        return label
    }()
    var completion: ((String?, Bool) -> Void)?
    lazy var cancelBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(handleCancelClick(_:)), for: .touchUpInside)
        button.sizeToFit()
        let btnX: CGFloat = 24.0
        let btnY: CGFloat = BarcodeHelper.statusBarHeight() + 10
        button.frame = CGRect(x: btnX, y: btnY, width: button.frame.width, height: button.frame.height)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        scanCode = SGScanCode()
        self.setupQRCodeScan()
        self.view.addSubview(self.scanView)
        self.view.addSubview(self.flashlightBtn)
        self.view.addSubview(self.promptLabel)
        self.view.addSubview(self.cancelBtn)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanCode?.startRunningWith(before: nil, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanView.startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.scanView.stopScanning()
        scanCode?.stopRunning()
    }
    
    func setupQRCodeScan() {
        scanCode?.brightness = true
        
        scanCode?.scan(with: self, resultBlock: { (scanCode, result) in
            if (result != nil) {
                scanCode?.stopRunning()
                scanCode?.playSoundName("SGQRCode.bundle/scanEndSound.caf")
                if (self.completion != nil) {
                    self.completion!(result, false)
                }
            }
        })
        
        scanCode?.startRunningWith(before: {
            
        }, completion: {
            
        })
    }

    @objc func handleCancelClick(_ button: UIButton) {
        if (self.completion != nil) {
            self.completion!(nil, true)
        }
    }
    
    @objc func handleFlashlightBtnClick(_ button: UIButton) {
        if (button.isSelected == false) {
            scanCode?.turnOnFlashlight()
            button.isSelected = true
        } else {
            scanCode?.turnOffFlashlight()
            button.isSelected = false
        }
    }
}
