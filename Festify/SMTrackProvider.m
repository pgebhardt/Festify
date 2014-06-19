//
//  PGFestifyTrackProvider.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "SMTrackProvider.h"
#import "SPTPlaylistSnapshot+AllTracks.h"

@interface SMTrackProvider ()
@property (nonatomic, strong) NSMutableDictionary* users;
@property (nonatomic, strong) NSMutableArray* tracksForPlayback;
@end

@implementation SMTrackProvider

-(id)init {
    if (self = [super init]) {
        self.users = [NSMutableDictionary dictionary];
        self.tracksForPlayback = [NSMutableArray array];
        
        // register to enter foreground notification to check and restart all timers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreTimersAfterSuspension:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setPlaylists:(NSArray *)playlists forUser:(NSString *)username withTimeoutInterval:(NSInteger)timeout session:(SPTSession*)session {
    NSMutableDictionary* userInfo = self.users[username];
    if (!userInfo) {
        userInfo = [NSMutableDictionary dictionary];
        self.users[username] = userInfo;
    }
    
    // add all tracks of all playlists to users track storage
    void (^addAllPlaylists)() = ^{
        NSMutableDictionary* playlistsDict = [NSMutableDictionary dictionary];
        userInfo[SMTrackProviderPlaylistsKey] = playlistsDict;
        
        for (NSUInteger i = 0; i < playlists.count; ++i) {
            [playlists[i] allTracksWithSession:session completion:^(NSArray *tracks, NSError *error) {
                if (!error) {
                    playlistsDict[[playlists[i] name]] = tracks;
                    if (i == playlists.count - 1) {
                        [self updateTracksArray];
                    }
                }
            }];
        }
    };
    
    // only update tracks array, if playlists are not identical
    if (userInfo[SMTrackProviderPlaylistsKey]) {
        NSArray* oldPlaylistNames = [[userInfo[SMTrackProviderPlaylistsKey] allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSArray* newPlaylistNames = [[playlists valueForKey:@"name"] sortedArrayUsingSelector:@selector(compare:)];
        
        if (![newPlaylistNames isEqualToArray:oldPlaylistNames]) {
            addAllPlaylists();
        }
    }
    else {
        addAllPlaylists();
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

    [self.tracksForPlayback removeAllObjects];
    [self.users removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidUpdateTracksArray object:self];
}

#pragma mark - SPTTrackProvider

-(NSArray *)tracksForPlayback {
    return _tracksForPlayback;
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

-(void)restoreTimersAfterSuspension:(id)notification {
    // TODO: Creates Crash!!
    // check all fire dates of the timers and either delete user or restart timer
    for (NSInteger i = 0; i < self.users.count; ++i) {
        NSMutableDictionary* userInfo = [self.users.allValues objectAtIndex:i];
        NSTimer* timer = [userInfo objectForKey:SMTrackProviderTimerKey];
        
        if (timer) {
            NSTimeInterval timeInterval = [timer.fireDate timeIntervalSinceNow];
            
            if (timeInterval <= 0.0) {
                [self timerHasExpired:timer];
            }
            else {
                [timer invalidate];
                userInfo[SMTrackProviderTimerKey] = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                                     target:self
                                                                                   selector:@selector(timerHasExpired:)
                                                                                   userInfo:self.users.allKeys[i]
                                                                                    repeats:NO];
            }
        }
    }
}

-(void)updateTracksArray {
    // select maximum 100 random songs of each user
    NSMutableArray* tracksOfUsers = [NSMutableArray array];
    for (NSInteger i = 0; i < self.users.count; ++i) {
        NSMutableArray* tracksOfUser = [NSMutableArray array];
        for (NSArray* playlist in [self.users.allValues[i][SMTrackProviderPlaylistsKey] allValues]) {
            [tracksOfUser addObjectsFromArray:playlist];
        }
        
        [self shuffleArray:tracksOfUser];
        [tracksOfUsers addObject:tracksOfUser];
    }

    [self.tracksForPlayback removeAllObjects];
    for (NSArray* tracks in tracksOfUsers) {
        NSIndexSet* indicesOfTracks = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,
            tracks.count < 100 ? tracks.count : 100)];
        [self.tracksForPlayback addObjectsFromArray:[tracks objectsAtIndexes:indicesOfTracks]];
    }
    
    [self shuffleArray:self.tracksForPlayback];
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidUpdateTracksArray object:self];
}

-(void)shuffleArray:(NSMutableArray*)array {
    static BOOL seeded = NO;
    if(!seeded) {
        seeded = YES;
        srandom((unsigned int)time(NULL));
    }
    
    for (NSUInteger i = 0; i < array.count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSUInteger nElements = array.count - i;
        NSUInteger n = (random() % nElements) + i;
        [array exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

@end