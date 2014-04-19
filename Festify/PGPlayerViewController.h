//
//  PGFestifyViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGPlaylistViewController.h"

@interface PGPlayerViewController : UIViewController<PGPlaylistViewDelegate>

- (IBAction)rewind:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)fastForward:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@property (weak, nonatomic) IBOutlet UIProgressView *trackPosition;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeView;
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeView;

@end
