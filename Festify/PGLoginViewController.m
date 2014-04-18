//
//  PGLoginViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGLoginViewController.h"
#import "PGFestifyViewController.h"
#import "PGAppDelegate.h"
#import "TSMessage.h"

@implementation PGLoginViewController

- (IBAction)login:(id)sender {
    // login to spotify api
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate loginToSpotifyAPI:^(NSError *error) {
        if (error) {
            // notify user
            [TSMessage showNotificationInViewController:self
                                                  title:@"Authentication Error"
                                               subtitle:error.userInfo[NSLocalizedDescriptionKey]
                                                   type:TSMessageNotificationTypeError];
        }
        else {
            if (self.delegate) {
                [self.delegate loginViewDidCompleteLogin:self];
            }
        }
    }];
}

@end
