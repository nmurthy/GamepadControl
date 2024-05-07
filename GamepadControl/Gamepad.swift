//
//  Gamepad.swift
//  GamepadControl
//
//  Created by Admin on 4/1/24.
//

import SwiftUI
import GameController

// Define audio control actions
enum AudioControlAction {
    case trackMute, trackSolo, trackArm
    case trackVolumeInc, trackVolumeDec
    case trackPrevious, trackNext
    case pannerAzimuthLeft, pannerAzimuthRight
    case pannerElevationInc, pannerElevationDec
    case pannerDistanceInc, pannerDistanceDec
    case pannerSpreadInc, pannerSpreadDec
    case transportPlay, transportStop
    case transportRecord, transportUndo, transportRedo
    
    func stub() {
        print("stub")
    }

    func performAction() {
        switch self {
        case .trackMute: stub() // TODO: Implement Mute
        case .trackSolo: stub() // TODO: Implement Solo
        case .trackArm: stub() // TODO: Implement Arm
        case .trackVolumeInc: stub() // TODO: Increase Volume
        case .trackVolumeDec: stub() // TODO: Decrease Volume
        case .trackPrevious: stub() // TODO: Previous Track
        case .trackNext: stub() // TODO: Next Track
        default: stub()
//        case .pannerAzimuthLeft: // TODO: Panner Move Azimuth Left
//        case .pannerAzimuthRight: // TODO: Panner Move Azimuth Right
//        case .pannerElevationInc: // TODO: Increase Elevation
//        case .pannerElevationDec: // TODO: Decrease Elevation
//        case .pannerDistanceInc: // TODO: Increase Distance
//        case .pannerDistanceDec: // TODO: Decrease Distance
//        case .pannerSpreadInc: // TODO: Increase Spread
//        case .pannerSpreadDec: // TODO: Decrease Spread
//        case .transportPlay: // TODO: Play Transport
//        case .transportStop: // TODO: Stop Transport
//        case .transportRecord: // TODO: Record Transport
//        case .transportUndo: // TODO: Undo Last Action
//        case .transportRedo: // TODO: Redo Last Action
        }
    }
}

class Gamepad: ObservableObject {
    struct ButtonElement {
        var id = UUID()
        var offSymbol: String
        var onSymbol: String
        var isPressed: Bool = false
    }
    
    struct TriggerElement: Identifiable {
        var id = UUID()
        var offSymbol: String
        var onSymbol: String
        var isPressed: Bool = false
        var value: Float = 0.0
    }
    
    struct StickElement: Identifiable {
        var id = UUID()
        var offSymbol: String
        var onSymbol: String
        var isPressed: Bool = false
        var x: Float = 0.0
        var y: Float = 0.0
    }
    
    var keymap: [String: AudioControlAction] = [
           "buttonX": .trackMute,
           "buttonCircle": .trackSolo,
           "buttonSquare": .trackArm,
           "buttonTriangle": .trackNext,
           "leftShoulder": .trackPrevious,
           "rightShoulder": .trackVolumeInc,
           "leftTrigger": .trackVolumeDec,
           "rightTrigger": .transportRecord,
           "dpad.left": .pannerAzimuthLeft,
           "dpad.right": .pannerAzimuthRight,
           "dpad.up": .pannerElevationInc,
           "dpad.down": .pannerElevationDec,
           "leftThumbstickButton": .transportPlay,
           "rightThumbstickButton": .transportStop,
           "touchpadButton": .transportUndo
       ]
    
    @Published var connected = false
    
