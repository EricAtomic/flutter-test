//
// AACValidateArguments.h
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterLogger.h"

static NSString* AACValidateArgumentsImpl(id arguments, NSArray<Class>* types, BOOL canBeNull) {
    NSString *result = @"";
    if([arguments isKindOfClass:NSArray.class] == NO) {
        result = [NSString stringWithFormat:@"Argument validation failed: expected NSArray but received %@.", arguments];
        [AACFlutterLogger log:@"%@", result];
    }
    
    NSArray *args = (NSArray*)arguments;
    
    // Check we have the right number of arguments.
    if(args.count != types.count) {
        result = [NSString stringWithFormat:@"Argument validation failed: count mismatch. Expected %@ arguments but received %@.", @(types.count), @(args.count)];
        [AACFlutterLogger log:@"%@", result];
    }
    
    // Check each argument is of the correct type.
    for(int i = 0; i < args.count; i++) {
        BOOL passed = [args[i] isKindOfClass:types[i]];
        if(passed == NO && canBeNull) {
            passed = [args[i] isKindOfClass:NSNull.class];
        }
        if(passed == NO) {
            result = [NSString stringWithFormat:@"Argument validation failed: argument at index %@ was not of type %@, got %@ instead.", @(i), NSStringFromClass(types[i]), args[i]];
            [AACFlutterLogger log:@"%@", result];
        }
    }
    
    return result;
};
#define AACValidateArguments(args, types, result) NSString* aacArgumentsValidateResult = AACValidateArgumentsImpl(args, types, NO); if(aacArgumentsValidateResult.length > 0) { result([FlutterError errorWithCode:@"InvalidArguments" message:aacArgumentsValidateResult details:nil]); return; }

// The argument can also be NSNull.
#define AACValidateArgumentsAllowNull(args, types, result) NSString* aacArgumentsValidateResult = AACValidateArgumentsImpl(args, types, YES); if(aacArgumentsValidateResult.length > 0) { result([FlutterError errorWithCode:@"InvalidArguments" message:aacArgumentsValidateResult details:nil]); return; }

