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
    
    // spotify authentication constants
    class var clientId: String { return "742dc3048abc43a6b5f2297fe07e6ae4" }
    class var callbackURL: String { return "festify://callback" }
    class var tokenSwapServiceURL: String { return "http://festify.schnuffm.fomalhaut.uberspace.de/swap" }
    class var tokenRefreshServiceURL: String { return "http://festify.schnuffm.fomalhaut.uberspace.de/refresh" }
    
    @IBAction func login(sender: AnyObject?) {
        // register url handler to app delegate and request authenticated session from
        // spotify backend
        (UIApplication.sharedApplication().delegate as AppDelegate).urlHandler = {
            (url: NSURL) in
            // this is the return point for the spotify authentication,
            // so completion happens here
            if SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL: NSURL(string: LoginViewController.callbackURL)) {
                SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url,
                    tokenSwapServiceEndpointAtURL: NSURL(string: LoginViewController.tokenSwapServiceURL)) {
                    (error: NSError?, session: SPTSession?) in
                    if !error {
                        self.delegate?.loginView?(self, didCompleteLoginWithSession: session)
                    }
                }
                
                return true
            }
            
            return false
        }
        
        // get correct login url and open safari to promt user for credentials
        let loginURL = SPTAuth.defaultInstance().loginURLForClientId(LoginViewController.clientId,
            declaredRedirectURL: NSURL(string: LoginViewController.callbackURL),
            scopes: [SPTAuthStreamingScope, SPTAuthPlaylistReadScope])
        UIApplication.sharedApplication().openURL(loginURL)
    }
    
    class func renewSpotifySession(session: SPTSession?, withCompletionHandler completion:((SPTSession?, NSError?) ->())) {
        SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: LoginViewController.tokenRefreshServiceURL)) {
            (error: NSError?, session: SPTSession?) in
            completion(session, error)
        }
    }
}
