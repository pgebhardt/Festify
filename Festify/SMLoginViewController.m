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
#import "UIView+ConvertToImage.h"
#import "UIImage+ImageEffects.h"
#import "TSMessage.h"
#import "MBProgressHud.h"

@implementation SMLoginViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // create image view containing a blured image of the current view controller.
    // This makes the effect of a transparent playlist view
    UIImage* image = [self.underlyingView convertToImage];
    image = [image applyBlurWithRadius:10
                             tintColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:0.5]
                 saturationDeltaFactor:1.3
                             maskImage:nil];
    
    UIImageView* backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = image;

    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // show login error, if available
    if (self.loginError) {
        [TSMessage showNotificationInViewController:self
                                              title:@"Authentication Error"
                                           subtitle:self.loginError.userInfo[NSLocalizedDescriptionKey]
                                               type:TSMessageNotificationTypeError];
        self.loginError = nil;
    }
}

- (IBAction)login:(id)sender {
    // login to spotify api
    [(SMAppDelegate*)[UIApplication sharedApplication].delegate requestSpotifySessionWithCompletionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // return to main screen
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.delegate) {
                    [self.delegate loginView:self didCompleteLoginWithError:error];
                }
            }];
        });
    }];
}

@end
