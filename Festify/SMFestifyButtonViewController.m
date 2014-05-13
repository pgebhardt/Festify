//
//  SMFestifyButtonViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 13/05/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import "SMFestifyButtonViewController.h"
#import "SMDiscoveryManager.h"

@implementation SMFestifyButtonViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // register to discovery manager state changes to apply animation to button overlay and check current
    // discovery manager state to start animation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAnimationState:)
                                                 name:SMDiscoveryManagerDidUpdateDiscoveryState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAnimationState:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [self startAnimation];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // unregister from all notifications and stop animation
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [self stopAnimation];
    }
}

- (IBAction)buttonPressed:(id)sender {
    // toggle discovering state
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [[SMDiscoveryManager sharedInstance] stopDiscovering];
    }
    else {
        [[SMDiscoveryManager sharedInstance] startDiscovering];
    }
}

-(void)updateAnimationState:(id)notification {
    if ([SMDiscoveryManager sharedInstance].isDiscovering) {
        [self startAnimation];
    }
    else {
        [self stopAnimation];
    }
}

-(void)startAnimation {
    // reset all current animations and start button animation from beginning
    [self.buttonOverlay.layer removeAllAnimations];
    self.buttonOverlay.transform = CGAffineTransformIdentity;
    
    [UIView animateWithDuration:0.6 delay:0.0
                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationCurveEaseInOut |
        UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat
                     animations:^{
                         self.buttonOverlay.transform = CGAffineTransformMakeRotation(-60.0 * M_PI / 180.0);
                     } completion:nil];
}

-(void)stopAnimation {
    // remove all animations and do a last cicle of animations
    [self.buttonOverlay.layer removeAllAnimations];
    self.buttonOverlay.transform = [self.buttonOverlay.layer.presentationLayer affineTransform];
    
    [UIView animateWithDuration:0.6 delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.buttonOverlay.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

@end
