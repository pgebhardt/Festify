//
//  PGLoginViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGLoginViewController.h"
#import "PGFestifyViewController.h"

@interface PGLoginViewController ()

@property (nonatomic, strong) SPTSession* session;

@end

// Spotify authentication credentials
static NSString* const kSpotifyClientId = @"spotify-ios-sdk-beta";
static NSString* const kSpotifyCallbackURL = @"spotify-ios-sdk-beta://callback";

@implementation PGLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)login:(id)sender {
    // get login url
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kSpotifyClientId
                                                 declaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]
                                                              scopes:@[@"login"]];
    
    // open url in safari to login to spotify api
    [[UIApplication sharedApplication] openURL:loginURL];
}

-(void)loginCompletedWithSession:(SPTSession *)session {
    // show main view controller and handle session
    self.session = session;
    [self performSegueWithIdentifier:@"showMainScene" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showMainScene"]) {
        PGFestifyViewController* destViewController = (PGFestifyViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        [destViewController handleNewSession:self.session];
    }
}

@end
