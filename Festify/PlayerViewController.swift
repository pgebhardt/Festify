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
    var streamingController: SPTAudioStreamingController! = nil
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // observe playback state change and track change to update UI accordingly
        self.streamingController.addObserver(self, forKeyPath: "isPlaying", options: nil, context: nil)
        self.streamingController.addObserver(self, forKeyPath: "currentPlaybackPosition", options: nil, context: nil)
        self.streamingController.addObserver(self, forKeyPath: "currentTrackMetadata", options: nil, context: nil)
        
        // initialy setup UI correctly
        if let currentTrackMetadata = self.streamingController.currentTrackMetadata {
            self.updateTrackInfo(currentTrackMetadata)
            // self.updateCoverArt(currentTrackMetadata)
            self.updatePlayButton(self.streamingController.isPlaying)
            self.updatePlaybackPosition(self.streamingController.currentPlaybackPosition,
                andDuration: currentTrackMetadata[SPTAudioStreamingMetadataTrackDuration]! as Double)
        }
    }
    
    override func viewWillDisappear(animated: Bool)  {
        super.viewWillDisappear(animated)
        
        // remove observers
        self.streamingController.removeObserver(self, forKeyPath: "isPlaying")
        self.streamingController.removeObserver(self, forKeyPath: "currentPlaybackPosition")
        self.streamingController.removeObserver(self, forKeyPath: "currentTrackMetadata")
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<()>) {
        if keyPath == "isPlaying" {
            self.updatePlayButton(self.streamingController.isPlaying)
        }
        else if keyPath == "currentPlaybackPosition" {
            self.updatePlaybackPosition(self.streamingController.currentPlaybackPosition,
                andDuration: self.streamingController.currentTrackMetadata![SPTAudioStreamingMetadataTrackDuration]! as Double)
        }
        else if keyPath == "currentTrackMetadata" {
            self.updateTrackInfo(self.streamingController.currentTrackMetadata)
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "showPlaylist" {
            let navigationController = segue.destinationViewController as UINavigationController
            let viewController = navigationController.viewControllers[0] as PlaylistViewController
            
            navigationController.modalTransitionStyle = .CrossDissolve
            viewController.streamingController = self.streamingController
        }
    }
    
    @IBAction func rewind(sender: AnyObject?) {
        self.streamingController.skipPrevious(nil)
    }
    
    @IBAction func playPause(sender: AnyObject?) {
        self.streamingController.setIsPlaying(!self.streamingController.isPlaying, callback: nil)
    }
    
    @IBAction func fastForward(sender: AnyObject?) {
        self.streamingController.skipNext(nil)
    }
    
    @IBAction func openInSpotify(sender: AnyObject?) {
        // open currently played track in spotify app, if available
        if SPTAuth.defaultInstance().spotifyApplicationIsInstalled() {
            let url = NSURL(string: "spotify://" + (self.streamingController.currentTrackMetadata![SPTAudioStreamingMetadataTrackURI]! as String))
            
            self.streamingController.setIsPlaying(false, callback: nil)
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
    
    func updateTrackInfo(trackMetadata: [NSObject: AnyObject]?) {
        if let trackMetadata = trackMetadata {
            dispatch_async(dispatch_get_main_queue()) {
                self.titleLabel.text = trackMetadata[SPTAudioStreamingMetadataTrackName]! as? String
                self.artistLabel.text = trackMetadata[SPTAudioStreamingMetadataArtistName]! as? String
            }
            
            // download image album cover for current track
            SPTAlbum.albumWithURI(NSURL(string: (trackMetadata[SPTAudioStreamingMetadataAlbumURI]! as String)), session: nil) {
                (error: NSError?, object: AnyObject?) in
                if let album = object as? SPTAlbum {
                    NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: album.largestCover.imageURL), completionHandler: {
                        (data: NSData?, response: NSURLResponse!, errror: NSError?) in
                        dispatch_async(dispatch_get_main_queue()) {
                            if let data = data {
                                self.coverImage.image = UIImage(data: data)
                            }
                            else {
                                self.coverImage.image = UIImage(named: "DefaultCoverArt")
                            }
                        }
                    }).resume()
                }
            }
        }
    }
}
