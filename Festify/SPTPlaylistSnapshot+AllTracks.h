//
//  SPTPlaylistSnapshot+AllTracks.h
//  Festify
//
//  Created by Patrik Gebhardt on 19/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface SPTPlaylistSnapshot (AllTracks)

-(void)allTracksWithSession:(SPTSession*)session completion:(void (^)(NSArray* tracks, NSError* error))completion;

@end