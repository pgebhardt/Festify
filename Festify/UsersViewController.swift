//
//  UsersViewController.swift
//  Festify
//
//  Created by Patrik Gebhardt on 30/09/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

import UIKit

class UsersViewController: UITableViewController {
    var trackProvider: TrackProvider! = nil
    var userIsExpanded: [Bool]! = nil
    var reloadTimer: NSTimer! = nil
    var usernameCellIndices: [NSIndexPath]! = nil
    
    @IBAction func done(sender: AnyObject!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userIsExpanded = [Bool](count: self.trackProvider.users.count, repeatedValue: false)
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // observe changes in track provider
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadData",
            name: "SMTrackProviderDidUpdateTracksArray", object: nil)
        self.updateUsernameCellIndicesArray()
        self.reloadTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "reloadUserCells", userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.reloadTimer.invalidate()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.trackProvider.users.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userIsExpanded[section] ? (self.trackProvider.users.values.array[section].playlists.count + 1) : 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = nil
        // cell to display username and time since user was detected
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("usernameCell", forIndexPath: indexPath) as UITableViewCell
            let time = -self.trackProvider.users.values.array[indexPath.section].lastUpdated.timeIntervalSinceNow
            
            cell.textLabel.text = self.trackProvider.users.keys.array[indexPath.section]
            cell.detailTextLabel!.text = "\(self.timeToString(Int(time))) ago"
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("playlistCell", forIndexPath: indexPath) as UITableViewCell
            cell.textLabel.text = self.trackProvider.users.values.array[indexPath.section].playlists.keys.array[indexPath.row - 1]
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // expand playlist cells when touching username
        if indexPath.row == 0 {
            self.userIsExpanded[indexPath.section] = !self.userIsExpanded[indexPath.section]
            tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row == 0 ? true : false
    }

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return tableView.editing ? .Delete : .None
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // delete user from track provider
        self.trackProvider.removePlaylistsForUser(self.trackProvider.users.keys.array[indexPath.section])
    }
    
    // these two methods hide the section headers completely
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    func reloadData() {
        // collapse all opend user views
        self.userIsExpanded = [Bool](count: self.trackProvider.users.count, repeatedValue: false)
        self.updateUsernameCellIndicesArray()
        
        // update cells
        self.tableView.beginUpdates()
        self.tableView.deleteSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.tableView.numberOfSections())), withRowAnimation: .Fade)
        self.tableView.insertSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.numberOfSectionsInTableView(self.tableView))), withRowAnimation: .Fade)
        self.tableView.endUpdates()
    }
    
    func reloadUserCells() {
        if !self.editing {
            self.tableView.reloadRowsAtIndexPaths(self.usernameCellIndices, withRowAnimation: .None)
        }
    }
    
    func updateUsernameCellIndicesArray() {
        self.usernameCellIndices = [NSIndexPath]()
        for var i = 0; i < self.trackProvider.users.count; ++i {
            self.usernameCellIndices.append(NSIndexPath(forRow: 0, inSection: i))
        }
    }
    
    func timeToString(time: Int) -> String {
        if time < 60 {
            return "\(time) sec."
        }
        else if time < 60 * 60 {
            return "\(time / 60) min."
        }
        else if time < 60 * 60  * 24{
            return "\(time / 60 / 60) h"
        }
        else if time < 2 * 60 * 60 * 24{
            return "\(time / 60 / 60 / 24) day"
        }
        else {
            return "\(time / 60 / 60 / 24) days"
        }
    }
}
