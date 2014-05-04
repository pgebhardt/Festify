//
//  PGPlaylistViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Spotify/Spotify.h>
#import "SMPlaylistViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIView+ConvertToImage.h"

@interface SMPlaylistViewController ()
@property (nonatomic, strong) NSArray* searchResults;
@end

@implementation SMPlaylistViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchDisplayController.searchBar.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // update UI
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self createBlurredBackgroundFromView:self.underlyingView];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate) {
            [self.delegate playlistViewDidEndShowing:self];
        }
    }];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
        // update background image
        [self createBlurredBackgroundFromView:self.underlyingView];
        
        // update table view
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
}

#pragma mark - Helper

-(void)createBlurredBackgroundFromView:(UIView*)view {
    // create image view containing a blured image of the current view controller.
    // This makes the effect of a transparent playlist view
    UIImage* image = [view convertToImage];
    image = [image applyBlurWithRadius:15
                             tintColor:[UIColor colorWithRed:26.0/255.0 green:26.0/255.0 blue:26.0/255.0 alpha:0.7]
                 saturationDeltaFactor:1.3
                             maskImage:nil];
    
    UIImageView* tableViewBackground = [[UIImageView alloc] initWithFrame:self.view.frame];
    UIImageView* searchViewBackground = [[UIImageView alloc] initWithFrame:self.view.frame];
    [tableViewBackground setImage:image];
    [searchViewBackground setImage:image];
    
    self.tableView.backgroundView = tableViewBackground;
    self.searchDisplayController.searchResultsTableView.backgroundView = searchViewBackground;
}

@end
