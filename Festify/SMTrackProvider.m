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
        userInfo[SMTrackProviderAddedDateKey] = [NSDate date];
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
    
    [self updateTimeoutInterval:timeout forUser:username];
}

-(void)updateTimeoutInterval:(NSInteger)timeout forUser:(NSString *)username {
    // get user info and update timer timeout
    NSMutableDictionary* userInfo = self.users[username];
    if (!userInfo) {
        return;
    }
    
    if (timeout != -1) {
        // create or update timer to delete user from track provider after timeout has expired
        if (!userInfo[SMTrackProviderTimerKey]) {
            NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)timeout * 60.0
                                                              target:self
                                                            selector:@selector(timerHasExpired:)
                                                            userInfo:username
                                                             repeats:NO];
            userInfo[SMTrackProviderTimerKey] = timer;
        }
        else {
            NSDate* dateAdded = userInfo[SMTrackProviderAddedDateKey];
            [userInfo[SMTrackProviderTimerKey] setFireDate:[NSDate dateWithTimeInterval:(NSTimeInterval)timeout * 60.0
                                                                              sinceDate:dateAdded]];
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
    [self removePlaylistsForUser:timer.userInfo];
}

-(void)updateTracksArray {
    [self.tracks removeAllObjects];
    
    for (NSDictionary* userInfo in self.users.allValues) {
        for (SPTPlaylistSnapshot* playlist in userInfo[SMTrackProviderPlaylistsKey]) {
            [self.tracks addObjectsFromArray:playlist.tracks];
        }
    }
    [self.tracks shuffle];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidUpdateTracksArray object:self];
}

@end