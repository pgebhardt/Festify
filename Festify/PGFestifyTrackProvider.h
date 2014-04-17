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

-(id)initWithSession:(SPTSession*)session;
-(BOOL)addPlaylist:(SPTPlaylistSnapshot*)playlist forIdentifier:(NSString*)identifier;
-(void)clearAllTracks;

@end
