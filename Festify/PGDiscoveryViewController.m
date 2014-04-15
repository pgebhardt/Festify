//
//  PGDiscoveryViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGDiscoveryViewController.h"
#import "PGDiscoveryManager.h"

@interface PGDiscoveryViewController () <PGDiscoveryManagerDelegate>

@property (atomic, strong) NSMutableDictionary* playlists;

@end

@implementation PGDiscoveryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playlists = [[NSMutableDictionary alloc] init];

    // set self as discovery manager delegate
    [PGDiscoveryManager sharedInstance].delegate = self;
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
