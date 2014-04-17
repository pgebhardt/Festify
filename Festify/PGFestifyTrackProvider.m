//
//  PGFestifyTrackProvider.m
//  Festify
//
//  Created by Patrik Gebhardt on 15/04/14.
//  Copyright (c) 2014 Patrik Gebhardt. All rights reserved.
//

#import "PGFestifyTrackProvider.h"
#import "NSMutableArray+Shuffling.h"

@interface PGFestifyTrackProvider ()

@property (nonatomic, strong) SPTSession* session;
@property (nonatomic, strong) NSMutableDictionary* playlists;
@property (nonatomic, strong) NSMutableArray* tracks;

@end

@implementation PGFestifyTrackProvider

-(id)initWithSession:(SPTSession*)session {
    if (self = [super init]) {
        self.session = session;
        self.playlists = [NSMutableDictionary dictionary];
        self.tracks = [NSMutableArray array];
    }
    
    return self;
}

-(void)clearAllTracks {
    [self.playlists removeAllObjects];
    [self.tracks removeAllObjects];
}

-(BOOL)addPlaylist:(SPTPlaylistSnapshot *)playlist forIdentifier:(NSString *)identifier {
    // check for existing playlist
    for (NSDictionary* playlistDict in self.playlists.allValues) {
        if ([playlistDict[@"URI"] isEqualToString:playlist.uri.absoluteString]) {
            return NO;
        }
    }
    
    // cleanup tracks array
    [self.tracks removeAllObjects];
    
    // add playlist to dictionary to allow only one playlist per identifier
    self.playlists[identifier] = @{@"URI": playlist.uri.absoluteString,
                                   @"Tracks": [playlist.tracks copy]};
    
    // add all tracks to tracks array
    for (NSDictionary* playlistDict in self.playlists.allValues) {
        [self.tracks addObjectsFromArray:playlistDict[@"Tracks"]];
    }
    
    // shuffle tracks array
    [self.tracks shuffle];
    
    return YES;
}

#pragma mark - SPTTrackProvider

-(NSArray *)tracks {
    return _tracks;
}

-(NSURL *)uri {
    return [NSURL URLWithString:@""];
}

@end
