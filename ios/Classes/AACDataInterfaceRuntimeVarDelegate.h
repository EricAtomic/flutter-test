//
// AACDataInterfaceRuntimeVarDelegate.h
// Atomic SDK - Flutter
// Copyright © 2024 Atomic.io Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AtomicSDK;

@interface AACDataInterfaceRuntimeVarDelegate : NSObject <AACRuntimeVariableDelegate>

@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> * _Nullable runtimeVariables;

- (instancetype _Nonnull )initWithRuntimeVariables:(NSDictionary<NSString *, NSString *> * _Nullable)runtimeVariables;

- (void)cardSessionDidRequestRuntimeVariables:(NSArray<AACCardInstance *> *_Nullable)cardsToResolve completionHandler:(AACSessionRuntimeVariablesHandler _Nonnull )completionHandler;

@end
