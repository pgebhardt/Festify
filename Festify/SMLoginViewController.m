//
//  PGLoginViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMLoginViewController.h"
#import "SMFestifyViewController.h"
#import "SMAppDelegate.h"

@implementation SMLoginViewController

- (IBAction)login:(id)sender {
    // login to spotify api
    [(SMAppDelegate*)[UIApplication sharedApplication].delegate requestSpotifySessionWithCompletionHandler:^(SPTSession* session, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate) {
                [self.delegate loginView:self didCompleteLoginWithSession:session error:error];
            }
        });
    }];
}

@end
