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
    func loginViewDidReturnFromExternalSignUp(loginView: LoginViewController)
    func loginView(loginView: LoginViewController, didCompleteLoginWithSession session: SPTSession)
    func loginView(loginView: LoginViewController, didCompleteLoginWithError error: NSError)
}

class LoginViewController: UIViewController {
    var delegate: LoginViewDelegate?
    
    // spotify authentication constants
    class var clientId: String { return "742dc3048abc43a6b5f2297fe07e6ae4" }
    class var callbackURL: String { return "festify://callback" }
    
    @IBAction func login(sender: AnyObject?) {
        // register url handler to app delegate and request authenticated session from
        // spotify backend
        (UIApplication.sharedApplication().delegate as AppDelegate).urlHandler = {
            (url: NSURL) in
            // this is the return point for the spotify authentication,
            // so completion happens here
            if SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL: NSURL(string: LoginViewController.callbackURL)) {
                self.delegate?.loginViewDidReturnFromExternalSignUp(self)
                
                // complete login process and inform delegate about success
                SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url) {
                    (error: NSError?, session: SPTSession?) -> () in
                    if let session = session {
                        self.delegate?.loginView(self, didCompleteLoginWithSession: session)
                    }
                    else {
                        self.delegate?.loginView(self, didCompleteLoginWithError: error!)
                    }
                }
                
                return true
            }
            
            return false
        }
        
        // get correct login url and open safari to promt user for credentials
        let loginURL = SPTAuth.defaultInstance().loginURLForClientId(LoginViewController.clientId,
            declaredRedirectURL: NSURL(string: LoginViewController.callbackURL),
            scopes: [SPTAuthStreamingScope, SPTAuthPlaylistModifyPublicScope],
            withResponseType: "token")
        UIApplication.sharedApplication().openURL(loginURL)
    }
}
