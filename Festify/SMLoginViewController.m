//
//  PGLoginViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "Festify-Bridging-Header.h"
#import "Festify-Swift.h"
#import "SMLoginViewController.h"
#import "SMFestifyViewController.h"

@implementation SMLoginViewController

- (IBAction)login:(id)sender {
    // login to spotify api
    [(AppDelegate*)[UIApplication sharedApplication].delegate requestSpotifySessionWithCompletionHandler:^(SPTSession* session, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && self.delegate) {
                [self.delegate loginView:self didCompleteLoginWithSession:session];
            }
        });
    }];
}

@end
