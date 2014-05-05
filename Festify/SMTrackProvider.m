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

@property (nonatomic, strong) NSMutableArray* playlistURIs;
@property (nonatomic, strong) NSMutableArray* tracks;

@end

@implementation SMTrackProvider

-(id)init {
    if (self = [super init]) {
        self.playlistURIs = [NSMutableArray array];
        self.tracks = [NSMutableArray array];
    }
    
    return self;
}

-(void)clearAllTracks {
    [self.tracks removeAllObjects];
    [self.playlistURIs removeAllObjects];

    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidClearAllTracks object:self];
}

-(BOOL)addPlaylist:(SPTPlaylistSnapshot *)playlist {
    // check for existing playlist
    for (NSString* playlistURI in self.playlistURIs) {
        if ([playlistURI isEqualToString:playlist.uri.absoluteString]) {
            return NO;
        }
    }
    
    // add all tracks and playlist uri to arrays
    [self.tracks addObjectsFromArray:playlist.tracks];
    [self.playlistURIs addObject:playlist.uri.absoluteString];
    
    // shuffle tracks array
    [self.tracks shuffle];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SMTrackProviderDidAddPlaylist object:self];
    
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