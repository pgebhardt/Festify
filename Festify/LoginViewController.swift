//
//  LoginViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

@objc
protocol LoginViewDelegate: NSObjectProtocol {
    @optional func loginView(loginView: LoginViewController, didCompleteLoginWithSession session:SPTSession?)
}

class LoginViewController: UIViewController {
    var delegate: LoginViewDelegate?
    
    @IBAction func login(sender: AnyObject?) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.requestSpotifySession {
                (session: SPTSession?, error: NSError?) in
                dispatch_async(dispatch_get_main_queue()) {
                    if !error {
                        self.delegate?.loginView?(self, didCompleteLoginWithSession: session)
                    }
                }
            }
        }
    }
}
