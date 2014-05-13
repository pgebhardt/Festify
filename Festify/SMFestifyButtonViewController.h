//
//  SMFestifyButtonViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 13/05/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMFestifyButtonViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *buttonOverlay;
- (IBAction)buttonPressed:(id)sender;

@end
