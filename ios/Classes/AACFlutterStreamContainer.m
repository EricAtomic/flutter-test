//
// AACFlutterStreamContainer.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterStreamContainer.h"
#import "AACConfiguration+Flutter.h"
#import "AACFlutterContainerViewController.h"
@import AtomicSDK;

@interface AACFlutterStreamContainerFactory ()

@end

@implementation AACFlutterStreamContainerFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id)args {
    return [[AACFlutterStreamContainer alloc] initWithFrame:frame
                                             viewIdentifier:viewId
                                                  arguments:args
                                            binaryMessenger:self.messenger];
}

@end

@interface AACFlutterStreamContainer () <AACStreamContainerActionDelegate>

@property (nonatomic, strong) AACFlutterContainerViewController *containerViewController;
@property (nonatomic, strong) AACStreamContainerViewController *streamContainerViewController;

@end

@implementation AACFlutterStreamContainer

- (NSString *)viewType {
    return @"io.atomic.sdk.streamContainer";
}

- (UIView *)view {
    return self.containerViewController.view;
}

- (void)createViewWithFrame:(CGRect)frame
                containerId:(NSString *)containerId
              configuration:(AACConfiguration *)configuration {
    if(containerId == nil) {
        return;
    }
    
    AACStreamContainerViewController *vc = [[AACStreamContainerViewController alloc] initWithIdentifier:containerId
                                                                                          configuration:configuration];
    self.streamContainerViewController = vc;
    self.containerViewController = [[AACFlutterContainerViewController alloc] init];
    
    UIViewController *rootViewController = [self rootViewController];
    [self.containerViewController willMoveToParentViewController:rootViewController];
    [rootViewController addChildViewController:self.containerViewController];
    [self.containerViewController didMoveToParentViewController:rootViewController];
    
    [self.containerViewController addChildViewController:vc];
    [vc willMoveToParentViewController:self.containerViewController];
    vc.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerViewController.view addSubview:vc.view];
    
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[view]-(0)-|" options:0 metrics:nil views:@{ @"view": vc.view }];
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[view]-(0)-|" options:0 metrics:nil views:@{ @"view": vc.view }];
    
    [self.containerViewController.view addConstraints:hConstraints];
    [self.containerViewController.view addConstraints:vConstraints];
    
    [vc didMoveToParentViewController:self.containerViewController];
    [self.channel invokeMethod:@"viewLoaded" arguments:nil];
}

- (void)dealloc {
    [self.containerViewController willMoveToParentViewController:nil];
    [self.containerViewController.view removeFromSuperview];
    [self.containerViewController removeFromParentViewController];
    [self.containerViewController didMoveToParentViewController:nil];
    
    self.containerViewController = nil;
    
    [self.streamContainerViewController.view removeFromSuperview];
    self.streamContainerViewController = nil;
}

- (void)applyFilters:(NSArray<AACCardFilter *> *)filters {
    [self.streamContainerViewController applyFilters:filters];
}

- (void)refresh {
    [self.streamContainerViewController refresh];
}

- (void)updateVariables {
    [self.streamContainerViewController updateVariables];
}

#pragma mark - AACStreamContainerActionDelegate
- (void)streamContainerDidTapActionButton:(AACStreamContainerViewController *)streamContainer {    
    [self.channel invokeMethod:@"didTapActionButton" arguments:@{}];
}
@end