    @Published var buttons: [String: ButtonElement] = [
           "R1": ButtonElement(offSymbol: "r1.rectangle.roundedbottom", onSymbol: "r1.rectangle.roundedbottom.fill"),
           "L1": ButtonElement(offSymbol: "l1.rectangle.roundedbottom", onSymbol: "l1.rectangle.roundedbottom.fill"),
           "R2": ButtonElement(offSymbol: "r2.rectangle.roundedbottom", onSymbol: "r2.rectangle.roundedbottom.fill"),
           "L2": ButtonElement(offSymbol: "l2.rectangle.roundedbottom", onSymbol: "l2.rectangle.roundedbottom.fill"),
           "Square": ButtonElement(offSymbol: "square.fill", onSymbol: "square.fill"), // Replace with actual symbols
           "Circle": ButtonElement(offSymbol: "circle.fill", onSymbol: "circle.fill"), // Replace with actual symbols
           "Triangle": ButtonElement(offSymbol: "triangle.fill", onSymbol: "triangle.fill"), // Replace with actual symbols
           "X": ButtonElement(offSymbol: "xmark.circle", onSymbol: "xmark.circle.fill"), // Replace with actual symbols
           "DPadUp": ButtonElement(offSymbol: "dpad.up", onSymbol: "dpad.up.fill"), // Replace with actual symbols
           "DPadDown": ButtonElement(offSymbol: "dpad.down", onSymbol: "dpad.down.fill"), // Replace with actual symbols
           "DPadLeft": ButtonElement(offSymbol: "dpad.left", onSymbol: "dpad.left.fill"), // Replace with actual symbols
           "DPadRight": ButtonElement(offSymbol: "dpad.right", onSymbol: "dpad.right.fill"), // Replace with actual symbols
           "LeftThumbstick": ButtonElement(offSymbol: "thumbstick.left", onSymbol: "thumbstick.left.fill"), // Replace with actual symbols
           "RightThumbstick": ButtonElement(offSymbol: "thumbstick.right", onSymbol: "thumbstick.right.fill"), // Replace with actual symbols
           "Options": ButtonElement(offSymbol: "options.rectangle", onSymbol: "options.rectangle.fill"), // Replace with actual symbols
           "Create": ButtonElement(offSymbol: "create.rectangle", onSymbol: "create.rectangle.fill"), // Replace with actual symbols
           "Touchpad": ButtonElement(offSymbol: "touchpad.rectangle", onSymbol: "touchpad.rectangle.fill") // Replace with actual symbols
       ]
    
    init() {
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(controllerDidConnect),
                                                   name: .GCControllerDidConnect,
                                                   object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(controllerDidDisconnect),
                                               name: .GCControllerDidDisconnect,
                                               object: nil)
        GCController.startWirelessControllerDiscovery {}
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        GCController.stopWirelessControllerDiscovery()
    }

    @objc func controllerDidConnect(notification: Notification) {
        guard let controller = notification.object as? GCController,
              let gamepad = controller.extendedGamepad else { return }
        setupGamepad(gamepad)
    }
    
    @objc func controllerDidDisconnect(notification: Notification) {
            print("Controller disconnected.")
        }

    private func setupGamepad(_ gamepad: GCExtendedGamepad) {
        gamepad.valueChangedHandler = { [weak self] gamepad, element in
            self?.handleInput(gamepad: gamepad, element: element)
        }
    }

    private func handleInput(gamepad: GCExtendedGamepad, element: GCControllerElement) {
        let key = elementAlias(from: element, gamepad)
        if let action = keymap[key] {
            action.performAction()
        }
    }
    
    private func elementAlias(from element: GCControllerElement, _ gamepad: GCExtendedGamepad) -> String {
            switch element {
            case gamepad.buttonX: return "buttonX"
            case gamepad.buttonCircle: return "buttonCircle"
            case gamepad.buttonSquare: return "buttonSquare"
            case gamepad.buttonTriangle: return "buttonTriangle"
            case gamepad.leftShoulder: return "leftShoulder"
            case gamepad.rightShoulder: return "rightShoulder"
            case gamepad.leftTrigger: return "leftTrigger"
            case gamepad.rightTrigger: return "rightTrigger"
            case gamepad.dpad.left: return "dpad.left"
            case gamepad.dpad.right: return "dpad.right"
            case gamepad.dpad.up: return "dpad.up"
            case gamepad.dpad.down: return "dpad.down"
            case gamepad.leftThumbstickButton: return "leftThumbstickButton"
            case gamepad.rightThumbstickButton: return "rightThumbstickButton"
            case gamepad.buttonMenu: return "buttonMenu"
            default: return ""
            }
        }
}
