//
//  PGFestifyTrackProvider.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface PGFestifyTrackProvider : NSObject<SPTTrackProvider>

-(id)init;
-(BOOL)addPlaylist:(SPTPlaylistSnapshot*)playlist;
-(void)addPlaylistsFromUser:(NSString*)username session:(SPTSession*)session completion:(void (^)(NSError* error))completion;
-(void)clearAllTracks;

@end