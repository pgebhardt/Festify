//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
#import "SMFestifyViewController.h"
#import "Appirater.h"
#import "BlurryModalSegue.h"

// spotify authentication constants
// TODO: replace with post-beta IDs and adjust the App's URL type
static NSString* const kClientID = @"spotify-ios-sdk-beta";
static NSString * const kCallbackURL = @"spotify-ios-sdk-beta://callback";

@interface SMAppDelegate ()
@property (nonatomic, copy) void (^loginCallback)(SPTSession* session, NSError* error);
@end

@implementation SMAppDelegate

-(void)remoteControlReceivedWithEvent:(UIEvent *)event {
    // control track player by remote events
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay ||
            event.subtype == UIEventSubtypeRemoteControlPause ||
            event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            if (self.trackPlayer.playing) {
                [self.trackPlayer pause];
            }
            else {
                [self.trackPlayer play];
            }
        }
        else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self.trackPlayer skipForward];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self.trackPlayer skipBackward];
        }
    }
}

-(void)requestSpotifySessionWithCompletionHandler:(void (^)(SPTSession*, NSError *))completion {
    // set login callback
    self.loginCallback = completion;
    
    // get login url
    NSURL* loginURL = [[SPTAuth defaultInstance] loginURLForClientId:kClientID
                                                 declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                                                              scopes:@[@"login"]];
    
    // open url in safari to login to spotify api
    [[UIApplication sharedApplication] openURL:loginURL];
}

#pragma mark - UIApplicationDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.trackPlayer = [SMTrackPlayer trackPlayerWithCompanyName:[NSBundle mainBundle].bundleIdentifier
                                                         appName:[NSBundle mainBundle].infoDictionary[(NSString*)kCFBundleNameKey]];

    // start receiving remote control events
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    // adjust default colors to match spotify color schema
    [[UITableView appearance] setSeparatorColor:[UIColor colorWithRed:86.0/255.0 green:86.0/255.0 blue:86.0/255.0 alpha:1.0]];
    [[BlurryModalSegue appearance] setBackingImageBlurRadius:@15];
    [[BlurryModalSegue appearance] setBackingImageSaturationDeltaFactor:@1.3];
    [[BlurryModalSegue appearance] setBackingImageTintColor:[UIColor colorWithRed:26.0/255.0 green:26.0/255.0
                                                                             blue:26.0/255.0 alpha:0.7]];

    // config appirater rating request system
    // TODO: [Appirater setAppId:@"123456789"];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // this is the return point for the spotify authentication,
    // so completion happens here
    if ([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kCallbackURL]]) {
        [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url
                                            tokenSwapServiceEndpointAtURL:[NSURL URLWithString:@"http://192.168.178.28:1234/swap"]
                                                                 callback:^(NSError *error, SPTSession *session) {
            // call callback to inform about completed session request
            if (self.loginCallback) {
                self.loginCallback(session, error);
            }
        }];
        
        return YES;
    }
    
    return NO;
}

-(void)applicationWillTerminate:(UIApplication *)application {
    // save current application state
    [SMUserDefaults saveApplicationState];
}

-(void)applicationWillResignActive:(UIApplication *)application {
    // save current application state
    [SMUserDefaults saveApplicationState];
}

-(void)applicationWillEnterForeground:(UIApplication *)application {
    // assume spotify did logout when player is not playing
    if (!self.trackPlayer.playing && self.trackPlayer.session) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SMFestifyViewControllerRestoreApplicationState object:nil];
    }
    
    [Appirater appEnteredForeground:YES];
}

@end