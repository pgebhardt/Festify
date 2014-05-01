//
//  SMSettingSelectionViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 01/05/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMSettingSelectionViewController;

@protocol SMSettinsSelectionViewDelegate <NSObject>

-(void)settingsSelectionView:(SMSettingSelectionViewController*)settingsSelectionView didChangeIndicesOfSelectedItems:(NSArray*)indicesOfSelectedItems;

@end

@interface SMSettingSelectionViewController : UITableViewController

@property (nonatomic, strong) NSArray* data;
@property (nonatomic, strong) NSArray* indicesOfSelectedItems;
@property (nonatomic, copy) NSString* (^dataAccessor)(id item);
@property (nonatomic, strong) id<SMSettinsSelectionViewDelegate> delegate;

@end
