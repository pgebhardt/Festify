//
//  PGFestifyTrackProvider.h
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@class SMFestifyTrackProvider;

@protocol SMFestifyTrackProviderDelegate <NSObject>

@optional
-(void)trackProvider:(SMFestifyTrackProvider*)trackProvider didAddPlaylistsFromUser:(NSString*)username withError:(NSError*)error;
-(void)trackProviderDidClearAllTracks:(SMFestifyTrackProvider*)trackProvider;

@end

@interface SMFestifyTrackProvider : NSObject<SPTTrackProvider>

-(id)init;
-(BOOL)addPlaylist:(SPTPlaylistSnapshot*)playlist;
-(void)addPlaylistsFromUser:(NSString*)username session:(SPTSession*)session completion:(void (^)(NSError* error))completion;
-(void)clearAllTracks;

@property id<SMFestifyTrackProviderDelegate> delegate;

@end