//
//  PGFestifyTrackProvider.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFestifyTrackProvider.h"

@interface PGFestifyTrackProvider ()

@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) NSMutableDictionary* playlists;

@end

@implementation PGFestifyTrackProvider

-(id)initWithSession:(SPTSession*)session {
    if (self = [super init]) {
        self.session = session;
        self.playlists = [NSMutableDictionary dictionary];
    }
    
    return self;
}

-(void)clearAllTracks {
    [self.playlists removeAllObjects];
}

#pragma mark - SPTTrackProvider

-(NSArray *)tracks {
    return self.playlists.allValues;
}

-(NSURL *)uri {
    return @"";
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri fromIdentifier:(NSUUID *)identifier {
    // retrieve tracks from playlist and add them to tracks array
    [SPTPlaylistSnapshot playlistWithURI:uri session:self.session callback:^(NSError *error, id object) {
        if (!error) {
            self.playlists[[identifier UUIDString]] = [[object tracks] copy];
        }
    }];
}

@end
