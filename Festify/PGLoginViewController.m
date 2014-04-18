//
//  PGLoginViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGLoginViewController.h"
#import "PGFestifyViewController.h"
#import "TSMessage.h"

// Spotify authentication credentials
static NSString* const kSpotifyClientId = @"spotify-ios-sdk-beta";
static NSString* const kSpotifyCallbackURL = @"spotify-ios-sdk-beta://callback";

@implementation PGLoginViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // notify user about login error
    if (self.error) {
        // notify user
        [TSMessage showNotificationInViewController:self
                                              title:@"Authentication Error"
                                           subtitle:self.error.userInfo[NSLocalizedDescriptionKey]
                                               type:TSMessageNotificationTypeError];
        self.error = nil;
    }
}

- (IBAction)login:(id)sender {
    // get login url
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kSpotifyClientId
                                                 declaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]
                                                              scopes:@[@"login"]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // open url in safari to login to spotify api
    [[UIApplication sharedApplication] openURL:loginURL];
}

@end
