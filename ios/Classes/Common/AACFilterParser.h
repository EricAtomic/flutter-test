//
// AACFilterParser.h
// Atomic SDK - Flutter
// Copyright © 2024 Atomic.io Limited. All rights reserved.
//

@import AtomicSDK;

@interface AACFilterParser: NSObject

+ (NSArray<AACCardFilter *> *)parseFiltersFromJson:(NSArray<NSDictionary<NSString *, id> *> *)filterJsons;

@end
