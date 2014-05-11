//
//  SMTrackPlayer.h
//  Festify
//
//  Created by Patrik Gebhardt on 28/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface SMTrackPlayer : NSObject<SPTTrackPlayerDelegate>

+(instancetype)trackPlayerWithCompanyName:(NSString*)companyName appName:(NSString*)appName;
-(id)initWithCompanyName:(NSString*)companyName appName:(NSString*)appName;

-(void)enablePlaybackWithSession:(SPTSession*)session callback:(SPTErrorableOperationCallback)block;
-(void)playTrackProvider:(id<SPTTrackProvider>)provider;
-(void)playTrackProvider:(id<SPTTrackProvider>)provider fromIndex:(NSInteger)index;
-(void)clear;
-(void)logout;

-(void)play;
-(void)pause;
-(void)skipToTrack:(NSInteger)index;
-(void)skipForward;
-(void)skipBackward;

@property (nonatomic, readonly) id<SPTTrackProvider> currentProvider;
@property (nonatomic, readonly) NSInteger indexOfCurrentTrack;
@property (nonatomic, readonly) NSTimeInterval currentPlaybackPosition;
@property (nonatomic, readonly) BOOL playing;
@property (nonatomic, readonly) SPTTrack* currentTrack;
@property (nonatomic, readonly) UIImage* coverArtOfCurrentTrack;
@property (nonatomic, readonly) SPTSession* session;

@end
