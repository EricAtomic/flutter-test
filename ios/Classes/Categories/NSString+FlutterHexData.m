//
// NSString+FlutterHexData.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "NSString+FlutterHexData.h"

@implementation NSString (FlutterHexData)

// From https://stackoverflow.com/a/13627835
- (NSData *)aacFlutter_dataFromHexString {
  NSString* hex = [self lowercaseString];
  NSMutableData *data = [[NSMutableData alloc] init];
  
  unsigned char whole_byte;
  char byte_chars[3] = {'\0', '\0', '\0'};
  
  int i = 0;
  int length = (int)hex.length;
  
  while(i < length - 1) {
    char c = [hex characterAtIndex:i++];
    
    if(c < '0' || (c > '9' && c < 'a') || c > 'f') {
      continue;
    }
    
    byte_chars[0] = c;
    byte_chars[1] = [hex characterAtIndex:i++];
    whole_byte = strtol(byte_chars, NULL, 16);
    [data appendBytes:&whole_byte length:1];
  }
  
  return data;
}

@end
