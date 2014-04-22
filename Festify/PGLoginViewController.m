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
#import "UIView+ConvertToImage.h"
#import "UIImage+ImageEffects.h"
#import "TSMessage.h"
#import "MBProgressHud.h"

@implementation PGLoginViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // create image view containing a blured image of the current view controller.
    // This makes the effect of a transparent playlist view
    UIImage* image = [self.underlyingView convertToImage];
    image = [image applyBlurWithRadius:15
                             tintColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:0.7]
                 saturationDeltaFactor:1.3
                             maskImage:nil];
    
    UIImageView* backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = image;

    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
}

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
