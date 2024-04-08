//
// NSString+ParsedDate.m
// Atomic SDK - Flutter
// Copyright © 2024 Atomic.io Limited. All rights reserved.
//

#import "NSString+ParsedDate.h"

@implementation NSString (ParsedDate)

- (NSDate *)aacFlutter_NSDateFromDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSDate *date = [dateFormatter dateFromString:self];
    return date;
}

@end
