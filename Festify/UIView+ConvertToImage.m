//
//  UIView+ConvertToImage.m
//  Festify
//
//  Created by Patrik Gebhardt on 19/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "UIView+ConvertToImage.h"

@implementation UIView (ConvertToImage)

-(UIImage*)convertToImage {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
