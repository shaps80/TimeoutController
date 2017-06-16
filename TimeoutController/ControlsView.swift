//
//  ControlsView.swift
//  InteractionController
//
//  Created by Shahpour Benkau on 15/06/2017.
//  Copyright © 2017 152 Percent Ltd. All rights reserved.
//

import UIKit

@IBDesignable
final class ControlsView: UIVisualEffectView {
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBInspectable var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
}
