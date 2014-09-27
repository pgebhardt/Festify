//
//  TrackPlayer.swift
//  Festify
//
//  Created by Patrik Gebhardt on 26/09/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import Foundation
import MediaPlayer

protocol TrackPlayerDelegate {
    func trackPlayer(trackPlayer: TrackPlayer, willEnablePlaybackWithSession session: SPTSession?)
    func trackPlayer(trackPlayer: TrackPlayer, didEnablePlaybackWithSession session: SPTSession?)
    func trackPlayer(trackPlayer: TrackPlayer, couldNotEnablePlaybackWithSession session: SPTSession?, error: NSError)
}

class TrackPlayer: NSObject, SPTAudioStreamingPlaybackDelegate {
    dynamic var playing: Bool = false
    var session: SPTSession? = nil
    dynamic var trackMetadata: [NSObject: AnyObject!]? = nil
    dynamic var coverArtOfCurrentTrack: UIImage? = nil
    dynamic var currentPlaybackPosition: NSTimeInterval = 0.0
    var currentProvider: SPTTrackProvider? = nil
    let streamingController = SPTAudioStreamingController()
    var trackInfo = Dictionary<String, AnyObject>()
    var delegate: TrackPlayerDelegate? = nil
    
    override init() {
        super.init()
        
        // init streaming controller
        self.streamingController.repeat = true
        self.streamingController.playbackDelegate = self
        self.streamingController.addObserver(self, forKeyPath: "currentPlaybackPosition", options: nil, context: nil)
    }
    
    func enablePlaybackWithSession(session: SPTSession, callback: ((NSError?) -> ())?) {
        self.delegate?.trackPlayer(self, willEnablePlaybackWithSession: session)
        
        self.streamingController.loginWithSession(session) {
            (error: NSError?) in
            // save login session for relogin purpose
            self.session = session
            
            // call completion block
            callback?(error)
            
            if error == nil {
                self.delegate?.trackPlayer(self, didEnablePlaybackWithSession: session)
            }
            else {
                self.delegate?.trackPlayer(self, couldNotEnablePlaybackWithSession: session, error: error!)
            }
        }
    }
    
    func playTrackProvider(provider: SPTTrackProvider) {
        self.playTrackProvider(provider, fromIndex: 0)
    }
    
    func playTrackProvider(provider: SPTTrackProvider, fromIndex index: Int) {
        self.performActionWithConnectivityCheck() {
            self.currentProvider = provider
            
            self.streamingController.playTrackProvider(provider, fromIndex: Int32(index), callback: nil)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        if keyPath == "currentPlaybackPosition" {
            self.currentPlaybackPosition = self.streamingController.currentPlaybackPosition
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func clear() {
        self.pause()
        
        self.currentProvider = nil
        self.trackMetadata = nil
        self.currentPlaybackPosition = 0.0
        self.coverArtOfCurrentTrack = nil
    }
    
    func logout() {
        self.streamingController.logout() {
            (error: NSError?) in
            self.session = nil
            self.clear()
        }
    }
    
    func play() {
        if self.currentProvider != nil && !self.playing {
            self.performActionWithConnectivityCheck() {
                self.streamingController.setIsPlaying(true) {
                    (error: NSError?) in
                    if error != nil {
                        // update playback position and rate to avoid apple tv and lockscreen glitches
                        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                        self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.streamingController.currentPlaybackPosition
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.trackInfo
                    }
                }
            }
        }
    }
    
    func pause() {
        if self.currentProvider != nil && self.playing {
            self.performActionWithConnectivityCheck() {
                self.streamingController.setIsPlaying(false) {
                    (error: NSError?) in
                    if error != nil {
                        // update playback position and rate to avoid apple tv and lockscreen glitches
                        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                        self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.streamingController.currentPlaybackPosition
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.trackInfo
                    }
                }
            }
        }
    }
    
    func skipToTrack(index: Int) {
        if self.currentProvider != nil {
            self.performActionWithConnectivityCheck() {
                self.streamingController.playTrackProvider(self.currentProvider, fromIndex: Int32(index), callback: nil)
                self.play()
            }
        }
    }
    
    func skipForward() {
        if self.currentProvider != nil {
            self.performActionWithConnectivityCheck() {
                self.streamingController.skipNext(nil)
                self.play()
            }
        }
    }
    
    func skipBackward() {
        if self.currentProvider != nil {
            self.performActionWithConnectivityCheck() {
                self.streamingController.skipPrevious(nil)
                self.play()
            }
        }
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.playing = isPlaying
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!,
        didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        self.trackMetadata = trackMetadata
        self.playing = true
            
        // update track info dictionary and NowPlayingCenter
        self.trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        self.trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        self.trackInfo[MPMediaItemPropertyTitle] = self.trackMetadata![SPTAudioStreamingMetadataTrackName]
        self.trackInfo[MPMediaItemPropertyAlbumTitle] = self.trackMetadata![SPTAudioStreamingMetadataAlbumName]
        self.trackInfo[MPMediaItemPropertyArtist] = self.trackMetadata![SPTAudioStreamingMetadataArtistName]
            self.trackInfo[MPMediaItemPropertyPlaybackDuration] = self.trackMetadata![SPTAudioStreamingMetadataTrackDuration]
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.trackInfo
            
        // download image album cover for current track
        SPTAlbum.albumWithURI(NSURL(string: (self.trackMetadata![SPTAudioStreamingMetadataAlbumURI]! as String)), session: self.session!) {
            (error: NSError?, object: AnyObject?) in
            if let album = object as? SPTAlbum {
                NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: album.largestCover.imageURL), completionHandler: {
                    (data: NSData?, response: NSURLResponse!, errror: NSError?) in
                    if let data = data {
                        self.coverArtOfCurrentTrack = UIImage(data: data)
                        self.trackInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: self.coverArtOfCurrentTrack)
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.trackInfo
                    }
                    
                }).resume()
            }
        }
    }
    
    func performActionWithConnectivityCheck(action: (() -> ())) {
        if !self.streamingController.loggedIn ||
            (UIApplication.sharedApplication().applicationState != .Active && !self.playing) {
            let backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({});
                
            self.enablePlaybackWithSession(self.session!) {
                (error: NSError?) in
                if error == nil {
                    action()
                }
                
                UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
            }
        }
        else {
            action()
        }
    }
}
