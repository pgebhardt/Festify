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
            // TODO: self.updateCoverArt(trackPlayer.coverArtOfCurrentTrack)
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
            ((segue.destinationViewController as UINavigationController).viewControllers[0] as PlayerViewController).streamingController = self.streamingController
        }
    }
    
    @IBAction func playButtonPressed(sender: AnyObject?) {
        self.streamingController.setIsPlaying(!self.streamingController.isPlaying, callback: nil)
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
    
    func updateTrackInfo(trackMetadata: [NSObject: AnyObject]?) {
        if let trackMetadata = trackMetadata {
            dispatch_async(dispatch_get_main_queue()) {
                self.trackLabel.text = trackMetadata[SPTAudioStreamingMetadataTrackName]! as? String
                self.artistLabel.text = trackMetadata[SPTAudioStreamingMetadataArtistName]! as? String
            }
            
            // download image album cover for current track
            SPTAlbum.albumWithURI(NSURL(string: (trackMetadata[SPTAudioStreamingMetadataAlbumURI]! as String)), session: nil) {
                (error: NSError?, object: AnyObject?) in
                if let album = object as? SPTAlbum {
                    NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: album.smallestCover.imageURL), completionHandler: {
                        (data: NSData?, response: NSURLResponse!, errror: NSError?) in
                        dispatch_async(dispatch_get_main_queue()) {
                            if let data = data {
                                self.coverArtImageView.image = UIImage(data: data)
                            }
                            else {
                                self.coverArtImageView.image = UIImage(named: "DefaultCoverArt")
                            }
                        }
                    }).resume()
                }
            }
        }
    }
}
