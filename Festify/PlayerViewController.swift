//
//  PlayerViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 22/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var coverImage: UIImageView!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var trackPosition: UIProgressView!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    var trackPlayer: SMTrackPlayer!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // observe playback state change and track change to update UI accordingly
        self.trackPlayer.addObserver(self, forKeyPath: "playing", options: nil, context: nil)
        self.trackPlayer.addObserver(self, forKeyPath: "currentPlaybackPosition", options: nil, context: nil)
        self.trackPlayer.addObserver(self, forKeyPath: "currentTrack", options: nil, context: nil)
        self.trackPlayer.addObserver(self, forKeyPath: "coverArtOfCurrentTrack", options: nil, context: nil)
        
        // initialy setup UI correctly
        self.updateTrackInfo(self.trackPlayer.currentTrack)
        self.updateCoverArt(self.trackPlayer.coverArtOfCurrentTrack)
        self.updatePlayButton(self.trackPlayer.playing)
        self.updatePlaybackPosition(self.trackPlayer.currentPlaybackPosition, andDuration: self.trackPlayer.currentTrack.duration)
    }
    
    override func viewWillDisappear(animated: Bool)  {
        super.viewWillDisappear(animated)
        
        // remove observers
        self.trackPlayer.removeObserver(self, forKeyPath: "playing")
        self.trackPlayer.removeObserver(self, forKeyPath: "currentPlaybackPosition")
        self.trackPlayer.removeObserver(self, forKeyPath: "currentTrack")
        self.trackPlayer.removeObserver(self, forKeyPath: "coverArtOfCurrentTrack")
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: NSDictionary!, context: CMutableVoidPointer) {
        if keyPath == "playing" {
            self.updatePlayButton(self.trackPlayer.playing)
        }
        else if keyPath == "currentPlaybackPosition" {
            self.updatePlaybackPosition(self.trackPlayer.currentPlaybackPosition, andDuration: self.trackPlayer.currentTrack.duration)
        }
        else if keyPath == "currentTrack" {
            self.updateTrackInfo(self.trackPlayer.currentTrack)
        }
        else if keyPath == "coverArtOfCurrentTrack" {
            self.updateCoverArt(self.trackPlayer.coverArtOfCurrentTrack)
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "showPlaylist" {
            let navigationController = segue.destinationViewController as UINavigationController
            let viewController = navigationController.viewControllers[0] as PlaylistViewController
            
            navigationController.modalTransitionStyle = .CrossDissolve
            viewController.trackPlayer = self.trackPlayer
        }
    }
    
    @IBAction func rewind(sender: AnyObject?) {
        self.trackPlayer.skipBackward()
    }
    
    @IBAction func playPause(sender: AnyObject?) {
        if self.trackPlayer.playing {
            self.trackPlayer.pause()
        }
        else {
            self.trackPlayer.play()
        }
    }
    
    @IBAction func fastForward(sender: AnyObject?) {
        self.trackPlayer.skipForward()
    }
    
    @IBAction func openInSpotify(sender: AnyObject?) {
        // open currently played track in spotify app, if available
        if SPTAuth.defaultInstance().spotifyApplicationIsInstalled() {
            let url = NSURL(string: "spotify://" + self.trackPlayer.currentTrack.uri.absoluteString)
            
            self.trackPlayer.pause()
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func done(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updatePlayButton(playing: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            if playing {
                self.playPauseButton.setImage(UIImage(named: "Pause"), forState: .Normal)
            }
            else {
                self.playPauseButton.setImage(UIImage(named: "Play"), forState: .Normal)
            }
        }
    }
    
    func updatePlaybackPosition(playbackPosition: Double, andDuration duration: Double) {
        dispatch_async(dispatch_get_main_queue()) {
            self.trackPosition.progress = CFloat(playbackPosition / duration)
            self.currentTimeLabel.text = NSString(format: "%d:%02d", Int(playbackPosition / 60.0), Int(playbackPosition % 60.0))
            self.remainingTimeLabel.text = NSString(format:"%d:%02d", Int((playbackPosition - duration) / 60.0),
                Int((duration - playbackPosition) % 60.0))
        }
    }
    
    func updateTrackInfo(track: SPTTrack) {
        dispatch_async(dispatch_get_main_queue()) {
            self.titleLabel.text = track.name
            self.artistLabel.text = (track.artists[0] as SPTPartialArtist).name
        }
    }
    
    func updateCoverArt(coverArt: UIImage?) {
        dispatch_async(dispatch_get_main_queue()) {
            if let coverArt = coverArt {
                self.coverImage.image = coverArt
            }
            else {
                self.coverImage.image = UIImage(named:"DefaultCoverArt")
            }
        }
    }
}