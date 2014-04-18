//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGDiscoveryManager.h"
#import "PGLoginViewController.h"
#import <Spotify/Spotify.h>
#import "TestFlight.h"

static NSString* const kSpotifyCallbackURL = @"spotify-ios-sdk-beta://callback";

@implementation PGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // update discovery manager service UUID
    [PGDiscoveryManager sharedInstance].serviceUUID = [CBUUID UUIDWithString:@"313752b1-f55b-4769-9387-61ce9fd7a840"];
 
    // enable test flight
    [TestFlight takeOff:@"53842477-fe12-4f61-ba55-aa1bb1eebba0"];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // this is the return point for the spotify authentication,
    // so completion happens here
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]]) {
        [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url
                                            tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://patrik-macbook:1234/swap"]
                                                                 callback:^(NSError *error, SPTSession *session) {
            // tell root view controller login has completed
            [(PGLoginViewController*)self.window.rootViewController loginCompletedWithSession:session andError:error];
        }];
        
        return YES;
    }
    
    return NO;
}

@end
