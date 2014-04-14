//
//  SPTAlbumCover.h
//  Spotify iOS SDK
//
//  Created by Daniel Kennett on 2014-04-04.
/*
 Copyright 2014 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/// Defines Spotify image sizes in relative terms.
typedef NS_ENUM(NSUInteger, SPTImageSize) {
	/// Specifies that the image is small.
	SPTImageSizeSmall,
	/// Specifies that the image is medium.
	SPTImageSizeMedium,
	/// Specifies that the image is large.
	SPTImageSizeLarge,
	/// Specifies that the image is extra large.
	SPTImageSizeExtraLarge
};

@interface SPTImage : NSObject

@property (nonatomic, readonly) CGSize aspect;

@property (nonatomic, readonly) SPTImageSize imageSize;

@property (nonatomic, readonly, copy) NSURL *imageURL;

@end
