//
//  SettingsViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 28/09/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit
import MessageUI

protocol SettingsViewDelegate {
    func settingsViewDidRequestLogout(settingsView: SettingsViewController)
    func settingsView(settingsView: SettingsViewController, didChangeAdvertisementState advertising: Bool)
    func settingsView(settingsView: SettingsViewController, didChangeAdvertisedPlaylistSelection selectedPlaylists: [String])
    func settingsView(settingsView: SettingsViewController, didChangeUsersTimeout: Int)
}

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet var advertisementSwitch: UISwitch!
    @IBOutlet var playlistNumberLabel: UILabel!
    @IBOutlet var playlistActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var timeoutLabel: UILabel!
    @IBOutlet var logoutLabel: UILabel!
    @IBOutlet var versionLabel: UILabel!
    
    var playlists: [SPTPartialPlaylist]! = nil
    var advertisedPlaylists: [String]! = nil
    var usersTimeout: Int? = nil
    var session: SPTSession! = nil
    var delegate: SettingsViewDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // connect switches to event handler and set them to correct state
        self.advertisementSwitch.addTarget(self, action: "toggleAdvertisementState:", forControlEvents: .ValueChanged)
        self.updateAdverisementSwitch()
        
        // collect playlists from currently logged in user to pass to playlist selection screen
        SPTRequest.playlistsForUserInSession(self.session) {
            (error: NSError?, object: AnyObject!) in
            if let error = error {
                NSLog("\(error)")
            }
            else {
                self.playlists = (object as SPTListPage).items as [SPTPartialPlaylist]
                
                // update UI
                self.playlistActivityIndicator.stopAnimating()
                self.playlistNumberLabel.hidden = false
                self.updateAdvertisedPlaylistsCell()
            }
        }
        
        // update UI
        let version = NSBundle.mainBundle().infoDictionary["CFBundleShortVersionString"]! as String
        let build = NSBundle.mainBundle().infoDictionary[kCFBundleVersionKey]! as String
        
        self.timeoutLabel.text = self.timeoutToString(self.usersTimeout!)
        self.logoutLabel.text = "Log Out \(self.session.canonicalUsername)"
        self.versionLabel.text = "\(version) (\(build))"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Observe changes in advertisement state
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAdverisementSwitch", name: "SMDiscoveryManagerDidUpdateAdvertisementState", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove all observations
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showVisiblePlaylists" {
            
        }
        else if segue.identifier == "showUserTimeout" {
            
        }
        else if segue.identifier == "showAcknowledgements" {
            // load acknowledgements from plist file
            if let path = NSBundle.mainBundle().pathForResource("Pods-acknowledgements", ofType: "markdown") {
                let acknowledgements = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
                
                let textView = (segue.destinationViewController as UIViewController).view.subviews[0] as UITextView
                textView.text = "\(textView.text)\n\n\(acknowledgements)"
                textView.textContainerInset = UIEdgeInsetsMake(12.0, 10.0, 12.0, 10.0)
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showVisiblePlaylists" && self.playlistActivityIndicator.isAnimating() {
            return false
        }
        return true
    }
    
    @IBAction func done(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func toggleAdvertisementState(sender: AnyObject?) {
        self.delegate?.settingsView(self, didChangeAdvertisementState: self.advertisementSwitch.on)
        
        // check if advertisement was not enabled and update UI accordingly
        if !SMDiscoveryManager.sharedInstance().advertising {
            self.advertisementSwitch.setOn(false, animated: true)
        }
    }
    
    func updateAdvertisedPlaylistsCell() {
        dispatch_async(dispatch_get_main_queue()) {
            switch self.advertisedPlaylists.count {
            case self.playlists.count:
                self.playlistNumberLabel.text = "All"
                
            case 0:
                self.playlistNumberLabel.text = "None"
                
            default:
                self.playlistNumberLabel.text = "Limited"
            }
        }
    }
    
    func updateAdverisementSwitch() {
        dispatch_async(dispatch_get_main_queue()) {
            self.advertisementSwitch.setOn(SMDiscoveryManager.sharedInstance().advertising, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // handle action for specific cell
        if let identifier = tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier {
            if identifier == "logoutCell" {
                self.dismissViewControllerAnimated(true) {
                    self.delegate?.settingsViewDidRequestLogout(self)
                    return // To avoid swift compiler bug!!
                }
            }
            else if identifier == "contactCell" {
                // add some basic debug information to default message
                let appName = NSBundle.mainBundle().bundleIdentifier!
                let appVersion = NSBundle.mainBundle().infoDictionary["CFBundleShortVersionString"]! as String
                let appBuild = NSBundle.mainBundle().infoDictionary[kCFBundleVersionKey]! as String
                let deviceName = self.deviceString()
                let osVersion = UIDevice.currentDevice().systemVersion
                
                // create mail composer to send feedback to me
                var mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setSubject("Support")
                mailComposer.setToRecipients(["support+festify@schnuffmade.com"])
                mailComposer.setMessageBody("\n\n-----\nApp: \(appName) \(appVersion) (\(appBuild))\nDevice: \(deviceName) (\(osVersion))", isHTML: false)
                self.presentViewController(mailComposer, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func timeoutToString(timeout: Int) -> String {
        if timeout == 0 {
            return "Never"
        }
        else if timeout < 60 {
            return "After \(timeout) min"
        }
        else {
            return "After \(timeout / 60) h"
        }
    }
    
    func deviceString() -> String {
        var size: UInt = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        
        var machine = [CChar](count: Int(size), repeatedValue: 0)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        
        return String.fromCString(machine)!
    }
}

