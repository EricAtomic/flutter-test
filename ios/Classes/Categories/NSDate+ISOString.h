//
// NSString+ParsedDate.h
// Atomic SDK - Flutter
// Copyright © 2024 Atomic.io Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ISOString)

/**
 Turns an NSDate into an ISO NSString
 */
- (NSString*)aacFlutter_ISONSStringFromNSDate;

@end
