//
//  SMUsersViewController.h
//  Festify
//
//  Created by Patrik Gebhardt on 08/05/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMUsersViewController : UITableViewController
@property (nonatomic, strong) NSArray* users;
- (IBAction)done:(id)sender;
@end
