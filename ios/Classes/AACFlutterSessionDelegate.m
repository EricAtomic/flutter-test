//
// AACFlutterSessionDelegate.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterSessionDelegate.h"
#import "AACFlutterSessionDelegateResolutionRequest.h"
#import "AACFlutterLogger.h"

@interface AACFlutterSessionDelegate ()

@property (nonatomic, strong) NSMutableDictionary<NSString*, AACFlutterSessionDelegateResolutionRequest*>* sessionDelegateRequests;

@end

@implementation AACFlutterSessionDelegate

- (instancetype)init {
  self = [super init];
  
  if(self) {
      self.sessionDelegateRequests = [[NSMutableDictionary alloc] init];
      self.retryIntervalFromFlutter = 0;
      self.expiryIntervalFromFlutter = 60;
  }
  
  return self;
}

- (void)cardSessionDidRequestAuthenticationTokenWithHandler:(AACSessionAuthenticationTokenHandler)handler {
    AACFlutterSessionDelegateResolutionRequest *request = [[AACFlutterSessionDelegateResolutionRequest alloc] init];
    request.handler = handler;
    self.sessionDelegateRequests[request.identifier] = request;
    self.authTokenCallback(request.identifier);
}

- (void)didReceiveAuthenticationToken:(NSString *)token forIdentifier:(NSString *)identifier {
    AACFlutterSessionDelegateResolutionRequest *request = self.sessionDelegateRequests[identifier];
    
    if(request != nil) {
        request.handler(token);
        [self.sessionDelegateRequests removeObjectForKey:identifier];
    } else {
        [AACFlutterLogger error:@"Request received for authentication token (%@) but no matching request was found.", identifier];
    }
}

- (NSTimeInterval)retryInterval {
    return self.retryIntervalFromFlutter;
}

- (NSTimeInterval)expiryInterval {
    return self.expiryIntervalFromFlutter;
}

@end
