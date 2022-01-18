//
//  BarcodeHelper.swift
//  Plugin
//
//  Created by ashoka on 2022/1/18.
//  Copyright © 2022 Max Lynch. All rights reserved.
//

import UIKit

class BarcodeHelper: NSObject {
    public static func image(_ named: String) -> UIImage? {
        var url = Bundle.main.url(forResource: "SGQRCode", withExtension: "bundle")
        if (url == nil) {
            url = Bundle(for: Self.self).url(forResource: "SGQRCode", withExtension: "bundle")
        }
        let bundle = url != nil ? Bundle(url: url!) : Bundle.main
        var image = UIImage(named: named, in: bundle, compatibleWith: nil)
        if (image == nil) {
            image = UIImage(named: named)
        }
        return image
    }
    
    public static func statusBarHeight() -> CGFloat {
        var height: CGFloat = 0
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
            height = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            height = UIApplication.shared.statusBarFrame.height
        }
        return height
    }
}
