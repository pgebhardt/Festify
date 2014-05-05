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
static NSString* const SMTrackProviderDidAddPlaylist = @"SMTrackProviderDidAddPlaylist";
static NSString* const SMTrackProviderDidClearAllTracks = @"SMTrackProviderDidClearAllTracks";

@interface SMTrackProvider : NSObject<SPTTrackProvider>

-(id)init;
-(BOOL)addPlaylist:(SPTPlaylistSnapshot*)playlist;
-(void)clearAllTracks;

@end