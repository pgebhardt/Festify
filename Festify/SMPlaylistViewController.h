//
//  PGPlaylistViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 17/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import "SMPlayerViewController.h"
#import "SMTrackPlayer.h"

@interface SMPlaylistViewController : UITableViewController<UISearchBarDelegate>

- (IBAction)done:(id)sender;
@property (nonatomic, weak) SMTrackPlayer* trackPlayer;

@end
