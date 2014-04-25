//
//  PGPlaylistViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@class PGPlaylistViewController;

@protocol PGPlaylistViewDelegate <NSObject>

-(void)playlistViewDidEndShowing:(PGPlaylistViewController*)playlistView;

@end

#import "PGPlayerViewController.h"

@interface PGPlaylistViewController : UITableViewController<PGPlayerViewDelegate>

- (IBAction)done:(id)sender;
@property (nonatomic, strong) UIView* underlyingView;
@property (nonatomic, weak) id<PGPlaylistViewDelegate> delegate;

@end
