//
// AACFlutterViewFactory.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterViewFactory.h"

@implementation AACFlutterViewFactory

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    
    if(self) {
        _messenger = messenger;
    }
    
    return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id)args {
    // Overriden by subclasses.
    return nil;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterJSONMessageCodec sharedInstance];
}

- (NSString *)viewType {
    // Overridden by subclasses.
    return nil;
}

@end
