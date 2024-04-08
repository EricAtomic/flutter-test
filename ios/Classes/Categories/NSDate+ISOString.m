//
// NSString+ParsedDate.m
// Atomic SDK - Flutter
// Copyright © 2024 Atomic.io Limited. All rights reserved.
//

#import "NSDate+ISOString.h"

@implementation NSDate (ISOString)

- (NSString *)aacFlutter_ISONSStringFromNSDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSString *iso8601String = [dateFormatter stringFromDate:self];
    return iso8601String;
}

@end
