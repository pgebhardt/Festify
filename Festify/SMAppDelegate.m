//
//  PGAppDelegate.m
//  Festify
//
//  Created by Patrik Gebhardt on 14/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMUserDefaults.h"
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
    // start receiving remote control events
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    // adjust default colors to match spotify color schema
    [[UITableView appearance] setSeparatorColor:[UIColor colorWithRed:86.0/255.0 green:86.0/255.0 blue:86.0/255.0 alpha:1.0]];
    [[BlurryModalSegue appearance] setBackingImageBlurRadius:@15];
    [[BlurryModalSegue appearance] setBackingImageSaturationDeltaFactor:@1.3];
    [[BlurryModalSegue appearance] setBackingImageTintColor:[UIColor colorWithRed:26.0/255.0 green:26.0/255.0
                                                                             blue:26.0/255.0 alpha:0.7]];

    // config appirater rating request system
    [Appirater setAppId:@"877580227"];
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
    [Appirater appEnteredForeground:YES];
}

@end