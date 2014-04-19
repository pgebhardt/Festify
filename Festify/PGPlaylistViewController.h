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

-(void)playlistView:(PGPlaylistViewController*)playlistView didSelectTrackWithIndex:(NSUInteger)index;

@end

@interface PGPlaylistViewController : UITableViewController

@property (nonatomic, weak) id<PGPlaylistViewDelegate> delegate;
- (IBAction)done:(id)sender;

@end
