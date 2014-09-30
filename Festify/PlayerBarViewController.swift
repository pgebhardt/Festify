//
//  TrackPlayerBarViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerBarViewController: UIViewController {
    @IBOutlet var trackLabel: UILabel!
    @IBOutlet var coverArtImageView: UIImageView!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    
    var nowPlayingCenterTrackInfo = Dictionary<String, AnyObject>()
    
    deinit {
        // cleanup all observations
        if let streamingController = self.streamingController {
            streamingController.removeObserver(self, forKeyPath: "isPlaying")
            streamingController.removeObserver(self, forKeyPath: "currentTrackMetadata")
        }
    }

    var streamingController: SPTAudioStreamingController! {
    willSet {
        // cleanup all observations
        if let streamingController = self.streamingController {
            streamingController.removeObserver(self, forKeyPath: "isPlaying")
            streamingController.removeObserver(self, forKeyPath: "currentTrackMetadata")
        }
    }
    
    didSet {
        if let streamingController = self.streamingController {
            // observe playback state change and track change to update UI accordingly
            streamingController.addObserver(self, forKeyPath: "isPlaying", options: nil, context: nil)
            streamingController.addObserver(self, forKeyPath: "currentTrackMetadata", options: nil, context: nil)
            
            // initialy setup UI correctly
            self.updateTrackInfo(streamingController.currentTrackMetadata)
            self.updatePlayButton(streamingController.isPlaying)
        }
    }
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<()>) {
        if keyPath == "currentTrackMetadata" {
            self.updateTrackInfo(self.streamingController.currentTrackMetadata)
        }
        else if keyPath == "isPlaying" {
            self.updatePlayButton(self.streamingController.isPlaying)
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "showTrackPlayer" {
            let viewController = ((segue.destinationViewController as UINavigationController).viewControllers[0] as PlayerViewController)
            
            viewController.streamingController = self.streamingController
            viewController.coverArt = self.coverArtImageView.image
        }
    }
    
    @IBAction func playButtonPressed(sender: AnyObject?) {
        self.streamingController.setIsPlaying(!self.streamingController.isPlaying, callback: nil)
    }
    
    func updatePlayButton(playing: Bool) {
        // update playback position and rate to avoid apple tv and lockscreen glitches
        self.nowPlayingCenterTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        self.nowPlayingCenterTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.streamingController.currentPlaybackPosition
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.nowPlayingCenterTrackInfo
        
        dispatch_async(dispatch_get_main_queue()) {
            if playing {
                self.playButton.setImage(UIImage(named: "Pause"), forState: .Normal)
            }
            else {
                self.playButton.setImage(UIImage(named: "Play"), forState: .Normal)
            }
        }
    }
    
    func updateTrackInfo(trackMetadata: [NSObject: AnyObject]?) {
        if let trackMetadata = trackMetadata {        // update track info dictionary and NowPlayingCenter
            dispatch_async(dispatch_get_main_queue()) {
                self.trackLabel.text = trackMetadata[SPTAudioStreamingMetadataTrackName]! as? String
                self.artistLabel.text = trackMetadata[SPTAudioStreamingMetadataArtistName]! as? String
            }
            
            // update now playing center with track info
            self.nowPlayingCenterTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            self.nowPlayingCenterTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            self.nowPlayingCenterTrackInfo[MPMediaItemPropertyTitle] = trackMetadata[SPTAudioStreamingMetadataTrackName]
            self.nowPlayingCenterTrackInfo[MPMediaItemPropertyAlbumTitle] = trackMetadata[SPTAudioStreamingMetadataAlbumName]
            self.nowPlayingCenterTrackInfo[MPMediaItemPropertyArtist] = trackMetadata[SPTAudioStreamingMetadataArtistName]
            self.nowPlayingCenterTrackInfo[MPMediaItemPropertyPlaybackDuration] = trackMetadata[SPTAudioStreamingMetadataTrackDuration]
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.nowPlayingCenterTrackInfo
            
            // download image album cover for current track
            SPTAlbum.albumWithURI(NSURL(string: (trackMetadata[SPTAudioStreamingMetadataAlbumURI]! as String)), session: nil) {
                (error: NSError?, object: AnyObject?) in
                if let album = object as? SPTAlbum {
                    NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: album.largestCover.imageURL), completionHandler: {
                        (data: NSData?, response: NSURLResponse!, errror: NSError?) in
                        dispatch_async(dispatch_get_main_queue()) {
                            if let data = data {
                                self.coverArtImageView.image = UIImage(data: data)
                            }
                            else {
                                self.coverArtImageView.image = UIImage(named: "DefaultCoverArt")
                            }

                            self.nowPlayingCenterTrackInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: self.coverArtImageView.image)
                            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = self.nowPlayingCenterTrackInfo
                        }
                    }).resume()
                }
            }
        }
    }
}
