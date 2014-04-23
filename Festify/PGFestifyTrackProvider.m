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

@property (nonatomic, strong) NSMutableArray* tracks;

@end

@implementation PGFestifyTrackProvider

-(id)init {
    if (self = [super init]) {
        self.tracks = [NSMutableArray array];
    }
    
    return self;
}

-(void)clearAllTracks {
    [self.tracks removeAllObjects];
}

-(void)addPlaylist:(SPTPlaylistSnapshot *)playlist {
    // add all tracks to tracks array
    [self.tracks addObjectsFromArray:playlist.tracks];
    
    // shuffle tracks array
    [self.tracks shuffle];
}

#pragma mark - SPTTrackProvider

-(NSArray *)tracks {
    return _tracks;
}

-(NSURL *)uri {
    return [NSURL URLWithString:@""];
}

@end