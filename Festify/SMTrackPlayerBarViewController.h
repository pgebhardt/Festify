//
//  SMTrackPlayerBarViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 12/05/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMTrackPlayer.h"

@interface SMTrackPlayerBarViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverArtImageView;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) SMTrackPlayer* trackPlayer;

- (IBAction)barPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;

@end
