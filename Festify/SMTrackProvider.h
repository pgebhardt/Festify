//
//  PGFestifyTrackProvider.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

// notification strings
static NSString* const SMTrackProviderDidUpdateTracksArray = @"SMTrackProviderDidUpdateTracksArray";

// users dictionary key
static NSString* const SMTrackProviderPlaylistsKey = @"SMTrackProviderPlaylistsKey";
static NSString* const SMTrackProviderTimerKey = @"SMTrackProviderTimerKey";
static NSString* const SMTrackProviderDateUpdatedKey = @"SMTrackProviderDateUpdatedKey";

@interface SMTrackProvider : NSObject<SPTTrackProvider>

-(id)init;
-(void)setPlaylists:(NSArray*)playlists forUser:(NSString*)username withTimeoutInterval:(NSInteger)timeout;
-(void)updateTimeoutInterval:(NSInteger)timeout forUser:(NSString*)username;
-(void)removePlaylistsForUser:(NSString*)username;
-(void)clear;

@property (nonatomic, readonly) NSMutableDictionary* users;

@end