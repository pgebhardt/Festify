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
@property (nonatomic, assign) UITableViewCellAccessoryType defaultAccessory;
@end

@implementation SMSettingSelectionViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // init UI elements
    if (self.allowMultipleSelections) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Select All"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(toggleSelection:)];
    }
    if (self.navigationController.viewControllers[0] == self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(done:)];
    }
    self.defaultAccessory = [[self.tableView dequeueReusableCellWithIdentifier:@"cell"] accessoryType];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // convert index array to array containig whether cell is selected or not
    self.itemIsSelected = [NSMutableArray arrayWithCapacity:self.data.count];
    for (NSUInteger i = 0; i < self.data.count; ++i) {
        self.itemIsSelected[i] = @NO;
    }
    if (self.allowMultipleSelections) {
        [self.indicesOfSelectedItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            self.itemIsSelected[idx] = @YES;
        }];
    }
    else {
        self.itemIsSelected[self.indexOfSelectedItem] = @YES;
    }
    
    // update UI
    if (self.allowMultipleSelections) {
        self.navigationItem.rightBarButtonItem.title = self.indicesOfSelectedItems.count == self.data.count ? @"Clear All" : @"Select All";
    }
}

-(void)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggleSelection:(id)sender {
    UIBarButtonItem* button = (UIBarButtonItem*)sender;
    if ([button.title isEqualToString:@"Select All"]) {
        button.title = @"Clear All";
        for (NSUInteger i = 0; i < self.data.count; ++i) {
            self.itemIsSelected[i] = @YES;
        }
    }
    else {
        button.title = @"Select All";
        for (NSUInteger i = 0; i < self.data.count; ++i) {
            self.itemIsSelected[i] = @NO;
        }
    }
    [self.tableView reloadData];
    
    
    // inform delegate about changes
    [self itemSelectionDidChange];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
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
        cell.accessoryType = self.defaultAccessory;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // update cell and itemIsSelected array
    if (self.allowMultipleSelections) {
        self.itemIsSelected[indexPath.row] = [self.itemIsSelected[indexPath.row] boolValue] ? @NO : @YES;
        
        // update UI
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([self.itemIsSelected[indexPath.row] boolValue]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            // check if all items are selected
            BOOL allItemsSelected = YES;
            for (NSNumber* itemIsSelected in self.itemIsSelected) {
                allItemsSelected &= itemIsSelected.boolValue;
            }
            self.navigationItem.rightBarButtonItem.title = allItemsSelected ? @"Clear All" : @"Select All";
        }
        else {
            cell.accessoryType = self.defaultAccessory;
            self.navigationItem.rightBarButtonItem.title = @"Select All";
        }
    }
    else {
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.indexOfSelectedItem inSection:0]].accessoryType = UITableViewCellAccessoryNone;
        self.indexOfSelectedItem = indexPath.row;
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.indexOfSelectedItem inSection:0]].accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    // inform delegate about changes
    [self itemSelectionDidChange];
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        return self.subtitle;
    }
    return @"";
}

// these two methods hide the section headers completely
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

#pragma mark - Helper

-(void)itemSelectionDidChange {
    // update selection array and inform delegate about changes
    if (self.allowMultipleSelections) {
        NSMutableIndexSet* indicesOfSelectedItems = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < self.data.count; ++i) {
            if ([self.itemIsSelected[i] boolValue]) {
                [indicesOfSelectedItems addIndex:i];
            }
        }
        
        if (self.delegate) {
            [self.delegate settingsSelectionView:self didChangeIndicesOfSelectedItems:indicesOfSelectedItems];
        }
    }
    else {
        if (self.delegate) {
            [self.delegate settingsSelectionView:self didChangeIndicesOfSelectedItems:[NSIndexSet indexSetWithIndex:self.indexOfSelectedItem]];
        }
    }
}

@end
