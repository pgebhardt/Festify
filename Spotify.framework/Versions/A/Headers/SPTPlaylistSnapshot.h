//
//  SPPlaylist.h
//  Basic Auth
//
//  Created by Daniel Kennett on 14/11/2013.
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
#import "SPTTypes.h"

@class SPTPlaylistSnapshot;
@class SPTSession;

typedef void (^SPTPlaylistMutationCallback)(NSError *error, SPTPlaylistSnapshot *playlist);

/** Represents a user's playlist on the Spotify service. */
@interface SPTPlaylistSnapshot : NSObject <SPTJSONObject, SPTTrackProvider>

/** The name of the playlist. */
@property (nonatomic, readonly, copy) NSString *name;

/** The version of the playlist. This is an opaque value, but newer versions of
 the same playlist will have a higher value. */
@property (nonatomic, readonly) NSInteger version;

/** The Spotify URI of the playlist. */
@property (nonatomic, readonly, copy) NSURL *uri;

/** `YES` if the playlist is collaborative (i.e., can be modified by anyone), otherwise `NO`. */
@property (nonatomic, readonly) BOOL collaborative;

/** The username of the playlist's creator. */
@property (nonatomic, readonly, copy) NSString *creator;

/** The tracks of the playlist, as `SPTPartialTrack` objects. */
@property (nonatomic, readonly, copy) NSArray *tracks;

/** The last time the playlist was modified. */
@property (nonatomic, readonly, copy) NSDate *dateModified;

/** Request the playlist at the given Spotify URI.

 @note This method takes Spotify URIs in the form `spotify:*`, NOT HTTP URLs.

 @param uri The Spotify URI of the playlist to request.
 @param session An authenticated session.
 @param block The block to be called when the operation is complete. The block will pass a Spotify SDK metadata object on success, otherwise an error.
 */
+(void)playlistWithURI:(NSURL *)uri session:(SPTSession *)session callback:(SPTRequestCallback)block;

/** Set the playlist's name. 
 
 @param name The new name.
 @param session An authenticated session.
 @param block The block to be called when the operation is complete. This block will pass an error if the operation failed, otherwise a new playlist snapshot reflecting the change.
 */
-(void)setPlaylistName:(NSString *)name withSession:(SPTSession *)session callback:(SPTPlaylistMutationCallback)block;

/** Set the playlist's description.

 @param desc The new description.
 @param session An authenticated session.
 @param block The block to be called when the operation is complete. This block will pass an error if the operation failed, otherwise a new playlist snapshot reflecting the change.
 */
-(void)setPlaylistDescription:(NSString *)desc withSession:(SPTSession *)session callback:(SPTPlaylistMutationCallback)block;

/** Set the playlist's collaborative status.

 @param collaborative The new value.
 @param session An authenticated session.
 @param block The block to be called when the operation is complete. This block will pass an error if the operation failed, otherwise a new playlist snapshot reflecting the change.
 */
-(void)setPlaylistIsCollaborative:(BOOL)collaborative withSession:(SPTSession *)session callback:(SPTPlaylistMutationCallback)block;

/** Delete the playlist.

 @param session An authenticated session.
 @param block The block to be called when the operation is complete. This block will pass an error if the operation failed.
 */
-(void)deletePlaylistWithSession:(SPTSession *)session callback:(SPTPlaylistMutationCallback)block;

/** Append tracks to the playlist.

 @param tracks The tracks to add, as `SPTTrack` or `SPTPartialTrack` objects.
 @param session An authenticated session.
 @param block The block to be called when the operation is complete. This block will pass an error if the operation failed, otherwise a new playlist snapshot reflecting the change.
 */
-(void)addTracksToPlaylist:(NSArray *)tracks withSession:(SPTSession *)session callback:(SPTPlaylistMutationCallback)block;

@end
