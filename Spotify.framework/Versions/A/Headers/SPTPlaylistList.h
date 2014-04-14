//
//  SPTPlaylistList.h
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
#import "SPTPlaylistSnapshot.h"
#import "SPTRequest.h"

@class SPTSession;

typedef void (^SPTPlaylistCreationCallback)(NSError *error, SPTPlaylistSnapshot *playlist);

/** This class represents a user's list of playlists. */
@interface SPTPlaylistList : NSObject <SPTJSONObject>

/** Returns the version of the playlist list. */
@property (nonatomic, readonly) NSInteger version;

/** Returns the username of the user that the playlist list belongs to. */
@property (nonatomic, readonly, copy) NSString *creator;

/** Returns the playlists contained in the list as an array of `SPTPartialPlaylist` objects. */
@property (nonatomic, readonly, copy) NSArray *items;

/** Returns the date motified of the playlist list. */
@property (nonatomic, readonly, copy) NSDate *dateModified;

/**
 Create a new playlist and add it to the this playlist list.
 
 @param name The name of the newly-created playlist. 
 @param session An authenticated session.
 @param block The callback block to be fired when playlist creation is completed (or fails).
 */
-(void)createPlaylistWithName:(NSString *)name session:(SPTSession *)session callback:(SPTPlaylistCreationCallback)block;

@end
