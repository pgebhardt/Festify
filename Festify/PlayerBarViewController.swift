//
//  TrackPlayerBarViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class PlayerBarViewController: UIViewController {
    @IBOutlet var trackLabel: UILabel!
    @IBOutlet var coverArtImageView: UIImageView!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    
    deinit {
        // cleanup all observations
        if let trackPlayer = self.trackPlayer {
            trackPlayer.removeObserver(self, forKeyPath: "playing")
            trackPlayer.removeObserver(self, forKeyPath: "currentTrack")
            trackPlayer.removeObserver(self, forKeyPath: "coverArtOfCurrentTrack")
        }
    }

    var trackPlayer: SMTrackPlayer! {
    willSet {
        // cleanup all observations
        if let trackPlayer = self.trackPlayer {
            trackPlayer.removeObserver(self, forKeyPath: "playing")
            trackPlayer.removeObserver(self, forKeyPath: "currentTrack")
            trackPlayer.removeObserver(self, forKeyPath: "coverArtOfCurrentTrack")
        }
    }
    
    didSet {
        if let trackPlayer = self.trackPlayer {
            // observe playback state change and track change to update UI accordingly
            trackPlayer.addObserver(self, forKeyPath: "playing", options: nil, context: nil)
            trackPlayer.addObserver(self, forKeyPath: "currentTrack", options: nil, context: nil)
            trackPlayer.addObserver(self, forKeyPath: "coverArtOfCurrentTrack", options: nil, context: nil)
            
            // initialy setup UI correctly
            self.updateTrackInfo(trackPlayer.currentTrack)
            self.updateCoverArt(trackPlayer.coverArtOfCurrentTrack)
            self.updatePlayButton(trackPlayer.playing)
        }
    }
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: NSDictionary!, context: CMutableVoidPointer) {
        if keyPath == "coverArtOfCurrentTrack" {
            self.updateCoverArt(self.trackPlayer.coverArtOfCurrentTrack)
        }
        else if keyPath == "currentTrack" {
            self.updateTrackInfo(self.trackPlayer.currentTrack)
        }
        else if keyPath == "playing" {
            self.updatePlayButton(self.trackPlayer.playing)
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "showTrackPlayer" {
            ((segue.destinationViewController as UINavigationController).viewControllers[0] as PlayerViewController).trackPlayer = self.trackPlayer
        }
    }
    
    @IBAction func playButtonPressed(sender: AnyObject?) {
        if self.trackPlayer.playing {
            self.trackPlayer.pause()
        }
        else {
            self.trackPlayer.play()
        }
    }
    
    func updatePlayButton(playing: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            if playing {
                self.playButton.setImage(UIImage(named: "Pause"), forState: .Normal)
            }
            else {
                self.playButton.setImage(UIImage(named: "Play"), forState: .Normal)
            }
        }
    }
    
    func updateTrackInfo(track: SPTTrack?) {
        if let track = track {
            dispatch_async(dispatch_get_main_queue()) {
                self.trackLabel.text = track.name
                self.artistLabel.text = (track.artists[0] as SPTPartialArtist).name
            }
        }
    }
    
    func updateCoverArt(coverArt: UIImage?) {
        dispatch_async(dispatch_get_main_queue()) {
            if let coverArt = coverArt {
                self.coverArtImageView.image = coverArt
            }
            else {
                self.coverArtImageView.image = UIImage(named: "DefaultCoverArt")
            }
        }
    }
}
