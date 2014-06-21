//
//  PlaylistViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class PlaylistViewController: UITableViewController {
    var trackPlayer: SMTrackPlayer!
    
    @IBAction func done(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
 
    // Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.trackPlayer.currentProvider.tracksForPlayback().count
    }
    
    // Table view delegate
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        let trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracksForPlayback().count
        let track: SPTPartialTrack = self.trackPlayer.currentProvider.tracksForPlayback()[trackIndex] as SPTPartialTrack
        
        cell.textLabel.text = track.name
        cell.detailTextLabel.text = (track.artists[0] as SPTPartialArtist).name
        
        return cell
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)  {
        let trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracksForPlayback().count
        
        self.trackPlayer.skipToTrack(trackIndex)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}