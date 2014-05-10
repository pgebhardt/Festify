//
//  SMUsersViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 08/05/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMUsersViewController.h"

@interface SMUsersViewController ()
@property (nonatomic, strong) NSMutableArray* userIsExpanded;
@end

@implementation SMUsersViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // show edit button
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // array describing, wether a user is expanded or not
    self.userIsExpanded = [NSMutableArray array];
    for (NSInteger i = 0; i < self.trackProvider.users.count; ++i) {
        [self.userIsExpanded addObject:@NO];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // observe changes in track provider
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:SMTrackProviderDidUpdateTracksArray object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.trackProvider.users.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userIsExpanded[section] boolValue] ? ([self.trackProvider.users.allValues[section][SMTrackProviderPlaylistsKey] count] + 1) : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"usernameCell" forIndexPath:indexPath];
        cell.textLabel.text = self.trackProvider.users.allKeys[indexPath.section];
        
        NSInteger minutesToTimeout = -[self.trackProvider.users.allValues[indexPath.section][SMTrackProviderAddedDateKey] timeIntervalSinceNow] / 60.0;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"added %ld min. ago", (long)minutesToTimeout];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCell" forIndexPath:indexPath];
        cell.textLabel.text = [[self.trackProvider.users.allValues[indexPath.section][SMTrackProviderPlaylistsKey] objectAtIndex:(indexPath.row - 1)] name];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0) {
        NSMutableArray* indexes = [NSMutableArray array];
        for (NSInteger i = 0; i < [self.trackProvider.users.allValues[indexPath.section][SMTrackProviderPlaylistsKey] count]; ++i) {
            [indexes addObject:[NSIndexPath indexPathForRow:(i + 1) inSection:indexPath.section]];
        }
        
        if ([self.userIsExpanded[indexPath.section] boolValue]) {
            self.userIsExpanded[indexPath.section] = @NO;
        }
        else {
            self.userIsExpanded[indexPath.section] = @YES;
        }
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // only the user itself is editable, not the playlists
    if (indexPath.row == 0) {
        return YES;
    }
    return NO;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // only allow editing in editing mode
    if ([tableView isEditing]) {
        return UITableViewCellEditingStyleDelete;
    }
    else {
        return UITableViewCellEditingStyleNone;
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // delete user from track provider
    [self.trackProvider removePlaylistsForUser:self.trackProvider.users.allKeys[indexPath.section]];
    
    // disable editing mode if last object
    if (self.trackProvider.users.count == 0) {
        self.editing = NO;
    }
}

// these two methods hide the section headers completely
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        return 44.0;
    }
    return CGFLOAT_MIN;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        return @"All visible playlists of these users are currently include in Festify`s playlist.";
    }
    return nil;
}

#pragma mark - Helper

-(void)reloadData {
    // array describing, wether a user is expanded or not
    self.userIsExpanded = [NSMutableArray array];
    for (NSInteger i = 0; i < self.trackProvider.users.count; ++i) {
        [self.userIsExpanded addObject:@NO];
    }

    [self.tableView beginUpdates];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections)] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView])] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

@end
