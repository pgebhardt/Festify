//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGDiscoveryManager.h"
#import "PGFestifyViewController.h"
#import <Spotify/Spotify.h>
#import "TestFlight.h"

static NSString* const kSpotifyCallbackURL = @"spotify-ios-sdk-beta://callback";
static NSString* const kSessionUserDefaultsKey = @"SpotifySession";

@implementation PGAppDelegate

-(void)handleSessionToRootViewController:(SPTSession*)session {
    // set session of root view controller
    UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;
    PGFestifyViewController* rootViewController = (PGFestifyViewController*)navigationController.viewControllers[0];
    
    [rootViewController handleNewSession:session];
}

-(void)handleErrorToRootViewController:(NSError*)error {
    // set error of root view controller
    UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;
    PGFestifyViewController* rootViewController = (PGFestifyViewController*)navigationController.viewControllers[0];
    
    [rootViewController handleLoginError:error];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // update discovery manager service UUID
    [PGDiscoveryManager sharedInstance].serviceUUID = [CBUUID UUIDWithString:@"313752b1-f55b-4769-9387-61ce9fd7a840"];
 
    // enable test flight
    [TestFlight takeOff:@"53842477-fe12-4f61-ba55-aa1bb1eebba0"];

    // try to load session from NSUserDefaults
    id plistRepresentation = [[NSUserDefaults standardUserDefaults] valueForKey:kSessionUserDefaultsKey];
    SPTSession* session = [[SPTSession alloc] initWithPropertyListRepresentation:plistRepresentation];
    
    // check for valid session
    if (session.credential.length > 0) {
        [self handleSessionToRootViewController:session];
    }

    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // this is the return point for the spotify authentication,
    // so completion happens here
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kSpotifyCallbackURL]]) {
        [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://patrik-macbook:1234/swap"] callback:^(NSError *error, SPTSession *session) {
            if (!error) {
                // save session to user defaults
                [[NSUserDefaults standardUserDefaults] setValue:[session propertyListRepresentation]
                                                         forKey:kSessionUserDefaultsKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // tell root view controller login has completed
                [self handleSessionToRootViewController:session];
            }
            else {
                [self handleErrorToRootViewController:error];
            }
        }];
        
        return YES;
    }
    
    return NO;
}

@end
