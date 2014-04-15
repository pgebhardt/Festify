//
//  PGDiscoveryViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGDiscoveryViewController.h"
#import "PGDiscoveryManager.h"
#import "PGFestifyTrackProvider.h"
#import <iAd/iAd.h>

@interface PGDiscoveryViewController ()

@property (atomic, strong) NSMutableDictionary* playlists;
@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;

@end

@implementation PGDiscoveryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init properties
    self.playlists = [[NSMutableDictionary alloc] init];
    self.trackProvider = [[PGFestifyTrackProvider alloc] initWithSession:self.session];
    [PGDiscoveryManager sharedInstance].delegate = self.trackProvider;

    // enable iAd
    self.canDisplayBannerAds = YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        [segue.destinationViewController setSession:self.session];
    }
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri {
    // retrieve playlist
    [SPTRequest requestItemAtURI:uri withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            self.playlists[uri.absoluteString] = (SPTPlaylistSnapshot*)object;
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.tableView reloadData];
            });
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playlists.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self.playlists.allValues[indexPath.row] name];
    cell.detailTextLabel.text = [self.playlists.allValues[indexPath.row] creator];
    
    return cell;
}

@end
