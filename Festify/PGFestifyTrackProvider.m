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
@property (nonatomic, strong) NSMutableArray* tracksArray;
@property (nonatomic, strong) NSMutableArray* playlistURIs;

@end

@implementation PGFestifyTrackProvider

-(id)initWithSession:(SPTSession*)session {
    if (self = [super init]) {
        self.session = session;
        self.tracksArray = [NSMutableArray array];
        self.playlistURIs = [NSMutableArray array];
    }
    
    return self;
}

-(void)clearAllTracks {
    [self.tracksArray removeAllObjects];
    [self.playlistURIs removeAllObjects];
}

#pragma mark - SPTTrackProvider

-(NSArray *)tracks {
    return self.tracksArray;
}

-(NSURL *)uri {
    return nil;
}

#pragma mark - PGDiscoveryManagerDelegate

-(void)discoveryManager:(PGDiscoveryManager *)discoveryManager didDiscoverPlaylistWithURI:(NSURL *)uri {
    // retrieve tracks from playlist and add them to tracks array
    [SPTPlaylistSnapshot playlistWithURI:uri session:self.session callback:^(NSError *error, id object) {
        if (!error) {
            // check if playlist is not already included
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", self.playlistURIs];
            if (![predicate evaluateWithObject:uri]) {
                [self.tracksArray addObjectsFromArray:[object tracks]];
                [self.playlistURIs addObject:uri];
            }
        }
    }];
}

@end
