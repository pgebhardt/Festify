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
    let streamingController = SPTAudioStreamingController()
    
    var window: UIWindow?
    var progressHUD: MBProgressHUD?
    var urlHandler: ((NSURL) -> (Bool))?

    override func remoteControlReceivedWithEvent(event: UIEvent) {
        // control track player by remote events
        if event.type == .RemoteControl {
            switch event.subtype {
            case .RemoteControlPlay, .RemoteControlPause, .RemoteControlTogglePlayPause:
                self.streamingController.setIsPlaying(!self.streamingController.isPlaying, callback: nil)
            
            case .RemoteControlNextTrack:
                self.streamingController.skipNext(nil)
                
            case .RemoteControlPreviousTrack:
                self.streamingController.skipPrevious(nil)
                
            default:
                break
            }
        }
    }
    
    // UIApplicationDelegate
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // start receiving remote control events
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
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
        if let urlHandler = self.urlHandler {
            return urlHandler(url)
        }
        else {
            return false
        }
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
        Appirater.appEnteredForeground(true)
    }
}
