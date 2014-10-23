//
//  TrackProvider.swift
//  Festify
//
//  Created by Patrik Gebhardt on 30/09/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import Foundation

protocol TrackProviderDelegate {
    func trackProvider(trackProvider: TrackProvider, willDeleteUser username: String)
}

class TrackProvider: NSObject, SPTTrackProvider {
    class UserInfo: NSObject {
        var playlists: [String: [SPTTrack]]
        var timeout: Int = 0 {
        didSet {
            // remove timer, if timeout = 0
            if self.timeout == 0 {
                self.timer?.invalidate()
                self.timer = nil
            }
            // create or update timer to delete user from track provider after
            // timeout has expired
            else {
                if let timer = self.timer {
                    timer.fireDate = NSDate(timeInterval: Double(self.timeout - 1) * 60.0, sinceDate: self.lastUpdated)
                }
                else {
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(Double(self.timeout - 1) * 60.0, target: self, selector: "timerHasExpired", userInfo: nil, repeats: false)
                }
            }
        }
        }
        
        var timer: NSTimer? = nil
        var lastUpdated = NSDate()
        var deletionWarningSent = false
        var callback: ((UserInfo) -> ())! = nil
        
        init(playlists: [String: [SPTTrack]], timeout: Int, callback: ((UserInfo) -> ())) {
            self.playlists = playlists
            self.timeout = timeout
            self.callback = callback
        }

        deinit {
            self.timer?.invalidate()
        }
        
        func timerHasExpired() {
            self.timer = nil
            self.callback(self)
        }
    }
    
    var users = Dictionary<String, UserInfo>()
    dynamic var tracks = NSMutableArray()
    var delegate: TrackProviderDelegate?
    
    override init() {
        super.init()
        
        // init random number generator
        srandom(UInt32(time(nil)))
            
        // register to enter foreground notification to check and restart all timers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "restoreTimersAfterSuspension:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func tracksForPlayback() -> [AnyObject]! {
        return self.tracks
    }
    
    func playableUri() -> NSURL! {
        return nil
    }
    
    func setPlaylists(playlists: [SPTPlaylistSnapshot], forUser username: String, withTimeout timeout: Int) {
        var userTracks = [String: [SPTTrack]]()
        
        // request all tracks of all playlists
        for playlist in playlists {
            playlist.allTracksWithSession(nil) {
                (tracks: [AnyObject]!, error: NSError?) in
                if error == nil {
                    userTracks[playlist.name] = tracks as? [SPTTrack]
                }
                
                if playlist == playlists.last {
                    if let user = self.users[username] {
                        user.playlists = userTracks
                        user.timeout = timeout
                    }
                    else {
                        self.users[username] = UserInfo(playlists: userTracks, timeout: timeout, callback: {
                            (user: UserInfo) in
                            // delete user from track provider if deletion warning was sent,
                            // or inform delegate to update user within 1 minute
                            if user.deletionWarningSent {
                                self.removePlaylistsForUser(username)
                            }
                            else {
                                user.deletionWarningSent = true
                                user.timeout = 2
                                
                                // give delegate 2 min chance to search for user, befor deleting
                                self.delegate?.trackProvider(self, willDeleteUser: username)
                            }
                        })
                    }

                    self.updateTracksArray()
                }
            }
        }
    }
    
    func removePlaylistsForUser(username: String) {
        self.users[username] = nil
        self.updateTracksArray()
    }
    
    func clear() {
        for user in self.users.values {
            user.timer?.invalidate()
        }
        
        self.tracks.removeAllObjects()
        self.users.removeAll(keepCapacity: false)
    }
    
    func updateTracksArray() {
        var tracks = [SPTTrack]()
        for user in self.users.values {
            for playlist in user.playlists.values {
                tracks += playlist
            }
        }
        
        self.tracks.removeAllObjects()
        self.tracks.addObjectsFromArray(tracks)
        
        // shuffle tracks array
        for var i = 0; i < self.tracks.count; ++i {
            let elements = self.tracks.count - i
            let n = (random() % elements) + i
            self.tracks.exchangeObjectAtIndex(i, withObjectAtIndex: n)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("SMTrackProviderDidUpdateTracksArray", object: self)
    }
    
    func restoreTimersAfterSuspension(notification: NSNotification!) {
        // check all fire dates of the timers and either delete user or restart timer
        for user in self.users.values {
            if let timer = user.timer {
                let timeInterval = timer.fireDate.timeIntervalSinceNow
                
                if timeInterval <= 0.0 {
                    user.timerHasExpired()
                }
                else {
                    user.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: user, selector: "timerHasExpired", userInfo: nil, repeats: false)
                }
            }
        }
    }
}
