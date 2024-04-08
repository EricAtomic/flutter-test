//
// AACFlutterSessionDelegateResolutionRequest.h
// Atomic SDK - Flutter
// Copyright © 2022 Atomic.io Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AtomicSDK;

/**
 Used internally by the SDK to match an auth token response to its original request.
 */
@interface AACFlutterSessionDelegateResolutionRequest: NSObject

/**
 Handler returned by the AACSessionDelegate implementation, called when a token is provided.
 */
@property (nonatomic, copy, nonnull) AACSessionAuthenticationTokenHandler handler;

/**
 Generated identifier that represents a specific authentication token request.
 */
@property (nonatomic, readonly, nonnull) NSString* identifier;

@end
