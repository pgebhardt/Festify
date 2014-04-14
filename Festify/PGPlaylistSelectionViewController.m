//
//  PGPlaylistSelectionViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGPlaylistSelectionViewController.h"
#import "PGDiscoveryManager.h"

@interface PGPlaylistSelectionViewController ()

@property (nonatomic, strong) SPTPlaylistList* playlists;

@end

@implementation PGPlaylistSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // add refresh controll to table view
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(retrievePlaylists) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // retrieve playlists
    [self retrievePlaylists];
}

-(void)retrievePlaylists {
    // get the playlists of the current user
    [SPTRequest playlistsForUser:self.session.canonicalUsername withSession:self.session callback:^(NSError *error, id object) {
        if (error) {
            NSLog(@"Could not retrieve playlists for user: %@", self.session.canonicalUsername);
        }
        else {
            self.playlists = object;
            
            // start advertising
            [[PGDiscoveryManager sharedInstance] startAdvertisingPlaylist:self.playlists.items[0] withSession:self.session];

            // update ui
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                
                // hide refresh control
                if (self.refreshControl.isRefreshing) {
                    [self.refreshControl endRefreshing];
                }
            });
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playlists.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self.playlists.items[indexPath.row] name];
    
    return cell;
}

@end
