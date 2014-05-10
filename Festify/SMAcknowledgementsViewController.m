//
//  SMAcknowledgementsViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 10/05/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMAcknowledgementsViewController.h"

@implementation SMAcknowledgementsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // load acknowledgements from plist file
    NSString* path = [[NSBundle mainBundle] pathForResource:@"Pods-acknowledgements" ofType:@"plist"];
    NSDictionary* acknowledgements = [NSDictionary dictionaryWithContentsOfFile:path][@"PreferenceSpecifiers"];
    
    // read out all acknowledgements and add them to one continous string
    NSMutableString* acknowledgementsText = [NSMutableString string];
    for (NSDictionary *acknowledgement in acknowledgements) {
        [acknowledgementsText appendFormat:@"\n\n%@\n%@", acknowledgement[@"Title"], acknowledgement[@"FooterText"]];
    }

    // configure textview to present acknowledgements
    self.textView.textContainerInset = UIEdgeInsetsMake(40.0, 10.0, 12.0, 10.0);
    self.textView.text = acknowledgementsText;
}

@end
