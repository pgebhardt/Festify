//
//  PGPlaylistViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGPlaylistViewController.h"
#import <Spotify/Spotify.h>

@implementation PGPlaylistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // add observers to update UI accordingly to track and playlist changes
    [self addObserver:self forKeyPath:@"trackPlayer.indexOfCurrentTrack" options:0 context:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeObserver:self forKeyPath:@"trackPlayer.indexOfCurrentTrack"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"trackPlayer.indexOfCurrentTrack"]) {
        [self.tableView reloadData];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.trackPlayer.currentProvider.tracks.count;
}

#pragma mark - Table view delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSUInteger trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracks.count;
    cell.textLabel.text = [self.trackPlayer.currentProvider.tracks[trackIndex] name];
    cell.detailTextLabel.text = [[[self.trackPlayer.currentProvider.tracks[trackIndex] artists] objectAtIndex:0] name];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate) {
        NSUInteger trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracks.count;
        [self.delegate playlistView:self didSelectTrackWithIndex:trackIndex];
        
        [self.tableView reloadData];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
