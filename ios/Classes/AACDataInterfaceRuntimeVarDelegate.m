//
// AACDataInterfaceRuntimeVarDelegate.m
// Atomic SDK - Flutter
// Copyright © 2024 Atomic.io Limited. All rights reserved.
//

#import "AACDataInterfaceRuntimeVarDelegate.h"

@implementation AACDataInterfaceRuntimeVarDelegate

- (void)cardSessionDidRequestRuntimeVariables:(NSArray<AACCardInstance *> *)cardsToResolve completionHandler:(AACSessionRuntimeVariablesHandler)completionHandler {
    if (self.runtimeVariables != nil && [self.runtimeVariables count] != 0) {
        for (AACCardInstance* cardInstance in cardsToResolve) {
            for (NSString* key in self.runtimeVariables) {
                [cardInstance resolveRuntimeVariableWithName:key value:self.runtimeVariables[key]];
            }
            
        }
        completionHandler(cardsToResolve);
    }
}

- (instancetype)initWithRuntimeVariables:(NSDictionary<NSString *, NSString *> * _Nullable)runtimeVariables {
    self = [super init];
    if (self) {
        _runtimeVariables = [runtimeVariables copy];
    }
    return self;
}

@end
