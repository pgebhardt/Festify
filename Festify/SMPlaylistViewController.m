//
//  PGPlaylistViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Spotify/Spotify.h>
#import "SMPlaylistViewController.h"

@implementation SMPlaylistViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // update UI
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.trackPlayer.currentProvider.tracksForPlayback.count;
}

#pragma mark - Table view delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSUInteger trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracksForPlayback.count;
    SPTPartialTrack* track = self.trackPlayer.currentProvider.tracksForPlayback[trackIndex];
    cell.textLabel.text = track.name;
    cell.detailTextLabel.text = [track.artists[0] name];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracksForPlayback.count;
    
    [self.trackPlayer skipToTrack:trackIndex];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PGPlayerViewDelegate

-(void)playerViewDidUpdateTrackInfo:(SMPlayerViewController *)playerView {
    dispatch_async(dispatch_get_main_queue(), ^{
        // update table view
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
}

@end