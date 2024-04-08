//
// AACConfiguration+Flutter.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACConfiguration+Flutter.h"

static NSDictionary *kAACFlutterVotingMapping = nil;
static NSDictionary *kAACFlutterInterfaceStyleMapping = nil;
static NSDictionary *kAACFlutterCustomStringMapping = nil;
static NSDictionary *kAACFlutterPresentationStyleMapping = nil;
static NSDictionary *kAACHorizontalContainerConfigurationEmptyStyleMapping = nil;
static NSDictionary *kAACHorizontalContainerConfigurationHeaderAlignmentMapping = nil;
static NSDictionary *kAACHorizontalContainerConfigurationLastCardAlignmentMapping = nil;
static NSDictionary *kAACHorizontalContainerConfigurationScrollModeMapping = nil;
static CGFloat kAACColourScale = 255.0f;

@implementation AACConfiguration (Flutter)

+ (AACConfiguration *)fromFlutterDictionary:(NSDictionary *)dict {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAACFlutterVotingMapping = @{
            @"none": @(AACCardVotingOptionNone),
            @"both": @(AACCardVotingOptionUseful | AACCardVotingOptionNotUseful),
            @"useful": @(AACCardVotingOptionUseful),
            @"notUseful": @(AACCardVotingOptionNotUseful)
        };
        kAACFlutterInterfaceStyleMapping = @{
            @"automatic": @(AACConfigurationInterfaceStyleAutomatic),
            @"light": @(AACConfigurationInterfaceStyleLight),
            @"dark": @(AACConfigurationInterfaceStyleDark)
        };
        kAACFlutterCustomStringMapping = @{
            @"votingUseful": @(AACCustomStringVotingUseful),
            @"cardListTitle":@(AACCustomStringCardListTitle),
            @"cardSnoozeTitle":@(AACCustomStringCardSnoozeTitle),
            @"votingNotUseful":@(AACCustomStringVotingNotUseful),
            @"allCardsCompleted":@(AACCustomStringAllCardsCompleted),
            @"awaitingFirstCard":@(AACCustomStringAwaitingFirstCard),
            @"votingFeedbackTitle":@(AACCustomStringVotingFeedbackTitle),
            @"cardListFooterMessage":@(AACCustomStringCardListFooterMessage),
            @"tryAgainTitle":@(AACCustomStringTryAgainTitle),
            @"dataLoadFailedMessage":@(AACCustomStringDataLoadFailedMessage),
            @"noInternetConnectionMessage":@(AACCustomStringNoInternetConnectionMessage),
            @"toastCardDismissedMessage":@(AACCustomStringToastCardDismissedMessage),
            @"toastCardCompletedMessage":@(AACCustomStringToastCardCompletedMessage),
            @"toastCardSnoozeMessage":@(AACCustomStringToastCardSnoozeMessage),
            @"toastCardFeedbackMessage":@(AACCustomStringToastCardFeedbackMessage),
        };
        kAACFlutterPresentationStyleMapping = @{
            @"withoutButton": @(AACConfigurationPresentationStyleWithoutButton),
            @"withActionButton": @(AACConfigurationPresentationStyleWithActionButton),
            @"withContextualButton": @(AACConfigurationPresentationStyleWithContextualButton),
        };
        kAACHorizontalContainerConfigurationEmptyStyleMapping = @{
            @"standard": @(AACHorizontalContainerConfigurationEmptyStyleStandard),
            @"shrink": @(AACHorizontalContainerConfigurationEmptyStyleShrink),
        };
        kAACHorizontalContainerConfigurationHeaderAlignmentMapping = @{
            @"center": @(AACHorizontalContainerConfigurationHeaderAlignmentCenter),
            @"left": @(AACHorizontalContainerConfigurationHeaderAlignmentLeft),
        };
        kAACHorizontalContainerConfigurationLastCardAlignmentMapping = @{
            @"left": @(AACHorizontalContainerConfigurationLastCardAlignmentLeft),
            @"center": @(AACHorizontalContainerConfigurationLastCardAlignmentCenter),
        };
        kAACHorizontalContainerConfigurationScrollModeMapping = @{
            @"snap": @(AACHorizontalContainerConfigurationScrollModeSnap),
            @"free": @(AACHorizontalContainerConfigurationScrollModeFree),
        };
    });
    
    AACConfiguration *config = [[AACConfiguration alloc] init];
    
    id automaticallyLoadNextCard = dict[@"automaticallyLoadNextCard"];
    if(automaticallyLoadNextCard != nil && [automaticallyLoadNextCard isKindOfClass:NSNumber.class]) {
        AACSingleCardConfiguration *singleConfig = [[AACSingleCardConfiguration alloc] init];
        singleConfig.automaticallyLoadNextCard = [(NSNumber*)automaticallyLoadNextCard boolValue];
        config = singleConfig;
    }
    id cardWidth = dict[@"cardWidth"];
    if(cardWidth != nil && [cardWidth isKindOfClass:NSNumber.class]) {
        AACHorizontalContainerConfiguration *horizonConfig = [[AACHorizontalContainerConfiguration alloc] init];
        horizonConfig.cardWidth = [(NSNumber *)cardWidth doubleValue];
        id emptyStyle = dict[@"emptyStyle"];
        if(emptyStyle != nil && [emptyStyle isKindOfClass:NSString.class]) {
            horizonConfig.emptyStyle = [kAACHorizontalContainerConfigurationEmptyStyleMapping[emptyStyle] intValue];
        }
        id headerAlignment = dict[@"headerAlignment"];
        if(headerAlignment != nil && [headerAlignment isKindOfClass:NSString.class]) {
            horizonConfig.headerAlignment = [kAACHorizontalContainerConfigurationHeaderAlignmentMapping[headerAlignment] intValue];
        }
        id lastCardAlignment = dict[@"lastCardAlignment"];
        if(lastCardAlignment != nil && [lastCardAlignment isKindOfClass:NSString.class]) {
            horizonConfig.lastCardAlignment = [kAACHorizontalContainerConfigurationLastCardAlignmentMapping[lastCardAlignment] intValue];
        }
        id scrollMode = dict[@"scrollMode"];
        if(scrollMode != nil && [scrollMode isKindOfClass:NSString.class]) {
            horizonConfig.scrollMode = [kAACHorizontalContainerConfigurationScrollModeMapping[scrollMode] intValue];
        }
        config = horizonConfig;
    }
    id pollingInterval = dict[@"pollingInterval"];
    id cardVotingOptions = dict[@"cardVotingOptions"];
    id launchColors = dict[@"launchColors"];
    id interfaceStyle = dict[@"interfaceStyle"];
    id customStrings = dict[@"customStrings"];
    id presentationStyle = dict[@"presentationStyle"];
    id enabledUiElements = dict[@"enabledUiElements"];
    id runtimeVariableTimeout = dict[@"runtimeVariableResolutionTimeout"];
    id runtimeVariableAnalytics = dict[@"runtimeVariableAnalytics"];
   
    if(pollingInterval != nil && [pollingInterval isKindOfClass:NSNumber.class]) {
        config.cardListRefreshInterval = [pollingInterval doubleValue];
    }
    
    if(cardVotingOptions != nil && [cardVotingOptions isKindOfClass:NSString.class]) {
        AACCardVotingOption option = [kAACFlutterVotingMapping[cardVotingOptions] intValue];
        config.cardVotingOptions = option;
    }
    
    if(launchColors != nil && [launchColors isKindOfClass:NSDictionary.class]) {
        config.launchBackgroundColor = [self colourFromInt:launchColors[@"background"]];
        config.launchLoadingIndicatorColor = [self colourFromInt:launchColors[@"loadingIndicator"]];
        config.launchButtonColor = [self colourFromInt:launchColors[@"button"]];
        config.launchTextColor = [self colourFromInt:launchColors[@"text"]];
    }

    if(interfaceStyle != nil && [interfaceStyle isKindOfClass:NSString.class]) {
        config.interfaceStyle = [kAACFlutterInterfaceStyleMapping[interfaceStyle] intValue];
    }
    
    if(customStrings != nil && [customStrings isKindOfClass:NSDictionary.class]) {
        for (NSString *key in customStrings) {
            id value = customStrings[key];
            if([value isKindOfClass:NSString.class]) {
                AACCustomString customStringKey = [kAACFlutterCustomStringMapping[key] intValue];
                [config setValue:value forCustomString:customStringKey];
            }
        }
    }
    
    if(presentationStyle != nil && [presentationStyle isKindOfClass:NSString.class]) {
        config.presentationStyle = [kAACFlutterPresentationStyleMapping[presentationStyle] intValue];
    }
    
    if(enabledUiElements != nil && [enabledUiElements isKindOfClass:NSArray.class]) {
        AACUIElement elements = AACUIElementNone;
        for(NSString *elementName in enabledUiElements) {
            if([elementName isEqualToString:@"cardListToast"]) {
                elements |= AACUIElementCardListToast;
            } else if([elementName isEqualToString:@"cardListFooterMessage"]) {
                elements |= AACUIElementCardListFooterMessage;
            } else if([elementName isEqualToString:@"cardListHeader"]) {
                elements |= AACUIElementCardListHeader;
            }
        }
        config.enabledUiElements = elements;
    }
    
    if(runtimeVariableTimeout != nil && [runtimeVariableTimeout isKindOfClass:NSNumber.class]) {
        config.runtimeVariableResolutionTimeout = [runtimeVariableTimeout doubleValue];
    }
    
    if(runtimeVariableAnalytics != nil && [runtimeVariableAnalytics isKindOfClass:NSNumber.class]) {
        config.features.runtimeVariableAnalytics = [(NSNumber*)runtimeVariableAnalytics boolValue];
    }
    return config;
}

+ (UIColor*)colourFromInt:(id)object {
    if(object == nil || [object isKindOfClass:NSNumber.class] == NO) {
        return nil;
    }
    
    int value = [object intValue];
    
    int opacity = (0xff000000 & value) >> 24;
    int r = (0x00ff0000 & value) >> 16;
    int g = (0x0000ff00 & value) >> 8;
    int b = (0x000000ff & value) >> 0;
    
    return [UIColor colorWithRed:r/kAACColourScale
                           green:g/kAACColourScale
                            blue:b/kAACColourScale
                           alpha:opacity/kAACColourScale];
}

@end
