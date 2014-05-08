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
    
    self.userIsExpanded = [NSMutableArray array];
    for (NSInteger i = 0; i < self.users.count; ++i) {
        [self.userIsExpanded addObject:@NO];
    }
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.users.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userIsExpanded[section] boolValue] ? ([self.users[section][@"playlists"] count] + 1) : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"usernameCell" forIndexPath:indexPath];
        cell.textLabel.text = self.users[indexPath.section][@"username"];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCell" forIndexPath:indexPath];
        cell.textLabel.text = [self.users[indexPath.section][@"playlists"] objectAtIndex:(indexPath.row - 1)];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0) {
        NSMutableArray* indexes = [NSMutableArray array];
        for (NSInteger i = 0; i < [self.users[indexPath.section][@"playlists"] count]; ++i) {
            [indexes addObject:[NSIndexPath indexPathForRow:(i + 1) inSection:indexPath.section]];
        }
        
        if ([self.userIsExpanded[indexPath.section] boolValue]) {
            self.userIsExpanded[indexPath.section] = @NO;
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else {
            self.userIsExpanded[indexPath.section] = @YES;
            
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
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

@end
