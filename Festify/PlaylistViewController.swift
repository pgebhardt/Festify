//
//  PlaylistViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 21/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class PlaylistViewController: UITableViewController {
    var streamingController: SPTAudioStreamingController! = nil

    @IBAction func done(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    // Table view delegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        // TODO
        self.streamingController.getRelativeTrackMetadata(indexPath.row + 1) {
            (trackMetadata: [NSObject: AnyObject]!) in
            cell.textLabel!.text = trackMetadata[SPTAudioStreamingMetadataTrackName]! as? String
            cell.detailTextLabel!.text = trackMetadata[SPTAudioStreamingMetadataArtistName]! as? String
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)  {
        // TODO:
        /*for _ in 1...indexPath.row {
            self.streamingController.skipNext(nil)
        }*/
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}