//
//  PGFeedbackViewController.m
//  Festify
//
//  Created by Patrik Gebhardt on 18/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFeedbackViewController.h"
#import "TestFlight.h"

@implementation PGFeedbackViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.feedbackTextView.delegate = self;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // show keyboard
    [self.feedbackTextView becomeFirstResponder];
}

- (IBAction)sendFeedback:(id)sender {
    [TestFlight submitFeedback:self.feedbackTextView.text];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)textViewDidChange:(UITextView *)textView {
    // enable or disable send button
    if (self.feedbackTextView.text.length == 0) {
        self.sendButton.enabled = NO;
    }
    else {
        self.sendButton.enabled = YES;
    }
}
@end
