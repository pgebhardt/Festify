//
//  SMSettingSelectionViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 01/05/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMSettingSelectionViewController.h"

@interface SMSettingSelectionViewController ()
@property (nonatomic, strong) NSMutableArray* itemIsSelected;
@end

@implementation SMSettingSelectionViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // convert index array to array containig whether cell is selected or not
    self.itemIsSelected = [NSMutableArray arrayWithCapacity:self.data.count];
    for (NSUInteger i = 0; i < self.data.count; ++i) {
        self.itemIsSelected[i] = @NO;
    }
    for (NSNumber* selectedItem in self.indicesOfSelectedItems) {
        self.itemIsSelected[[selectedItem integerValue]] = @YES;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.delegate) {
        NSMutableArray* indicesOfSelectedItems = [NSMutableArray array];
        for (NSUInteger i = 0; i < self.data.count; ++i) {
            if ([self.itemIsSelected[i] boolValue]) {
                [indicesOfSelectedItems addObject:[NSNumber numberWithInteger:i]];
            }
        }
        
        [self.delegate settingsSelectionView:self didChangeIndicesOfSelectedItems:[indicesOfSelectedItems copy]];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // configure cell
    if (self.dataAccessor) {
        cell.textLabel.text = self.dataAccessor(self.data[indexPath.row]);
    }
    else {
        cell.textLabel.text = [self.data[indexPath.row] description];
    }
    if ([self.itemIsSelected[indexPath.row] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // update cell and itemIsSelected array
    self.itemIsSelected[indexPath.row] = [self.itemIsSelected[indexPath.row] boolValue] ? @NO : @YES;
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.itemIsSelected[indexPath.row] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
