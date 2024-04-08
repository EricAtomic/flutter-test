//
// AACFlutterContainerViewController.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterContainerViewController.h"
@import UIKit;
@import AtomicSDK;

@interface AACFlutterContainerViewController ()

@end

@implementation AACFlutterContainerViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Call `viewWillTransitionToSize:` to ensure that cards are resized correctly on rotation. This isn't required in the native
    // SDK as Flutter intercepts the layout call for the card list before the parent view has the correct size, causing cards
    // to be sized at their previous (incorrect) dimensions.
    for(UIViewController *vc in self.childViewControllers) {
        if([vc isKindOfClass:AACStreamContainerViewController.class]) {
            AACStreamContainerViewController *svc = (AACStreamContainerViewController*)vc;
            [svc viewWillTransitionToSize:self.view.frame.size
                withTransitionCoordinator:self.transitionCoordinator];
        }
    }
}

- (void)dealloc {
    for(UIViewController *vc in self.childViewControllers) {
        [vc.view removeFromSuperview];
        [vc willMoveToParentViewController:nil];
        [vc removeFromParentViewController];
        [vc didMoveToParentViewController:nil];
    }
}

@end
