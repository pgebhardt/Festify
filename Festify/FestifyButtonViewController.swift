//
//  FestifyButtonViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class FestifyButtonViewController: UIViewController {
    @IBOutlet var buttonOverlay: UIImageView!
    
    @IBAction func buttonPressed(sender: AnyObject?) {
        // toggle discovering state
        if SMDiscoveryManager.sharedInstance().discovering {
            SMDiscoveryManager.sharedInstance().stopDiscovering()
        }
        else {
            SMDiscoveryManager.sharedInstance().startDiscovering()
        }
    }
    
    override func viewDidAppear(animated: Bool)  {
        super.viewDidDisappear(animated)
        
        // register to discovery manager state changes to apply animation to button overlay and check current
        // discovery manager state to start animation
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAnimationState:", name: "SMDiscoveryManagerDidUpdateDiscoveryState", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAnimationState:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        if SMDiscoveryManager.sharedInstance().discovering {
            self.startAnimation()
        }
    }
    
    override func viewDidDisappear(animated: Bool)  {
        super.viewDidDisappear(animated)
        
        // unregister from all notifications and stop animation
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if SMDiscoveryManager.sharedInstance().discovering {
            self.stopAnimation()
        }
    }

    func updateAnimationState(notification: AnyObject?) {
        if SMDiscoveryManager.sharedInstance().discovering {
            self.startAnimation()
        }
        else {
            self.stopAnimation()
        }
    }
    
    func startAnimation() {
        // reset all current animations and start button animation from beginning
        self.buttonOverlay.layer.removeAllAnimations()
        self.buttonOverlay.transform = CGAffineTransformIdentity;
            
        UIView.animateWithDuration(0.6, delay: 0.0, options: .Repeat | .CurveEaseInOut | .Autoreverse | .AllowUserInteraction, animations: {
                self.buttonOverlay.transform = CGAffineTransformMakeRotation(CGFloat(-60.0 * Double(M_PI) / 180.0))
            }, completion: nil)
    }
    
    func stopAnimation() {
        // remove all animations and do a last cicle of animations
        self.buttonOverlay.transform = buttonOverlay.layer.presentationLayer().affineTransform()
        self.buttonOverlay.layer.removeAllAnimations()
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseOut | .BeginFromCurrentState, animations: {
                self.buttonOverlay.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
}
