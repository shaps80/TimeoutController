//
//  TimeoutControllerHost.swift
//  InteractionController
//
//  Created by Shahpour Benkau on 15/06/2017.
//  Copyright © 2017 152 Percent Ltd. All rights reserved.
//

import UIKit

/// This class basically encapsulates the setup and functions normally found inside your UIViewController or UIView. It encapsultes the visibility of a view, along with a tap gesture for toggling visibility as well as an underling TimeoutController.
@IBDesignable @objc public final class TimeoutControllerHost: NSObject {
    
    /// If true, the timeoutController will automatically resume immediately.
    @IBInspectable dynamic private var autoStart: Bool = false
    
    /// If true, the timeoutController's events are ignored. Sometimes useful for temporarily disabling this feature.
    @IBInspectable dynamic var autoHide: Bool = true
    
    @IBInspectable dynamic var animationDuration: Double = 0.2
    
    /// The underlying view to show/hide. E.g. In a media player, this would usually be the control's view
    @IBOutlet public private(set) weak var viewToHide: UIView!
    
    /// The tap gesture to monitor for state changes. This will toggle the visibility of `viewToHide`
    @IBOutlet public private(set) weak var tapGesture: UITapGestureRecognizer! {
        didSet {
            tapGesture.addTarget(self, action: #selector(tapGestureHandler))
        }
    }
    
    /// The underlying TimeoutController that will also listen for events to determine appropriate times to hide `viewToHide`
    @IBOutlet public var timeoutController: TimeoutController? {
        didSet {
            timeoutController?.timeoutHandler = timeoutHandler
            
            if autoStart {
                timeoutController?.resume()
            }
        }
    }
    
    // Required for Storyboard/XIB support
    override init() {
        super.init()
    }
    
    /// Programmatically initializes a new TimeoutControllerHost
    ///
    /// - Parameters:
    ///   - viewToHide: The view to show/hide
    ///   - tapGesture: The tap gesture to toggle visibility
    ///   - autoStart: If true, the timeoutController will be started automatically on first launch
    public init(viewToHide: UIView, tapGesture: UITapGestureRecognizer, autoStart: Bool = true) {
        self.viewToHide = viewToHide
        self.autoStart = autoStart
        self.tapGesture = tapGesture
        
        super.init()
        tapGesture.addTarget(self, action: #selector(tapGestureHandler))
    }
    
    /// Handles the tap gesture
    @objc private func tapGestureHandler() {
        let viewHidden = viewToHide.alpha == 0
        
        if viewHidden {
            setView(hidden: false)
            timeoutController?.resume()
        } else {
            setView(hidden: true)
            timeoutController?.pause()
        }
    }
    
    /// Handles the timeout controller
    @objc private func timeoutHandler() {
        guard autoHide else { return }
        setView(hidden: true)
    }
    
    /// Sets the visibility of `viewToHide`
    ///
    /// - Parameters:
    ///   - hidden: If true, the view's alpha will be set to 0
    ///   - animated: If true, the change will be animated
    public func setView(hidden: Bool, animated: Bool = true) {
        guard animated else {
            self.viewToHide.alpha = hidden ? 0 : 1
            return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.viewToHide.alpha = hidden ? 0 : 1
        }
    }
}
