//
//  AACFlutterSessionDelegateResolutionRequest.m
// Atomic SDK - Flutter
// Copyright © 2022 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterSessionDelegateResolutionRequest.h"

@implementation AACFlutterSessionDelegateResolutionRequest

- (instancetype)init {
  self = [super init];
  
  if(self) {
    _identifier = [[NSUUID UUID] UUIDString];
  }
  
  return self;
}

@end
