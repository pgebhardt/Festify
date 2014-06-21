//
//  PlaylistViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class PlaylistViewController: UITableViewController {
    var trackPlayer: SMTrackPlayer?
    
    @IBAction func done(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
 
    // Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        if let trackPlayer = self.trackPlayer {
            return trackPlayer.currentProvider.tracksForPlayback().count
        }
        else {
            return 0
        }
    }
    
    // Table view delegate
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        if let trackPlayer = self.trackPlayer {
            let trackIndex = (indexPath.row + trackPlayer.indexOfCurrentTrack + 1) % trackPlayer.currentProvider.tracksForPlayback().count
            let track: SPTPartialTrack = trackPlayer.currentProvider.tracksForPlayback()[trackIndex] as SPTPartialTrack
            
            cell.textLabel.text = track.name
            cell.detailTextLabel.text = (track.artists[0] as SPTPartialArtist).name
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)  {
        if let trackPlayer = self.trackPlayer {
            let trackIndex = (indexPath.row + trackPlayer.indexOfCurrentTrack + 1) % trackPlayer.currentProvider.tracksForPlayback().count
            
            trackPlayer.skipToTrack(trackIndex)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}