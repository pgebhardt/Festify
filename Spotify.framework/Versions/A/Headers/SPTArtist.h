//
//  SPTArtist.h
//  Basic Auth
//
//  Created by Daniel Kennett on 19/11/2013.
/*
 Copyright 2013 Spotify AB

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
#import "SPTJSONDecoding.h"
#import "SPTRequest.h"

@class SPTImage;

/** This class represents an artist on the Spotify service. */
@interface SPTArtist : NSObject <SPTJSONObject>

/** Request the artist at the given Spotify URI.

 @note This method takes Spotify URIs in the form `spotify:*`, NOT HTTP URLs.

 @param uri The Spotify URI of the artist to request.
 @param session An authenticated session. Can be `nil`.
 @param block The block to be called when the operation is complete. The block will pass a Spotify SDK metadata object on success, otherwise an error.
 */
+(void)artistWithURI:(NSURL *)uri session:(SPTSession *)session callback:(SPTRequestCallback)block;

/** The name of the artist. */
@property (nonatomic, readonly, copy) NSString *name;

/** The Spotify URI of the artist. */
@property (nonatomic, readonly, copy) NSURL *uri;

/** The HTTP open.spotify.com URL of the artist. */
@property (nonatomic, readonly, copy) NSURL *sharingURL;

/** Returns a list of genre strings for the artist. */
@property (nonatomic, readonly, copy) NSArray *genres;

/** Returns a list of artist images in various sizes, as `SPTImage` objects. */
@property (nonatomic, readonly, copy) NSArray *images;

/** Convenience method that returns the smallest available artist image. */
@property (nonatomic, readonly) SPTImage *smallestImage;

/** Convenience method that returns the largest available artist image. */
@property (nonatomic, readonly) SPTImage *largestImage;

/** The popularity of the artist as a value between 0.0 (least popular) to 100.0 (most popular). */
@property (nonatomic, readonly) double popularity;

@end
