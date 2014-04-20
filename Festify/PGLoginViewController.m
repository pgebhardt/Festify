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
#import "MBProgressHud.h"

@implementation PGLoginViewController

- (IBAction)login:(id)sender {
    void (^errorHandler)(NSError* error) = ^(NSError* error) {
        [TSMessage showNotificationInViewController:self
                                              title:@"Authentication Error"
                                           subtitle:error.userInfo[NSLocalizedDescriptionKey]
                                               type:TSMessageNotificationTypeError];
    };
    
    // login to spotify api
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate loginToSpotifyAPI:^(NSError *error) {
        if (error) {
            errorHandler(error);
        }
        else {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [(PGAppDelegate*)[UIApplication sharedApplication].delegate initSpotifyWithCompletionHandler:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    
                    if (!error) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        errorHandler(error);
                    }
                });
            }];
        }
    }];
}

@end
