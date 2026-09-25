//
//  UIViewController+Extension.swift
//  CustomVerticalBar
//
//  Created by pradeepMac on 24/09/26.
//

import UIKit

extension UIViewController {
    
    enum ScreenSide {
        case left
        case right
        case fullWidth
    }
    
    var currentScreenSide: ScreenSide {
        guard let window = view.window,
              let windowScene = window.windowScene else {
            return .fullWidth
        }
        
        let windowFrame = window.frame
        let screenBounds = windowScene.screen.bounds
        // Check if app occupies full width
        if windowFrame.width >= screenBounds.width {
            return .fullWidth
        }
        
        // Convert window origin to coordinate space of the screen
        let windowOriginInScreen = window.convert(CGPoint.zero, to: nil)
        
        if windowOriginInScreen.x == 0 {
            return .left
        } else {
            return .right
        }
    }
}
