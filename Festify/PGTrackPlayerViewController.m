//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGTrackPlayerViewController.h"
#import <iAd/iAd.h>

@interface PGTrackPlayerViewController ()

@end

@implementation PGTrackPlayerViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    // enable iAd
    self.canDisplayBannerAds = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	[self addObserver:self forKeyPath:@"trackPlayer.indexOfCurrentTrack" options:0 context:nil];
    [self updateUI];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeObserver:self forKeyPath:@"trackPlayer.indexOfCurrentTrack"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"trackPlayer.indexOfCurrentTrack"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUI];
        });
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Actions

-(IBAction)rewind:(id)sender {
	[self.trackPlayer skipToPreviousTrack:NO];
}

-(IBAction)playPause:(id)sender {
	if (self.trackPlayer.paused) {
		[self.trackPlayer resumePlayback];
	}
    else {
		[self.trackPlayer pausePlayback];
	}
}

-(IBAction)fastForward:(id)sender {
	[self.trackPlayer skipToNextTrack];
}

#pragma mark - Logic

-(void)updateUI {
	if (self.trackPlayer.indexOfCurrentTrack == NSNotFound) {
		self.titleLabel.text = @"Nothing Playing";
		self.albumLabel.text = @"";
		self.artistLabel.text = @"";
        self.coverImage.image = nil;
	}
    else {
		NSInteger index = self.trackPlayer.indexOfCurrentTrack;
		SPTTrack *track = (SPTTrack*)self.trackPlayer.currentProvider.tracks[index];
		self.titleLabel.text = track.name;
		self.albumLabel.text = track.album.name;
		self.artistLabel.text = [track.artists.firstObject name];
        self.coverImage.image = nil;
        
        [self loadCoverArt];
    }
}

-(void)loadCoverArt {
    // request complete album of track
    [SPTRequest requestItemFromPartialObject:[self.trackPlayer.currentProvider.tracks[self.trackPlayer.indexOfCurrentTrack] album]
                                 withSession:self.session
                                    callback:^(NSError *error, id object) {
        if (error) {
            return;
        }

        SPTAlbum* album = (SPTAlbum*)object;
        NSURL* imageURL = album.largestCover.imageURL;
        
        if (imageURL == nil) {
            NSLog(@"Album %@ doesn't have any images!", album);
            self.coverImage.image = nil;
            return;
        }
        
        [self.spinner startAnimating];
        
        // Pop over to a background queue to load the image over the network.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSError *error = nil;
            UIImage *image = nil;
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
            
            if (imageData != nil) {
                image = [UIImage imageWithData:imageData];
            }
            
            // …and back to the main queue to display the image.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                self.coverImage.image = image;
                if (image == nil) {
                    NSLog(@"Couldn't load cover image with error: %@", error);
                }
            });
        });
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        [segue.destinationViewController setSession:self.session];
    }
}

@end
