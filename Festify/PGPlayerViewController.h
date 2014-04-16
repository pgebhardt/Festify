//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PGPlayerViewController : UIViewController<SPTTrackPlayerDelegate>

- (IBAction)rewind:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)fastForward:(id)sender;

@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) SPTSession* session;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
