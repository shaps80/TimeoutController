//
//  InteractionController.swift
//  InteractionController
//
//  Created by Shahpour Benkau on 15/06/2017.
//  Copyright © 2017 152 Percent Ltd. All rights reserved.
//

import UIKit

/// Automatic conformance is implemented for UIView's and UIGestureRecognizers, allowing TimeoutController's to receive feedback from these providers.
@objc public protocol TimeoutInteractionProviding {
    
    /// The TimeoutController associated with this provider
    var timeoutController: TimeoutController? { get }
    
}

/// A timeout controller is basically a wrapper around a timer, however it also maintains interaction provider's that give feedback as to whether or not the timer needs to be invalidated.
@objc public final class TimeoutController: NSObject {
    
    /// An array of interaction provider's. Storyboard and XIB supported
    @IBOutlet public private(set) var interactionProviders: [TimeoutInteractionProviding]? {
        didSet {
            interactionProviders?.flatMap { $0 as? UIView }.forEach { $0.timeoutController = self }
            interactionProviders?.flatMap { $0 as? UIGestureRecognizer }.forEach { $0.timeoutController = self }
        }
    }
    
    /// The specified timeout is used to determine when the TimeoutController needs to call its handler
    @IBInspectable dynamic public var timeout: Double = 5 {
        didSet {
            guard timer != nil else { return }
            pause()
            resume()
        }
    }
    
    /// The underlying timer instance
    private weak var timer: Timer?
    
    /// You can set this timeout handler to be executed whenever a timeout occurs. Note: This will not execute if you manually pause/resume the controller.
    public var timeoutHandler: (() -> Void)?
    
    // This empty implementation needs to be here in order for Storyboards to work.
    public override init() {
        super.init()
    }
    
    /// Initializes a new controller.
    ///
    /// - Parameters:
    ///   - providers: The interaction provider's that will provide feedback to this controller
    ///   - timeout: The timeout interval to use for the timer
    public init(providers: [TimeoutInteractionProviding], timeout: TimeInterval) {
        self.timeout = timeout
        self.interactionProviders = providers
        super.init()
        
        interactionProviders?.flatMap { $0 as? UIView }.forEach { $0.timeoutController = self }
        interactionProviders?.flatMap { $0 as? UIGestureRecognizer }.forEach { $0.timeoutController = self }
    }
    
    /// Specifies that an interaction began. Starts a new timer.
    fileprivate func interactionBegan() {
        pause()
    }
    
    /// Specifies that an interaction ended. Causes the timer to be invalidated automatically
    fileprivate func interactionEnded() {
        // sometimes we didn't get an interactionBegan() so this just ensures the current timer is reset
        pause()
        resume()
    }
    
    /// Resumes the timer and if the timeout is reached, executes the handler
    public func resume() {
        timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] timer in
            self?.timeoutHandler?()
            self?.pause()
        }
    }
    
    /// Invalidates the timer. Effectively preventing any calls to the timeoutHandler
    public func pause() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Cleanup.
    deinit {
        pause()
    }
    
}

private struct TimeoutKVO {
    fileprivate static var context: UInt8 = 1
    fileprivate static var controllerKey: UInt8 = 2
}

/// Extends UIGestureRecognizer to observer its state and provide feedback to a TimeoutController
extension UIGestureRecognizer: TimeoutInteractionProviding {
    public fileprivate(set) var timeoutController: TimeoutController? {
        get { return objc_getAssociatedObject(self, &TimeoutKVO.controllerKey) as? TimeoutController }
        set {
            objc_setAssociatedObject(self, &TimeoutKVO.controllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if newValue == nil {
                removeObserver(self, forKeyPath: "state", context: &TimeoutKVO.context)
            } else {
                addObserver(self, forKeyPath: "state", options: .new, context: &TimeoutKVO.context)
            }
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &TimeoutKVO.context && keyPath == "state" {
            switch state {
            case .began:
                timeoutController?.interactionBegan()
            case .changed:
                break
            default:
                timeoutController?.interactionEnded()
            }
            
            return
        }
        
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}

/// Extends UIView to provide feedback to a TimeoutController
extension UIView: TimeoutInteractionProviding {
    public fileprivate(set) var timeoutController: TimeoutController? {
        get { return objc_getAssociatedObject(self, &TimeoutKVO.controllerKey) as? TimeoutController }
        set { objc_setAssociatedObject(self, &TimeoutKVO.controllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        timeoutController?.interactionBegan()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        timeoutController?.interactionEnded()
    }
}

/// UISliders, buttons and other UIControl subclasses don't call their corresponding touchesBegan, touchesEnded, etc... so we have to use a different method here to provide feedback to a TimeoutController
extension UISlider {
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        timeoutController?.interactionBegan()
        return super.beginTracking(touch, with: event)
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        timeoutController?.interactionEnded()
        super.endTracking(touch, with: event)
    }
}

/// UISliders, buttons and other UIControl subclasses don't call their corresponding touchesBegan, touchesEnded, etc... so we have to use a different method here to provide feedback to a TimeoutController
extension UIButton {
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return super.beginTracking(touch, with: event)
        timeoutController?.interactionBegan()
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        timeoutController?.interactionEnded()
    }
}

/// UISliders, buttons and other UIControl subclasses don't call their corresponding touchesBegan, touchesEnded, etc... so we have to use a different method here to provide feedback to a TimeoutController
extension UISwitch {
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return super.beginTracking(touch, with: event)
        timeoutController?.interactionBegan()
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        timeoutController?.interactionEnded()
    }
}
