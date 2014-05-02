//
//  PGPlaylistViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@class SMPlaylistViewController;

@protocol SMPlaylistViewDelegate <NSObject>

-(void)playlistViewDidEndShowing:(SMPlaylistViewController*)playlistView;

@end

#import "SMPlayerViewController.h"
#import "SMTrackPlayer.h"

@interface SMPlaylistViewController : UITableViewController<SMPlayerViewDelegate>

- (IBAction)done:(id)sender;
@property (nonatomic, strong) UIView* underlyingView;
@property (nonatomic, weak) SMTrackPlayer* trackPlayer;
@property (nonatomic, weak) id<SMPlaylistViewDelegate> delegate;

@end
