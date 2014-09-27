//
//  FestifyViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 23/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class FestifyViewController: UIViewController, SMDiscoveryManagerDelegate, TrackPlayerDelegate, SMTrackProviderDelegate, LoginViewDelegate, SMSettingsViewDelegate {
    @IBOutlet var trackPlayerBarPosition: NSLayoutConstraint!
    @IBOutlet var usersButton: UIBarButtonItem!
    
    let trackPlayer = (UIApplication.sharedApplication().delegate as AppDelegate).trackPlayer
    let trackProvider = SMTrackProvider()
    var trackPlayerBar: PlayerBarViewController!
    var progressHUD: MBProgressHUD?
    
    // make sure all user relevant stored properties are stored correctly
    // in NSUserDefaults database
    var session: SPTSession? {
    didSet {
        if let session = self.session {
            NSUserDefaults.standardUserDefaults().setValue(
                NSKeyedArchiver.archivedDataWithRootObject(session),
                forKey: "SMUserDefaultsSpotifySessionKey")
        }
        else {
            NSUserDefaults.standardUserDefaults().setValue(nil,
                forKey: "SMUserDefaultsSpotifySessionKey")
        }
    }
    }
    
    var advertisedPlaylists: [String] = [String]() {
    didSet {
        NSUserDefaults.standardUserDefaults().setValue(self.advertisedPlaylists,
            forKey: "SMUserDefaultsAdvertisedPlaylistsKey")
    }
    }

    var advertisementState: Bool {
    get {
        return SMDiscoveryManager.sharedInstance().advertising
    }
    set {
        if newValue {
            // create broadcast disctionary with username and all playlists
            let broadcastData = ["username": self.session!.canonicalUsername,
                "playlists": self.advertisedPlaylists]
            let jsonData = NSJSONSerialization.dataWithJSONObject(broadcastData, options: nil, error: nil)
            SMDiscoveryManager.sharedInstance().advertiseProperty(jsonData)
        }
        else {
            SMDiscoveryManager.sharedInstance().stopAdvertising()
        }
        
        NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "SMUserDefaultsAdvertisementStateKey")
    }
    }
    
    var usersTimeout: Int = 120 {
    didSet {
        NSUserDefaults.standardUserDefaults().setValue(self.usersTimeout, forKey: "SMUserDefaultsUserTimeoutKey")
        
        // update timeout value for all users in track provider
        for username in self.trackProvider.users.allKeys as [String] {
            self.trackProvider.updateTimeoutInterval(usersTimeout, forUser: username)
        }
    }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // listen to notifications to update application state correctly
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "discoveryManagerDidUpdateState:",
            name: "SMDiscoveryManagerDidUpdateAdvertisementState", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "discoveryManagerDidUpdateState:",
            name: "SMDiscoveryManagerDidUpdateDiscoveryState", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "trackProviderDidUpdateTracks:",
            name: "SMTrackProviderDidUpdateTracksArray", object: nil)

        // init delegations and track player bar
        SMDiscoveryManager.sharedInstance().delegate = self
        self.trackPlayerBar.trackPlayer = self.trackPlayer
        self.trackPlayer.delegate = self
        self.trackProvider.delegate = self

        // load spotify session from user defaults
        if let sessionData = NSUserDefaults.standardUserDefaults().valueForKey("SMUserDefaultsSpotifySessionKey") as? NSData {
            self.session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? SPTSession
        }
        
        // if session is available, try to enable playback, or show login screen
        if let session = self.session {
            // try to enable playback of track player with new session
            self.trackPlayer.enablePlaybackWithSession(session) {
                (error: NSError?) in
                // load users defaults
                self.advertisedPlaylists = NSUserDefaults.standardUserDefaults().valueForKey("SMUserDefaultsAdvertisedPlaylistsKey") as [String]
                self.usersTimeout = NSUserDefaults.standardUserDefaults().valueForKey("SMUserDefaultsUserTimeoutKey") as Int
                self.advertisementState = NSUserDefaults.standardUserDefaults().valueForKey("SMUserDefaultsAdvertisementStateKey") as Bool
            }
        }
        else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.performSegueWithIdentifier("showLogin", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "showLogin" {
            let loginView = segue.destinationViewController as LoginViewController
            loginView.delegate = self
            loginView.modalTransitionStyle = .CrossDissolve
        }
        else if segue.identifier == "showSettings" {
            let settingsView = (segue.destinationViewController as UINavigationController).viewControllers[0] as SMSettingsViewController
            settingsView.session = self.session
            settingsView.delegate = self
        }
        else if segue.identifier == "showUsers" {
            let usersView = (segue.destinationViewController as UINavigationController).viewControllers[0] as SMUsersViewController
            usersView.trackProvider = self.trackProvider
        }
        else if segue.identifier == "loadPlayerBar" {
            self.trackPlayerBar = segue.destinationViewController as PlayerBarViewController
        }
    }
    
    @IBAction func spotifyButton(sender: AnyObject?) {
        // open either spotify website or app, if available
        if SPTAuth.defaultInstance().spotifyApplicationIsInstalled() {
            UIApplication.sharedApplication().openURL(NSURL(string:"spotify//open"))
        }
        else {
            UIApplication.sharedApplication().openURL(NSURL(string:"http://www.spotify.com"))
        }
    }
    
    func discoveryManager(discoveryManager: SMDiscoveryManager!, didDiscoverDevice devicename: String!, withProperty property: NSData!) {
        // extract spotify username and indicesOfSelectedPlaylists from device property
        if let advertisedData = NSJSONSerialization.JSONObjectWithData(property, options: nil, error: nil) as? NSDictionary {
            let playlists = advertisedData["playlists"] as? [String]
            let username = advertisedData["username"] as? String
            
            // request all playlists and add them to the track provider
            SPTPlaylistSnapshot.playlistsWithURIs(playlists?.map({ NSURL(string:  $0)}), session: self.session!) {
                (error: NSError?, object: AnyObject?) in
                self.trackProvider.setPlaylists(object as? [AnyObject], forUser: username, withTimeoutInterval: self.usersTimeout, session: self.session)
            }
        }
    }
    
    func discoveryManagerDidUpdateState(notification: AnyObject?) {
        // add all currently advertised songs, if festify and advertisement modes are active
        if SMDiscoveryManager.sharedInstance().discovering &&
            SMDiscoveryManager.sharedInstance().advertising {
                SPTPlaylistSnapshot.playlistsWithURIs(self.advertisedPlaylists.map({ NSURL(string:  $0)}), session: self.session!) {
                    (error: NSError?, object: AnyObject?) in
                    self.trackProvider.setPlaylists(object as? [AnyObject], forUser: self.session?.canonicalUsername, withTimeoutInterval: 0, session: self.session)
                }
        }
    }
    
    func trackProvider(trackProvider: SMTrackProvider!, willDeleteUser username: String!) {
        // restart discovery manager to rescan for all available devices to possibly prevent
        // track provider from deleting the user
        if SMDiscoveryManager.sharedInstance().discovering {
            SMDiscoveryManager.sharedInstance().startDiscovering()
        }
    }
    
    func trackProviderDidUpdateTracks(notification: AnyObject?) {
        // initialize track player to play tracks from track provider
        if self.trackProvider.tracksForPlayback().count != 0 {
            if self.trackPlayer.currentProvider == nil {
                self.trackPlayer.playTrackProvider(self.trackProvider)
            }
        }
        // clean up track player, if no tracks are available anymore
        // and return to main screen, to avoid viewing an unusuable
        // player screen, or similar
        else {
            self.trackPlayer.clear()
            self.dismissViewControllerAnimated(true, completion: nil)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        
        // update UI
        dispatch_async(dispatch_get_main_queue()) {
            self.usersButton.enabled = self.trackProvider.users.count != 0
            
            // show or hide track player bar
            self.trackPlayerBarPosition.constant = (self.trackPlayer.currentProvider != nil) ? 0.0 : -44.0
            UIView.animateWithDuration(0.4) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func trackPlayer(trackPlayer: TrackPlayer, couldNotEnablePlaybackWithSession session: SPTSession?, error: NSError) {
        if error.code == 9 {
            // if playback could not be enabled due to a missing spotify premium
            // subscribtion, ignore error and hide progress HUD
            self.progressHUD?.hide(true)
            self.progressHUD = nil
        }
        else {
            // try to renew session, and logout if it fails
            LoginViewController.renewSpotifySession(session) {
                (session: SPTSession?, error: NSError?) in
                if error != nil {
                    self.progressHUD?.hide(true)
                    self.progressHUD = nil
                    
                    self.logoutOfSpotify()
                }
                else {
                    self.session = session
                    self.trackPlayer.enablePlaybackWithSession(self.session!, callback: nil)
                }
            }
        }
    }
    
    func trackPlayer(trackPlayer: TrackPlayer, didEnablePlaybackWithSession session: SPTSession?) {
        // when playback is successfully enabled unlock the UI by hiding the
        // progress hud
        self.progressHUD?.hide(true)
        self.progressHUD = nil
    }
    
    func trackPlayer(trackPlayer: TrackPlayer, willEnablePlaybackWithSession session: SPTSession?) {
        // show progress hud on top of the window to indicatie the process and
        // block all UI interactions
        if self.progressHUD == nil {
            let window = (UIApplication.sharedApplication().delegate as AppDelegate).window
            self.progressHUD = MBProgressHUD.showHUDAddedTo(window!.subviews[0] as UIView, animated: true)
            self.progressHUD!.labelText = "Connecting ..."
        }
    }

    func loginViewDidReturnFromExternalSignUp(loginView: LoginViewController) {
        // hide login view and block UI with progress hud
        loginView.dismissViewControllerAnimated(false, completion: nil)
        self.progressHUD = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true)
        self.progressHUD!.labelText = "Logging in ..."
    }
    
    func loginView(loginView: LoginViewController, didCompleteLoginWithSession session: SPTSession)  {
        // store new session to user defaults
        self.session = session
        
        // initialize default values for user settings
        SPTRequest.playlistsForUserInSession(self.session) {
            (error: NSError?, object: AnyObject?) in
            // request all playlists for the user and advertise them
            self.advertisedPlaylists = ((object as SPTPlaylistList).items as [SPTPartialPlaylist]).map({ $0.uri.absoluteString! })
            self.usersTimeout = 120
            self.advertisementState = true
        }
        
        // try to enable playback, an error should only occure,
        // when user does not have a premium subscribtion
        self.trackPlayer.enablePlaybackWithSession(self.session!) {
            (error: NSError?) in
            if error != nil {
                let alert = UIAlertController(title: "No Spotify Premuim subscription detected!",
                    message: "You will be able to use all features of Festify, except playing music.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }

    func loginView(loginView: LoginViewController, didCompleteLoginWithError error: NSError) {
        let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default) {
            (action: UIAlertAction?) in
            // hide progress HUD and show login view
            self.progressHUD?.hide(true)
            self.progressHUD = nil
            
            self.performSegueWithIdentifier("showLogin", sender: self)
        })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func settingsView(settingsView: SMSettingsViewController!, didChangeAdvertisedPlaylistSelection selectedPlaylists: [AnyObject]!) {
        self.advertisedPlaylists = selectedPlaylists as [String]
    
        // reset advertisement state to update advertised playlist selection
        self.advertisementState = SMDiscoveryManager.sharedInstance().advertising
    }
    
    func settingsView(settingsView: SMSettingsViewController!, didChangeAdvertisementState advertising: Bool) {
        self.advertisementState = advertising
    }
    
    func settingsView(settingsView: SMSettingsViewController!, didChangeUsersTimeout usersTimeout: Int) {
        self.usersTimeout = usersTimeout
    }
    
    func settingsViewDidRequestLogout(settingsView: SMSettingsViewController!) {
        self.logoutOfSpotify()
    }
    
    func logoutOfSpotify() {
        // stop advertisiement and discovery and clear all settings
        SMDiscoveryManager.sharedInstance().stopDiscovering()
        SMDiscoveryManager.sharedInstance().stopAdvertising()
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        
        // cleanup spotify objects
        self.session = nil
        self.trackProvider.clear()
        self.trackPlayer.logout()
        
        self.performSegueWithIdentifier("showLogin", sender: self)
    }
}
