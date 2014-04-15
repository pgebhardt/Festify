//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGDiscoveryManager.h"
#import "PGDiscoveryViewController.h"
#import <Spotify/Spotify.h>

// Spotify authentication credentials
static NSString* const kSpotifyClientId = @"spotify-ios-sdk-beta";
static NSString* const kSpotifyCallbackURL = @"spotify-ios-sdk-beta://callback";

// key for plist spotify session representation
static NSString* const kSpotifySessionKey = @"SpotifySession";

@implementation PGAppDelegate

-(void)enableAudioPlaybackWithSession:(SPTSession*)session {
    // pass spotify session to root view controller
    UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;
    PGDiscoveryViewController* rootViewController = (PGDiscoveryViewController*)navigationController.viewControllers[0];
    
    rootViewController.session = session;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // update discovery manager app id
    [PGDiscoveryManager sharedInstance].serviceUUID = [CBUUID UUIDWithString:@"313752b1-f55b-4769-9387-61ce9fd7a840"];
    
    // get spotify session from user defaults
    id spotifySessionPlistRepresentation = [[NSUserDefaults standardUserDefaults] valueForKey:kSpotifySessionKey];
    SPTSession* spotifySession = [[SPTSession alloc] initWithPropertyListRepresentation:spotifySessionPlistRepresentation];
    
    // check if spotify session is valid, or authenticate with oauth
    if (spotifySession.credential.length > 0) {
        NSLog(@"Logged in from plist as user: %@", spotifySession.canonicalUsername);
        [self enableAudioPlaybackWithSession:spotifySession];
    }
    else {
        // get login url
        NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kSpotifyClientId
                                                     declaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]
                                                                  scopes:@[@"login"]];
        
        // open url in safari, but add a delay to avoid opening browser during didFinishLaunchingWithObtions
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:loginURL];
        });
    }

    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // this is the return point for the spotify authentication,
    // so completion happens here
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]]) {
        [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url
                                            tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://patrik-macbook:1234/swap"]
                                                                 callback:^(NSError *error, SPTSession *session) {
            if (error != nil) {
                NSLog(@"*** Authentication error: %@", error);
                return;
            }
            
            // save current session to user defaults for future use
            [[NSUserDefaults standardUserDefaults] setValue:[session propertyListRepresentation] forKey:kSpotifySessionKey];
            [self enableAudioPlaybackWithSession:session];
                                                                     
            NSLog(@"Logged in from web as user: %@", session.canonicalUsername);
        }];
        
        return YES;
    }
    
    return NO;
}

@end
