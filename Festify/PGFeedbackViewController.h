//
//  PGFeedbackViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 18/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGFeedbackViewController : UITableViewController<UITextViewDelegate>

-(IBAction)sendFeedback:(id)sender;
-(IBAction)cancel:(id)sender;

@property (nonatomic, weak) IBOutlet UITextView* feedbackTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;

@end
