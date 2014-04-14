//
//  PGDiscoveryViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PGDiscoveryViewController : UITableViewController

@property (nonatomic, strong) SPTSession* session;

@end
