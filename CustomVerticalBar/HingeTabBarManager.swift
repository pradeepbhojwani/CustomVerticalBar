//
//  HingeTabBarManager.swift
//  CustomVerticalBar
//
//  Created by pradeepMac on 24/09/26.
//

import UIKit
import Combine

@MainActor
final class HingeTabBarManager {

    static let shared = HingeTabBarManager()

    private init() {}

    // MARK: - Hinge Data

    private(set) var hinge: UIHinge?
    private(set) var orientation: DeviceOrientation = .unknown
    
    var cancellables = Set<AnyCancellable>()
    var isFoldablePhone: Bool {
        hinge != nil
    }

    var hingeStatus: UIHinge.Status? {
        hinge?.status
    }

    var hingeStatusText: String {
        guard let hinge else { return "Unavailable" }
        return "\(hinge.status)"
    }

    var hingeAngleInDegrees: Int? {
        guard let hinge else { return nil }
        let degrees = hinge.angle * 180 / .pi
        return Int(degrees)
    }

    // Use this directly in a UILabel.
    var displayText: String {
        guard isFoldablePhone else {
            return """
            Not Foldable

            Orientation: \(orientation.title)
            """
        }

        return """
        Foldable Phone

        Status: \(hingeStatusText)
        Angle: \(hingeAngleInDegrees ?? 0)°
        Orientation: \(orientation.title)
        """
    }

    // Called whenever hinge data or orientation changes.
    var onUpdate: (() -> Void)?

    private var hingeInteraction: UIHingeInteraction?
    private weak var monitoredView: UIView?

    // MARK: - Monitoring

    func startMonitoring(on view: UIView) {
        // Avoid adding the same interaction again.
        guard monitoredView !== view else {
            updateOrientation(from: view)
            return
        }

        stopMonitoring()

        monitoredView = view
        updateOrientation(from: view)

        let interaction = UIHingeInteraction { [weak self, weak view] _, update in
            guard let self else { return }

            self.hinge = update.hinge
            if let view {
                self.updateOrientation(from: view)
            }

            self.log(update.hinge)
            self.notifyUpdate()
        }

        hingeInteraction = interaction
        view.addInteraction(interaction)
        notifyUpdate()
    }

    func stopMonitoring() {
        if let hingeInteraction, let monitoredView {
            monitoredView.removeInteraction(hingeInteraction)
        }

        hingeInteraction = nil
        monitoredView = nil
        hinge = nil
        onUpdate = nil
    }

    // Call this when the interface rotates.
    func updateOrientation(from view: UIView) {
        guard let interfaceOrientation = view.window?.windowScene?.interfaceOrientation else {
            orientation = .unknown
            return
        }

        switch interfaceOrientation {
        case .portrait:
            orientation = .portrait

        case .portraitUpsideDown:
            orientation = .portraitUpsideDown

        case .landscapeLeft:
            orientation = .landscapeLeft

        case .landscapeRight:
            orientation = .landscapeRight

        default:
            orientation = .unknown
        }
    }

    func refresh(from view: UIView) {
        updateOrientation(from: view)
        notifyUpdate()
    }

    private func notifyUpdate() {
        onUpdate?()
    }

    private func log(_ hinge: UIHinge?) {
        guard let hinge else {
            print("Hinge update — no hinge available")
            return
        }

        let degrees = Int(hinge.angle * 180 / .pi)
        print("Hinge update — angle: \(degrees)°, status: \(hinge.status)")
    }

    enum DeviceOrientation {
        case portrait
        case portraitUpsideDown
        case landscapeLeft
        case landscapeRight
        case unknown

        var title: String {
            switch self {
            case .portrait:
                return "Portrait"
            case .portraitUpsideDown:
                return "Portrait Upside Down"
            case .landscapeLeft:
                return "Landscape Left"
            case .landscapeRight:
                return "Landscape Right"
            case .unknown:
                return "Unknown"
            }
        }
    }
    
    func evaluatePosition(in scene: UIWindowScene,on view: UIView) {
        guard let window = view.window, window.windowScene === scene else { return }

        // Convert both rectangles into the same scene coordinate space. This
        // works correctly while the device is rotated or in iPad multitasking.
        let coordinateSpace = scene.coordinateSpace
        let windowFrame = window.convert(window.bounds, to: coordinateSpace)
        let sceneBounds = coordinateSpace.bounds
        let fullWidthThreshold = sceneBounds.width * 0.95

        let currentSide: String
        if windowFrame.width >= fullWidthThreshold {
            currentSide = "FULL SCREEN"
        } else if windowFrame.midX <= sceneBounds.midX {
            currentSide = "LEFT"
        } else {
            currentSide = "RIGHT"
        }

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
        print("⚡️ [Split Screen] \(appName) is on the \(currentSide) side")
    }
}
