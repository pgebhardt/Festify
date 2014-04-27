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

@property (nonatomic, strong) NSMutableArray* playlistURIs;
@property (nonatomic, strong) NSMutableArray* tracks;

@end

@implementation PGFestifyTrackProvider

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
    
    if (self.delegate) {
        [self.delegate trackProviderDidClearAllTracks:self];
    }
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
    
    return YES;
}

-(void)addPlaylistsFromUser:(NSString *)username session:(SPTSession *)session completion:(void (^)(NSError *))completion {
    // reguest and add all playlists of the given user
    [SPTRequest playlistsForUser:username withSession:session callback:^(NSError *error, id object) {
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(trackProvider:didAddPlaylistsFromUser:withError:)]) {
                [self.delegate trackProvider:self didAddPlaylistsFromUser:username withError:error];
            }
            if (completion) {
                completion(error);
            }
        }
        else {
            SPTPlaylistList* playlists = object;
            for (NSUInteger i = 0; i < playlists.items.count; ++i) {
                [SPTRequest requestItemFromPartialObject:playlists.items[i] withSession:session callback:^(NSError* error, id object) {
                    if (!error) {
                        [self addPlaylist:object];
                    }
                    
                    if (i == playlists.items.count - 1) {
                        NSError* error = nil;
                        if (self.tracks.count == 0) {
                            error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier code:1 userInfo:nil];
                        }
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(trackProvider:didAddPlaylistsFromUser:withError:)]) {
                            [self.delegate trackProvider:self didAddPlaylistsFromUser:username withError:error];
                        }
                        if (completion) {
                            completion(error);
                        }
                    }
                }];
            }
        }
    }];
}


#pragma mark - SPTTrackProvider

-(NSArray *)tracks {
    return _tracks;
}

-(NSURL *)uri {
    return [NSURL URLWithString:@""];
}

@end