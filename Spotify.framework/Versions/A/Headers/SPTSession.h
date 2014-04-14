//
//  SPTSession.h
//  Spotify iOS SDK
//
//  Created by Daniel Kennett on 2014-02-19.
/*
 Copyright 2014 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>

/**
 This class represents a user logged in using the Spotify oAuth service.
 */
@interface SPTSession : NSObject

/**
 Initialise an SPTSession. 
 
 @param userName The username of the user.
 @param credential The login token of the user. 
 @return Returns the initialised session.
 */
-(id)initWithUserName:(NSString *)userName credential:(NSString *)credential;

/**
 Initialise an SPTSession from a previously stored state.
 
 @param plistRep A representation of the session as obtained from -propertyListRepresentation.
 @return Returns the initialised session, or `nil` if an invalid representation is given.
 */
-(id)initWithPropertyListRepresentation:(id)plistRep;

/** Returns a representation of the session for serialising.
 
 The value returned by this method is suitable for storing without further encryption,
 such as in `NSUserDefaults` or similar.
 */
-(id)propertyListRepresentation;

/** Returns the canonical username of the user. */
@property (nonatomic, copy, readonly) NSString *canonicalUsername;

/** Returns the login token of the user. */
@property (nonatomic, copy, readonly) NSString *credential;

@end
