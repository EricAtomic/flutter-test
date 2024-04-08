//
// AACFlutterSingleCardView.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterSingleCardView.h"
#import "AACConfiguration+Flutter.h"
#import "AACFlutterContainerViewController.h"

@import AtomicSDK;

@implementation AACFlutterSingleCardViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id)args {
    return [[AACFlutterSingleCardView alloc] initWithFrame:frame
                                            viewIdentifier:viewId
                                                 arguments:args
                                           binaryMessenger:self.messenger];
}

@end

/**
 Custom subclass of single card view required to workaround a bug in Flutter's gesture handling.
 */
@interface AACFlutterSingleCardViewImpl: AACSingleCardView

@end

@implementation AACFlutterSingleCardViewImpl

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    
    if([NSStringFromClass(view.class) isEqualToString:@"AACLabel"]) {
        for(UIGestureRecognizer *recognizer in view.gestureRecognizers) {
            // When tapping on a label, ensure touches bubble up immediately.
            // This isn't an issue in native iOS implementations, but appears to be a conflict
            // with Flutter's gesture recognition engine.
            // Without this, the user has to long press on a submit button to submit a card, and this only works intermittently.
            recognizer.delaysTouchesEnded = NO;
        }
    }
    
    return view;
}

@end

@interface AACFlutterSingleCardView () <AACSingleCardViewDelegate, AACStreamContainerActionDelegate>

@property (nonatomic, strong) AACFlutterContainerViewController *containerViewController;
@property (nonatomic, strong) AACSingleCardView *singleCardView;

@end

@implementation AACFlutterSingleCardView

- (NSString *)viewType {
    return @"io.atomic.sdk.singleCard";
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
    
    self.containerViewController = [[AACFlutterContainerViewController alloc] init];
    
    UIViewController *rootViewController = [self rootViewController];
    if(rootViewController != nil) {
        [self.containerViewController willMoveToParentViewController:rootViewController];
        [rootViewController addChildViewController:self.containerViewController];
        [self.containerViewController didMoveToParentViewController:rootViewController];
    }
    
    self.singleCardView = [[AACFlutterSingleCardViewImpl alloc] initWithFrame:frame
                                                          containerIdentifier:containerId
                                                                configuration:configuration];
    
    self.singleCardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerViewController.view addSubview:self.singleCardView];
    self.singleCardView.delegate = self;
    
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[view]-(0)-|" options:0 metrics:nil views:@{ @"view": self.singleCardView }];
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[view]-(0)-|" options:0 metrics:nil views:@{ @"view": self.singleCardView }];
    
    [self.containerViewController.view addConstraints:hConstraints];
    [self.containerViewController.view addConstraints:vConstraints];
    [self.channel invokeMethod:@"viewLoaded" arguments:nil];
}

- (void)dealloc {
    [self.containerViewController willMoveToParentViewController:nil];
    [self.containerViewController.view removeFromSuperview];
    [self.containerViewController removeFromParentViewController];
    [self.containerViewController didMoveToParentViewController:nil];
    self.containerViewController = nil;
    
    [self.singleCardView removeFromSuperview];
    self.singleCardView.delegate = nil;
    self.singleCardView = nil;
}

- (void)singleCardView:(AACSingleCardView *)cardView willChangeSize:(CGSize)newSize {
    CGSize adjustedSize = CGSizeMake(newSize.width, MAX(1, newSize.height));
    
    [self.singleCardView layoutIfNeeded];
    [self.channel invokeMethod:@"sizeChanged"
                     arguments:@{
                         @"width": @(adjustedSize.width),
                         @"height": @(adjustedSize.height)
                     }];
}

- (void)applyFilters:(NSArray<AACCardFilter *> *)filters {
    [self.singleCardView applyFilters:filters];
}

- (void)refresh {
    [self.singleCardView refresh];
}

- (void)updateVariables {
    [self.singleCardView updateVariables];
}

@end
