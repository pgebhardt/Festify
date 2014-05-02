//
//  SMSettingSelectionViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 01/05/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMSettingSelectionViewController.h"
#import "MSCellAccessory.h"
#import "UIImage+ImageEffects.h"
#import "UIView+ConvertToImage.h"

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
    
    // blur background
    [self createBlurredBackgroundFromView:self.underlyingView];
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

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_CHECKMARK
                                                          color:[UIColor colorWithRed:132.0/255.0 green:189.0/255.0 blue:0.0 alpha:1.0]];
    }
    else {
        cell.accessoryView = nil;
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
        cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_CHECKMARK
                                                          color:[UIColor colorWithRed:132.0/255.0 green:189.0/255.0 blue:0.0 alpha:1.0]];
    }
    else {
        cell.accessoryView = nil;
    }
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
    
    self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [(UIImageView*)self.tableView.backgroundView setImage:image];
}

@end
