//
//  AppDelegate.swift
//  Festify
//
//  Created by Patrik Gebhardt on 20/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var trackPlayer: SMTrackPlayer?
    var reachability: Reachability?
    var progressHUD: MBProgressHUD?
    var loginCallback: ((SPTSession?, NSError?) ->())?
    
    // spotify authentication constants
    class var clientId: String { return "742dc3048abc43a6b5f2297fe07e6ae4" }
    class var callbackURL: String { return "festify://callback" }
    class var tokenSwapServiceURL: String { return "http://festify.schnuffm.fomalhaut.uberspace.de/swap" }
    class var tokenRefreshServiceURL: String { return "http://festify.schnuffm.fomalhaut.uberspace.de/refresh" }
    
    func requestSpotifySession(#completionHandler: ((SPTSession?, NSError?) ->())?) {
        // save login callback for use, when login completes
        self.loginCallback = completionHandler
        
        // open login url in safari to ask user to login
        let loginURL = SPTAuth.defaultInstance().loginURLForClientId(AppDelegate.clientId, declaredRedirectURL: NSURL(string: AppDelegate.callbackURL), scopes: [SPTAuthStreamingScope, SPTAuthPlaylistReadScope])
        UIApplication.sharedApplication().openURL(loginURL)
    }
    
    func renewSpotifySession(session: SPTSession?, withCompletionHandler completion:((SPTSession?, NSError?) ->())) {
        SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: AppDelegate.tokenRefreshServiceURL)) {
            (error: NSError?, session: SPTSession?) in
            completion(session, error)
        }
    }

    override func remoteControlReceivedWithEvent(event: UIEvent!) {
        // control track player by remote events
        if event.type == .RemoteControl {
            switch event.subtype {
            case .RemoteControlPlay, .RemoteControlPause, .RemoteControlTogglePlayPause:
                if self.trackPlayer!.playing {
                    self.trackPlayer!.pause()
                }
                else {
                    self.trackPlayer!.play()
                }
            
            case .RemoteControlNextTrack:
                self.trackPlayer!.skipForward()
                
            case .RemoteControlPreviousTrack:
                self.trackPlayer!.skipBackward()
                
            default:
                break
            }
        }
    }
    
    func reachabilityCanged(notification: AnyObject?) {
        // block UI with progress HUD and inform user about missing internet connection,
        // also stop playback, to prevent any glitches with the Spotify service.
        if self.reachability!.isReachable() {
            if !self.progressHUD {
                self.progressHUD = MBProgressHUD.showHUDAddedTo(self.window, animated: true)
                self.progressHUD!.labelText = "Lost Connection ..."
            }
            
            self.trackPlayer!.pause()
        }
        else {
            self.progressHUD?.hide(true)
            self.progressHUD = nil
            
            // try to enable playback for trackplayer, if application is active
            if UIApplication.sharedApplication().applicationState == .Active {
                self.trackPlayer!.enablePlaybackWithSession(self.trackPlayer!.session, callback: nil)
            }
        }
    }
    
    // UIApplicationDelegate
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // create shared track player object
        self.trackPlayer = SMTrackPlayer(companyName: NSBundle.mainBundle().bundleIdentifier, appName: NSBundle.mainBundle().infoDictionary[kCFBundleNameKey] as String)
        
        // start receiving remote control events
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        // check active network connection using reachability framework
        self.reachability = Reachability.reachabilityForInternetConnection()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: kReachabilityChangedNotification, object: nil)
        self.reachability!.startNotifier()
        
        // adjust default colors to match spotify color schema
        UITableView.appearance().separatorColor = UIColor(red: 86.0/255.0, green: 86.0/255.0, blue: 86.0/255.0, alpha: 1.0)
        BlurryModalSegue.appearance().backingImageBlurRadius = 15
        BlurryModalSegue.appearance().backingImageSaturationDeltaFactor = 1.3
        BlurryModalSegue.appearance().backingImageTintColor = UIColor(red: 26.0/255.0, green: 26.0/255.0, blue: 26.0/255.0, alpha: 0.7)
        
        // config appirater rating request system
        Appirater.setAppId("877580227")
        Appirater.setDebug(false)
        Appirater.appLaunched(true)
        
        return true
    }
    
    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        // this is the return point for the spotify authentication,
        // so completion happens here
        if SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL: NSURL(string: AppDelegate.callbackURL)) {
            SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url, tokenSwapServiceEndpointAtURL: NSURL(string: AppDelegate.tokenSwapServiceURL)) { (error: NSError?, session: SPTSession?) in
                if let loginCallback = self.loginCallback {
                    loginCallback(session, error)
                }
            }
            
            return true
        }
        
        return false
    }

    func applicationWillTerminate(application: UIApplication!) {
        // save current application state
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func applicationWillResignActive(application: UIApplication!) {
        // save current application state
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func applicationWillEnterForeground(application: UIApplication!) {
        // try to enable playback for trackplayer, if authenticated session is available
        if let trackPlayer = self.trackPlayer {
            if let reachability = self.reachability {
                if trackPlayer.playing && reachability.isReachable() {
                    self.progressHUD?.hide(true)
                    self.progressHUD = nil
                    
                    trackPlayer.enablePlaybackWithSession(trackPlayer.session, callback: nil)
                }
            }
        }
        
        Appirater.appEnteredForeground(true)
    }
}
