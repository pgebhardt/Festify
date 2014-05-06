//
//  PGPlaylistViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Spotify/Spotify.h>
#import "SMPlaylistViewController.h"

@interface SMPlaylistViewController ()
@property (nonatomic, strong) NSArray* searchResults;
@end

@implementation SMPlaylistViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // update UI
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // make search table view appear similar to playlist table view
    UIImage* backgroundImage = ((UIImageView*)self.navigationController.view.subviews.firstObject).image;
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.searchDisplayController.searchResultsTableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.searchDisplayController.searchBar.delegate = self;
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults.count;
    }
    else {
        return self.trackPlayer.currentProvider.tracks.count;
    }
}

#pragma mark - Table view delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    SPTPartialTrack* track = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        track = self.searchResults[indexPath.row];
    }
    else {
        NSUInteger trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracks.count;
        track = self.trackPlayer.currentProvider.tracks[trackIndex];
    }
    cell.textLabel.text = track.name;
    cell.detailTextLabel.text = [track.artists[0] name];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger trackIndex = 0;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        trackIndex = [self.trackPlayer.currentProvider.tracks indexOfObject:self.searchResults[indexPath.row]];
    }
    else {
        trackIndex = (indexPath.row + self.trackPlayer.indexOfCurrentTrack + 1) % self.trackPlayer.currentProvider.tracks.count;
    }
    
    [self.trackPlayer skipToTrack:trackIndex];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(name contains[c] %@) || (artists[0].name contains[c] %@)", searchText, searchText];
    self.searchResults = [self.trackPlayer.currentProvider.tracks filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

#pragma mark - UISearchBarDelegate

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // hide search table view, to avoid strange UI glitch
    self.searchDisplayController.searchResultsTableView.hidden = YES;
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
