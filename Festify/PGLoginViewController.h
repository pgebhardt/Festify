//
//  PGLoginViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 16/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PGLoginViewController : UIViewController

- (IBAction)login:(id)sender;
-(void)loginCompletedWithSession:(SPTSession*)session;

@end
