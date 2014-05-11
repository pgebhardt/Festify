//
//  PGFestifyTrackProvider.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMTrackProvider.h"
#import "NSMutableArray+Shuffling.h"

@interface SMTrackProvider ()

@property (nonatomic, strong) NSMutableDictionary* users;
@property (nonatomic, strong) NSMutableArray* tracks;

@end

@implementation SMTrackProvider

-(id)init {
    if (self = [super init]) {
        self.users = [NSMutableDictionary dictionary];
        self.tracks = [NSMutableArray array];
    }
    
    return self;
}

-(void)setPlaylists:(NSArray *)playlists forUser:(NSString *)username withTimeoutInterval:(NSInteger)timeout {
    NSMutableDictionary* userInfo = self.users[username];
    if (!userInfo) {
        userInfo = [NSMutableDictionary dictionary];
        self.users[username] = userInfo;
    }
    
    // only update tracks array, if playlists are not identical
    if (userInfo[SMTrackProviderPlaylistsKey]) {
        NSArray* oldPlaylistURIs = [[[userInfo[SMTrackProviderPlaylistsKey] valueForKey:@"uri"] valueForKey:@"absoluteString"] sortedArrayUsingSelector:@selector(compare:)];
        NSArray* newPlaylistURIs = [[[playlists valueForKey:@"uri"] valueForKey:@"absoluteString"] sortedArrayUsingSelector:@selector(compare:)];
        
        if (![newPlaylistURIs isEqualToArray:oldPlaylistURIs]) {
            userInfo[SMTrackProviderPlaylistsKey] = playlists;
            [self updateTracksArray];
        }
    }
    else {
        userInfo[SMTrackProviderPlaylistsKey] = playlists;
        [self updateTracksArray];
    }
    
    userInfo[SMTrackProviderDateUpdatedKey] = [NSDate date];
    [self updateTimeoutInterval:timeout forUser:username];
}

-(void)updateTimeoutInterval:(NSInteger)timeout forUser:(NSString *)username {
    // get user info and update timer timeout
    NSMutableDictionary* userInfo = self.users[username];
    if (!userInfo) {
        return;
    }
    
    if (timeout != 0) {
        // create or update timer to delete user from track provider after timeout has expired
        userInfo[SMTrackProviderDeletionWarningSentKey] = @NO;
        if (!userInfo[SMTrackProviderTimerKey]) {
            NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(timeout - 1) * 60.0
                                                              target:self
                                                            selector:@selector(timerHasExpired:)
                                                            userInfo:username
                                                             repeats:NO];
            userInfo[SMTrackProviderTimerKey] = timer;
        }
        else {
            NSDate* dateUpdated = userInfo[SMTrackProviderDateUpdatedKey];
            [userInfo[SMTrackProviderTimerKey] setFireDate:[NSDate dateWithTimeInterval:(NSTimeInterval)(timeout - 1) * 60.0
                                                                              sinceDate:dateUpdated]];
        }
    }
    else {
        // remove timer
        if (userInfo[SMTrackProviderTimerKey]) {
            [userInfo[SMTrackProviderTimerKey] invalidate];
            [userInfo removeObjectForKey:SMTrackProviderTimerKey];
        }
    }
}

-(void)removePlaylistsForUser:(NSString *)username {
    // remove user info and
    NSMutableDictionary* userInfo = self.users[username];
    if (!userInfo) {
        return;
    }
    
    [userInfo[SMTrackProviderTimerKey] invalidate];
    [self.users removeObjectForKey:username];
    
    [self updateTracksArray];
}

-(void)clear {
    for (NSDictionary* userInfo in self.users.allValues) {
        [userInfo[SMTrackProviderTimerKey] invalidate];
    }

    [self.tracks removeAllObjects];
    [self.users removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidUpdateTracksArray object:self];
}

#pragma mark - SPTTrackProvider

-(NSArray *)tracks {
    return _tracks;
}

-(NSURL *)uri {
    return [NSURL URLWithString:@""];
}

#pragma mark - Helper

-(void)timerHasExpired:(NSTimer*)timer {
    NSString* username = timer.userInfo;
    NSMutableDictionary* userInfo = self.users[username];
    [userInfo removeObjectForKey:SMTrackProviderTimerKey];
    
    // delete user from track provider if deletion warning was sent,
    // or inform delegate to update user within 1 minute
    if (![userInfo[SMTrackProviderDeletionWarningSentKey] boolValue]) {
        [self updateTimeoutInterval:(1 + 1) forUser:username];
        userInfo[SMTrackProviderDeletionWarningSentKey] = @YES;
        
        if (self.delegate) {
            [self.delegate trackProvider:self willDeleteUser:username];
        }
    }
    else {
        [self removePlaylistsForUser:timer.userInfo];
    }
}

-(void)updateTracksArray {
    // select maximum 100 random songs of each user
    NSMutableArray* tracksOfUser = [NSMutableArray array];
    for (NSInteger i = 0; i < self.users.count; ++i) {
        [tracksOfUser addObject:[NSMutableArray array]];
        
        for (SPTPlaylistSnapshot* playlist in self.users.allValues[i][SMTrackProviderPlaylistsKey]) {
            [tracksOfUser[i] addObjectsFromArray:playlist.tracks];
        }
        [tracksOfUser shuffle];
    }

    [self.tracks removeAllObjects];
    for (NSArray* tracks in tracksOfUser) {
        NSIndexSet* indicesOfTracks = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,
            tracks.count < 100 ? tracks.count : 100)];
        [self.tracks addObjectsFromArray:[tracks objectsAtIndexes:indicesOfTracks]];
    }
    
    [self.tracks shuffle];
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidUpdateTracksArray object:self];
}

@end