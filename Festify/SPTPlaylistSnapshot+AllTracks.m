//
//  SPTPlaylistSnapshot+AllTracks.m
//  Festify
//
//  Created by Patrik Gebhardt on 19/06/14.
//  Copyright (c) 2014 SchnuffMade. All rights reserved.
//

#import "SPTPlaylistSnapshot+AllTracks.h"

@implementation SPTPlaylistSnapshot (AllTracks)

void callback(SPTListPage* listPage, SPTSession* session, NSMutableArray* tracksArray, void (^completion)(NSArray* tracks, NSError* error)) {
    if (listPage) {
        [tracksArray addObjectsFromArray:listPage.items];
        
        if (listPage.hasNextPage) {
            [listPage requestNextPageWithSession:session callback:^(NSError *error, id object) {
                if (!error) {
                    callback(object, session, tracksArray, completion);
                }
                else {
                    completion(nil, error);
                }
            }];
        }
        else {
            completion(tracksArray, nil);
        }
    }
}

// retrieve all tracks from all track pages
-(void)allTracksWithSession:(SPTSession*)session completion:(void (^)(NSArray* tracks, NSError* error))completion {
    NSMutableArray* allTracks = [NSMutableArray array];
    callback(self.firstTrackPage, session, allTracks, completion);
}

@end
