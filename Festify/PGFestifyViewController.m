//
//  PGFestifyViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFestifyViewController.h"
#import "PGFestifyTrackProvider.h"
#import <iAd/iAd.h>

@interface PGFestifyViewController ()

@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) SPTTrackPlayer* trackPlayer;
@property (nonatomic, strong) PGFestifyTrackProvider* trackProvider;

@end

@implementation PGFestifyViewController

-(void)viewDidLoad {
    [super viewDidLoad];
	[self addObserver:self forKeyPath:@"trackPlayer.indexOfCurrentTrack" options:0 context:nil];

    // set as discovery manager delegate
    [PGDiscoveryManager sharedInstance].delegate = self;
    
    // enable iAd
    self.canDisplayBannerAds = YES;
}

-(void)handleNewSession:(SPTSession *)session {
    self.session = session;
    self.trackProvider = [[PGFestifyTrackProvider alloc] initWithSession:session];

    // create new track player if not already existing
    if (!self.trackPlayer) {
        self.trackPlayer = [[SPTTrackPlayer alloc] initWithCompanyName:@"Patrik Gebhardt" appName:@"Festify"];
    }
    
    // enable playback
    [self.trackPlayer enablePlaybackWithSession:session callback:^(NSError *error) {
        if (error) {
			NSLog(@"*** Enabling playback got error: %@", error);
        }
    }];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"trackPlayer.indexOfCurrentTrack"]) {
        [self updateUI];
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

- (IBAction)festify:(id)sender {
    // reset track player
    if (self.trackPlayer.currentProvider != nil) {
        [self.trackPlayer pausePlayback];
    }
    
    // clear content of track provider
    [self.trackProvider clearAllTracks];

    // start discovering playlists
    [[PGDiscoveryManager sharedInstance] startDiscoveringPlaylists];
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
		SPTTrack *track = (SPTTrack*)self.trackProvider.tracks[index];
		self.titleLabel.text = track.name;
		self.albumLabel.text = track.album.name;
		self.artistLabel.text = [track.artists.firstObject name];
        self.coverImage.image = nil;
        
        [self loadCoverArt];
    }
}

-(void)loadCoverArt {
    // request complete album of track
    [SPTRequest requestItemFromPartialObject:[self.trackProvider.tracks[self.trackPlayer.indexOfCurrentTrack] album]
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

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri fromIdentifier:(NSString *)identifier {
    // request complete playlist and add it to track provider
    [SPTRequest requestItemAtURI:uri withSession:self.session callback:^(NSError *error, id object) {
        if (!error) {
            [self.trackProvider addPlaylist:object forIdentifier:identifier];
            
            // start playback, if not already running
            if (self.trackPlayer.currentProvider == nil || self.trackPlayer.paused) {
                [self.trackPlayer playTrackProvider:self.trackProvider];
            }
        }
    }];
}

@end
