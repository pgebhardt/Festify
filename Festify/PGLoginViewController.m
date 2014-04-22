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
    // login to spotify api
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [(PGAppDelegate*)[UIApplication sharedApplication].delegate requestSpotifySessionWithCompletionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if (!error) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [TSMessage showNotificationInViewController:self
                                                      title:@"Authentication Error"
                                                   subtitle:error.userInfo[NSLocalizedDescriptionKey]
                                                       type:TSMessageNotificationTypeError];
            }
        });
    }];
}

@end
