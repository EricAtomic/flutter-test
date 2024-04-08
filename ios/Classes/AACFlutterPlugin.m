//
// AACFlutterPlugin.m
// Atomic SDK - Flutter
// Copyright © 2021 Atomic.io Limited. All rights reserved.
//

#import "AACFlutterPlugin.h"
#import "AACFlutterStreamContainer.h"
#import "AACFlutterSingleCardView.h"
#import "AACFlutterSessionDelegate.h"
#import "NSString+FlutterHexData.h"
#import "AACFlutterCardCountObserver.h"
#import "AACValidateArguments.h"
#import "AACFlutterHorizontalContainerView.h"
#import "NSString+ParsedDate.h"
#import "AACFilterParser.h"
#import "NSDate+ISOString.h"
#import "AACDataInterfaceRuntimeVarDelegate.h"

@import AtomicSDK;

static int kAACFlutterCardCountObserverId = 1;

static NSDictionary *kAACFlutterFontWeight = nil;
static NSDictionary *kAACFlutterFontStyle = nil;

@interface AACFlutterPlugin ()

@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) NSMutableDictionary *cardCountObservers;
@property (nonatomic, strong) AACFlutterSessionDelegate *sessionDelegate;
@property (nonatomic) NSTimeInterval authTokenRetryInterval;
@property (nonatomic) NSTimeInterval authTokenExpiryInterval;

@end

@implementation AACFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    AACFlutterStreamContainerFactory *factory = [[AACFlutterStreamContainerFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:factory withId:@"io.atomic.sdk.streamContainer"];
    
    AACFlutterSingleCardViewFactory *scvFactory = [[AACFlutterSingleCardViewFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:scvFactory withId:@"io.atomic.sdk.singleCard"];
    
    AACFlutterHorizontalContainerViewFactory *hcvFactory = [[AACFlutterHorizontalContainerViewFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:hcvFactory withId:@"io.atomic.sdk.horizontalContainer"];
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"io.atomic.sdk.session" binaryMessenger:registrar.messenger];
    AACFlutterPlugin *plugin = [[AACFlutterPlugin alloc] initWithMethodChannel:channel];
    [registrar addMethodCallDelegate:plugin channel:channel];
}

- (instancetype)initWithMethodChannel:(FlutterMethodChannel*)channel {
    self = [super init];
    
    if(self) {
        self.channel = channel;
        self.cardCountObservers = [[NSMutableDictionary alloc] init];
        self.authTokenRetryInterval = 0;
        self.authTokenExpiryInterval = 60;
    }
    
    return self;
}

// Handle method calls for static methods on the SDK.
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if([call.method isEqual:@"setApiBaseUrl"]) {
        AACValidateArguments(call.arguments, @[ NSString.class ], result);
        [self setApiBaseUrl:call.arguments[0]];
        result(@(YES));
    } else if([call.method isEqual:@"initialise"]) {
        NSArray *types = @[ NSString.class, NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self initialiseWithEnvironmentId:call.arguments[0] apiKey:call.arguments[1]];
        result(@(YES));
    } else if([call.method isEqual:@"enableDebugMode"]) {
        AACValidateArguments(call.arguments, @[ NSNumber.class ], result);
        NSNumber* numberValue = (NSNumber*)call.arguments[0];
        [self enableDebugMode:numberValue.intValue];
        result(@(YES));
    } else if([call.method isEqual:@"onAuthTokenReceived"]) {
        NSArray *types = @[ NSString.class, NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self.sessionDelegate didReceiveAuthenticationToken:call.arguments[0] forIdentifier:call.arguments[1]];
        result(@(YES));
    } else if([call.method isEqual:@"logout"]) {
        AACValidateArguments(call.arguments, @[], result);
        [self logout:result];
    } else if([call.method isEqual:@"registerDeviceForNotifications"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self registerDeviceForNotifications:call.arguments[0]
                                      result:result];
    } else if([call.method isEqual:@"registerStreamContainersForNotifications"]) {
        NSArray *types = @[ NSArray.class ];
        AACValidateArguments(call.arguments, types, result);
        [self registerStreamContainersForNotifications:call.arguments[0]
                                                result:result];
    } else if([call.method isEqual:@"registerStreamContainersForNotificationsEnabled"]) {
        NSArray *types = @[ NSArray.class, NSNumber.class ];
        AACValidateArguments(call.arguments, types, result);
        BOOL enabled = [(NSNumber*)call.arguments[2] boolValue];
        [self registerStreamContainersForNotifications:call.arguments[0]
                                               enabled:enabled
                                                result:result];
    } else if([call.method isEqual:@"deregisterDeviceForNotifications"]) {
        AACValidateArguments(call.arguments, @[], result);
        [self deregisterDeviceForNotifications:result];
    } else if([call.method isEqual:@"notificationFromPushPayload"]) {
        AACValidateArguments(call.arguments, @[ NSDictionary.class ], result);
        [self notificationFromPushPayload:call.arguments[0]
                                   result:result];
    } else if([call.method isEqual:@"startObservingSDKEvents"]) {
        AACValidateArguments(call.arguments, @[], result);
        [self startObservingSDKEvents:result];
    } else if([call.method isEqual:@"stopObservingSDKEvents"]) {
        AACValidateArguments(call.arguments, @[], result);
        [self stopObservingSDKEvents:result];
    } else if([call.method isEqual:@"observeCardCount"]) {
        NSArray *types = @[ NSString.class, NSNumber.class, NSArray.class ];
        AACValidateArguments(call.arguments, types, result);
        [self observeCardCount:call.arguments[0]
             atPollingInterval:call.arguments[1]
                filterJsonList:call.arguments[2]
                        result:result];
    } else if([call.method isEqual:@"stopObservingCardCount"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self stopObservingCardCount:call.arguments[0]
                              result:result];
    } else if([call.method isEqual:@"trackPushNotificationReceived"]) {
        NSArray *types = @[ NSDictionary.class ];
        AACValidateArguments(call.arguments, types, result);
        [self trackPushNotificationReceived:call.arguments[0]
                                     result:result];
    } else if([call.method isEqual:@"sendEvent"]) {
        NSArray *types = @[ NSDictionary.class ];
        AACValidateArguments(call.arguments, types, result);
        [self sendEvent:call.arguments[0]
                 result:result];
    } else if([call.method isEqual:@"requestCardCount"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self requestCardCountForStreamContainerWithIdentifier:call.arguments[0]
                                                        result:result];
    } else if([call.method isEqual:@"userMetrics"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self userMetricsForStreamContainerWithIdentifier:call.arguments[0]
                                                   result:result];
    } else if([call.method isEqual:@"registerEmbeddedFonts"]) {
        NSArray *types = @[ NSArray.class ];
        AACValidateArguments(call.arguments, types, result);
        [self registerEmbeddedFonts:call.arguments[0]];
        result(@(YES));
    } else if([call.method isEqual:@"setApiProtocol"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self setApiProtocol:call.arguments[0]];
        result(@(YES));
    } else if([call.method isEqual:@"setSessionDelegateRetryInterval"]) {
        NSArray *types = @[ NSNumber.class];
        AACValidateArguments(call.arguments, types, result);
        [self setSessionDelegateRetryInterval:call.arguments[0]];
        result(@(YES));
    } else if([call.method isEqual:@"setSessionDelegateExpiryInterval"]) {
        NSArray *types = @[ NSNumber.class];
        AACValidateArguments(call.arguments, types, result);
        [self setSessionDelegateExpiryInterval:call.arguments[0]];
        result(@(YES));
    } else if([call.method isEqual:@"sendCustomEvent"]) {
        NSArray *types = @[ NSString.class, NSDictionary.class ];
        AACValidateArgumentsAllowNull(call.arguments, types, result);
        NSDictionary *properties = nil;
        if([call.arguments[1] isKindOfClass:NSDictionary.class]) {
            properties = call.arguments[1];
        }
        [self sendCustomEvent:call.arguments[0] properties:properties result:result];
    } else if([call.method isEqual:@"updateUser"]) {
        NSArray *types = @[ NSDictionary.class ];
        AACValidateArguments(call.arguments, types, result);
        [self updateUser:call.arguments[0] result:result];
    } else if([call.method isEqual:@"setClientAppVersion"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self setClientAppVersion:call.arguments[0]];
        result(@(YES));
    } else if([call.method isEqual:@"setSessionDelegate"]) {
        [self settingUpSessionDelegate];
        result(@(YES));
    } else if([call.method isEqual:@"observeStreamContainer"]) {
        NSArray *types = @[ NSString.class, NSDictionary.class ];
        AACValidateArguments(call.arguments, types, result);
        [self observeStreamContainer:call.arguments[0] configJson:call.arguments[1]  result:result];
    } else if ([call.method isEqual:@"stopObservingStreamContainer"]) {
        NSArray *types = @[ NSString.class ];
        AACValidateArguments(call.arguments, types, result);
        [self stopObservingStreamContainer:call.arguments[0] result:result];
    } else if ([call.method isEqual:@"executeCardAction"]) {
        [self executeCardActionWithContainerId:call.arguments[0] cardId:call.arguments[1] actionType:call.arguments[2] actionArg:call.arguments[3] result:result];
    } else {
        NSString *message = [NSString stringWithFormat:@"Method call (%@) not implemented.", call.method];
        [AACFlutterLogger warn:message];
        result(@(YES));
    }
}

#pragma mark - SDK method implementations

- (void) executeCardActionWithContainerId:(NSString*) containerId
                                   cardId:(NSString*) cardId
                               actionType:(NSString*) actionType
                               actionArg:(id) actionArg
                                   result:(FlutterResult) result {
    AACSessionCardAction* action;
    if ([actionType  isEqual: @"Dismiss"]) {
        action = [[AACSessionCardAction alloc] initDismissActionWithContainerId:containerId cardId:cardId];
    }
    else if ([actionType  isEqual: @"Snooze"]) {
        action = [[AACSessionCardAction alloc] initSnoozeActionWithContainerId:containerId cardId:cardId snoozeInterval:((NSNumber*)actionArg).doubleValue];
    }
    else if ([actionType  isEqual: @"Submit"]) {
        action = [[AACSessionCardAction alloc] initSubmitActionWithContainerId:containerId cardId:cardId submitValues:(NSDictionary<NSString*, id>*)actionArg];
    }
    else {
        @throw [NSException exceptionWithName:@"ExecuteCardActionTypeException" reason:[NSString stringWithFormat:@"Unknown actionType: %@", actionType] userInfo:nil];
    }
    [AACSession onCardAction:action completionHandler:^(NSError* error){
        if (error == nil) {
            result(@"Success");
        }
        else {
            if (error.code == AACSessionCardActionsErrorCodeNetworkError) {
                result(@"NetworkError");
            }
            else if (error.code == AACSessionCardActionsErrorCodeDataError) {
                NSLog(@"Error executing card action: %@", error);
                result(@"DataError");
            }
            else {
                @throw [NSException exceptionWithName:@"OnCardActionException" reason:[NSString stringWithFormat:@"Unknown error: %@", error] userInfo:nil];
            }
        }
    }];
}

NSString* AACCardNodeDatePickerFormatToString(AACCardNodeDatePickerFormat format) {
    switch (format) {
        case AACCardNodeDatePickerFormatInline:
            return @"inline";
        case AACCardNodeDatePickerFormatStacked:
            return @"stacked";
        default:
            return @"unknown";
    }
}

NSString* AACCardNodeDropdownFormatToString(AACCardNodeDropdownFormat format) {
    switch (format) {
        case AACCardNodeDropdownFormatInline:
            return @"inline";
        case AACCardNodeDropdownFormatStacked:
            return @"stacked";
        default:
            return @"unknown";
    }
}

NSString* AACCardNodeListStyleToString(AACCardNodeListStyle style) {
    switch (style) {
        case AACCardNodeListStyleComma:
            return @"comma";
        case AACCardNodeListStyleOrdered:
            return @"number";
        case AACCardNodeListStyleUnordered:
            return @"unordered";
        default:
            return @"unknown";
    }
}

NSString* AACCardNodeMediaKindToString(AACCardNodeMediaKind mediaKind) {
    switch (mediaKind) {
        case AACCardNodeMediaKindImage:
            return @"image";
        case AACCardNodeMediaKindVideo:
            return @"video";
        default:
            return @"unknown";
    }
}

NSString* AACCardNodeMediaFormatToString(AACCardNodeMediaFormat mediaFormat) {
    switch (mediaFormat) {
        case AACCardNodeMediaFormatText:
            return @"text";
        case AACCardNodeMediaFormatBanner:
            return @"banner";
        case AACCardNodeMediaFormatInline:
            return @"inline";
        case AACCardNodeMediaFormatThumbnail:
            return @"thumbnail";
        default:
            return @"unknown";
    }
}

NSDictionary<NSString *, id>* toJsonFromNode(AACCardNode *node) {
    NSString* type = node.type;
    NSMutableArray<AACCardNode*>* children = [NSMutableArray array];
    if (node.children != nil) {
        children = node.children.mutableCopy;
    }
    
    NSMutableDictionary<NSString*, id>* validationsJson = [NSMutableDictionary dictionary];
//    for (AACValidation* validation in node.validator.validations) {
          // NOTICE AACValidationRequired not found
//        if ([validation isKindOfClass:AACValidationRequired.class]) {
//            ...
//        }
//        ...
//    }
    
    NSMutableDictionary<NSString*, id>* attributesJson = [NSMutableDictionary dictionary]; //TODO
    //if ([node isKindOfClass:AACCardNodePlaceHolder.class]) // NOTICE not found
    //if ([node isKindOfClass:AACCardNodeRadioGroup.class]) // NOTICE not found
    //if ([node isKindOfClass:AACCardNodeRadioItem.class]) // NOTICE not found
    if ([node isKindOfClass:AACCardNodeText.class]) {
        AACCardNodeText* nodeText = (AACCardNodeText*) node;
        attributesJson[@"icon"] = nodeText.icon;
        attributesJson[@"text"] = nodeText.text;
        // Setting the type here manually because for some reason the type is nil sometimes for this node class.
        type = @"text";
    }
    else if ([node isKindOfClass:AACCardNodeMedia.class]) {
        AACCardNodeMedia* nodeMedia = (AACCardNodeMedia*) node;
        attributesJson[@"label"] = nodeMedia.label;
        attributesJson[@"mediaDescription"] = nodeMedia.mediaDescription;
        attributesJson[@"thumbnailUrl"] = nodeMedia.thumbnailUrl.description;
        attributesJson[@"url"] = nodeMedia.url.description;
        attributesJson[@"thumbnailAlternateText"] = nodeMedia.thumbnailAlternateText;
        attributesJson[@"alternateText"] = nodeMedia.alternateText;
        //attributesJson[@"actionUrl"] = nodeMedia.actionUrl; // NOTICE not found
        //attributesJson[@"actionLayoutName"] = nodeMedia.actionLayoutName; // NOTICE not found
        //attributesJson[@"actionPayload"] = nodeMedia.actionPayload; // NOTICE not found
        //nodeMedia.actionType // NOTICE not found
        attributesJson[@"mediaKind"] = AACCardNodeMediaKindToString(nodeMedia.mediaKind);
        attributesJson[@"format"] = AACCardNodeMediaFormatToString(nodeMedia.format);
    }
    else if ([node isKindOfClass:AACCardNodeListItem.class]) {
        AACCardNodeListItem* nodeListItem = (AACCardNodeListItem*) node;
        attributesJson[@"text"] = nodeListItem.text;
        attributesJson[@"icon"] = nodeListItem.icon;
        attributesJson[@"preIcon"] = nodeListItem.preIcon;
        attributesJson[@"style"] = AACCardNodeListStyleToString(nodeListItem.style);
        attributesJson[@"sequenceNumber"] = @(nodeListItem.sequenceNumber);
        attributesJson[@"sequencePlaceholder"] = @(nodeListItem.sequencePlaceHolder);
        attributesJson[@"isLastItem"] = @(nodeListItem.isLastItem);
    }
    else if ([node isKindOfClass:AACCardNodeList.class]) {
        AACCardNodeList* nodeList = (AACCardNodeList*) node;
        attributesJson[@"style"] = AACCardNodeListStyleToString(nodeList.style);
        if ([node isKindOfClass:AACCardNodeListComma.class]) {
            AACCardNodeListComma* nodeListComma = (AACCardNodeListComma*) node;
            attributesJson[@"listText"] = nodeListComma.listText;
        }
    }
    else if ([node isKindOfClass:AACCardNodeSubmittable.class]) {
        AACCardNodeSubmittable* nodeSubmittable = (AACCardNodeSubmittable*) node;
        attributesJson[@"name"] = nodeSubmittable.name;
        attributesJson[@"storedResponseValue"] = nodeSubmittable.storedResponseValue;
        attributesJson[@"needValidation"] = @(nodeSubmittable.needValidation);
        if ([node isKindOfClass:AACCardNodeTextInput.class]) {
            AACCardNodeTextInput* textInput = (AACCardNodeTextInput*) node;
            attributesJson[@"placeholder"] = textInput.placeholder;
            attributesJson[@"defaultValue"] = textInput.defaultValue;
            attributesJson[@"numberOfLines"] = textInput.numberOfLines;
            attributesJson[@"thumbnailUrl"] = textInput.thumbnailUrl.description;
            attributesJson[@"maximumLength"] = textInput.maximumLength;
        }
        else if ([node isKindOfClass:AACCardNodeStepper.class]) {
            AACCardNodeStepper* nodeStepper = (AACCardNodeStepper*) node;
            attributesJson[@"label"] = nodeStepper.label;
            attributesJson[@"thumbnailUrl"] = nodeStepper.thumbnailUrl.description;
            attributesJson[@"minimumValue"] = nodeStepper.minimumValue;
            attributesJson[@"maximumValue"] = nodeStepper.maximumValue;
            attributesJson[@"stepValue"] = nodeStepper.stepValue;
            attributesJson[@"defaultValue"] = nodeStepper.defaultValue;
        }
        else if ([node isKindOfClass:AACCardNodeSwitch.class]) {
            AACCardNodeSwitch* nodeSwitch = (AACCardNodeSwitch*) node;
            attributesJson[@"label"] = nodeSwitch.label;
            attributesJson[@"thumbnailUrl"] = nodeSwitch.thumbnailUrl.description;
            attributesJson[@"defaultValue"] = @(nodeSwitch.defaultValue);
        }
        else if ([node isKindOfClass:AACCardNodeNumberInput.class]) {
            AACCardNodeNumberInput* numberInput = (AACCardNodeNumberInput*) node;
            attributesJson[@"placeholder"] = numberInput.placeholder;
            attributesJson[@"defaultValue"] = numberInput.defaultValue;
            attributesJson[@"thumbnailUrl"] = numberInput.thumbnailUrl.description;
        }
        else if ([node isKindOfClass:AACCardNodeDropdown.class]) {
            AACCardNodeDropdown* nodeDropdown = (AACCardNodeDropdown*) node;
            attributesJson[@"label"] = nodeDropdown.label;
            attributesJson[@"defaultValue"] = nodeDropdown.defaultValue;
            attributesJson[@"thumbnailUrl"] = nodeDropdown.thumbnailUrl.description;
            attributesJson[@"placeholder"] = nodeDropdown.placeholder;
            attributesJson[@"format"] = AACCardNodeDropdownFormatToString(nodeDropdown.format);
            NSMutableArray<NSDictionary<NSString*, id>*>* dropdownValuesJsonList = @[].mutableCopy;
            for (AACCardNodeDropdownValue* dropdownValue in nodeDropdown.values) {
                [dropdownValuesJsonList addObject:@{
                    @"value" : dropdownValue.value,
                    @"title" : dropdownValue.title,
                }];
            }
            attributesJson[@"values"] = dropdownValuesJsonList;
        }
        else if ([node isKindOfClass:AACCardNodeDatePicker.class]) {
            AACCardNodeDatePicker* datePicker = (AACCardNodeDatePicker*) node;
            attributesJson[@"label"] = datePicker.label;
            attributesJson[@"minimumValue"] = datePicker.minimumValue.aacFlutter_ISONSStringFromNSDate;
            attributesJson[@"defaultValue"] = datePicker.defaultValue.aacFlutter_ISONSStringFromNSDate;
            attributesJson[@"maximumValue"] = datePicker.maximumValue.aacFlutter_ISONSStringFromNSDate;
            attributesJson[@"thumbnailUrl"] = datePicker.thumbnailUrl.description;
            attributesJson[@"placeholder"] = datePicker.placeholder;
            attributesJson[@"format"] = AACCardNodeDatePickerFormatToString(datePicker.format);
        }
    }
    else if ([node isKindOfClass:AACCardNodeHeading1.class]) {
        AACCardNodeHeading1* nodeHeading1 = (AACCardNodeHeading1*) node;
        attributesJson[@"text"] = nodeHeading1.text;
    }
    else if ([node isKindOfClass:AACCardNodeCategory.class]) {
        AACCardNodeCategory* nodeCategory = (AACCardNodeCategory*) node;
        attributesJson[@"text"] = nodeCategory.text;
    }
    else if ([node isKindOfClass:AACCardNodeForm.class]) {
        AACCardNodeForm* nodeForm = (AACCardNodeForm*) node;
        attributesJson[@"responseDefinition"] = nodeForm.responseDefinition;
        attributesJson[@"defaultValues"] = nodeForm.defaultValues;
        [children addObjectsFromArray:node.buttons];
    }
    else if ([node isKindOfClass:AACCardBaseButton.class]) {
        AACCardBaseButton* baseButton = (AACCardBaseButton*) node;
        attributesJson[@"text"] = baseButton.text;
        attributesJson[@"icon"] = baseButton.icon;
        if ([node isKindOfClass:AACCardActionButton.class]) {
            if ([node isKindOfClass:AACCardNodeSnoozeButton.class]) {
                AACCardNodeSnoozeButton* nodeSnoozeButton = (AACCardNodeSnoozeButton*) node;
                attributesJson[@"snoozeDate"] = [nodeSnoozeButton snoozeDateFromDate:NSDate.date].aacFlutter_ISONSStringFromNSDate;
            }
        }
        else if ([node isKindOfClass:AACCardNodeButton.class]) {
            AACCardNodeButton* nodeButton = (AACCardNodeButton*) node;
            attributesJson[@"url"] = nodeButton.urlString;
            attributesJson[@"action"] = nodeButton.actionPayload;
            if ([node isKindOfClass:AACCardNodeLinkButton.class]) {
                AACCardNodeLinkButton* linkButton = (AACCardNodeLinkButton*) node;
                attributesJson[@"layoutName"] = linkButton.layoutName;
            }
            else if ([node isKindOfClass:AACCardNodeSubmitButton.class]) {
                AACCardNodeSubmitButton* submitButton = (AACCardNodeSubmitButton*) node;
                attributesJson[@"values"] = submitButton.values;
            }
        }
    }
    
    NSMutableDictionary<NSString *, id> *nodeJson = @{
        @"type" : type == nil ? @"unknown type" : type,
        @"attributes" : attributesJson,
        @"validations" : validationsJson,
    }.mutableCopy;
    
    NSMutableArray<NSDictionary<NSString *, id> *> *childrenJsonList = @[].mutableCopy;
    if (children != nil) {
        // NOTICE after testing this, children is always either nil or an empty list (). Might need to wait for iOS to be updated as this is currently only an MVP feature.
        for (AACCardNode *childNode in children) {
            NSDictionary<NSString *, id> *childJson = toJsonFromNode(childNode);
            if (childJson) {
                [childrenJsonList addObject:childJson];
            }
        }
    }
    nodeJson[@"children"] = childrenJsonList;
    
    return nodeJson;
}

- (void)observeStreamContainer:(NSString*) containerId
                    configJson:(NSDictionary<NSString*, id> *)configJson
                        result:(FlutterResult)result {
    bool runtimeVariableAnalytics = configJson[@"runtimeVariableAnalytics"];
    NSNumber* runtimeVariableResolutionTimeout = configJson[@"runtimeVariableResolutionTimeout"];
    NSArray<NSDictionary<NSString*, id>*>*  _Nullable filtersJsonList = configJson[@"filters"];
    NSNumber* pollingInterval = configJson[@"pollingInterval"];
    
    NSDictionary<NSString*, NSString*>*  _Nullable runtimeVariables = configJson[@"runtimeVariables"];
    AACDataInterfaceRuntimeVarDelegate* runtimeVariablesDelegate = [[AACDataInterfaceRuntimeVarDelegate alloc] initWithRuntimeVariables:runtimeVariables];
    
    AACStreamContainerObserverConfiguration* config = AACStreamContainerObserverConfiguration.new;
    config.sendRuntimeVariableAnalytics = runtimeVariableAnalytics;
    config.runtimeVariableResolutionTimeout = runtimeVariableResolutionTimeout.doubleValue;
    config.filters = [AACFilterParser parseFiltersFromJson:filtersJsonList];
    config.runtimeVariableDelegate = runtimeVariablesDelegate;
    // 1000 minumum polling interval
    double pollingIntervalDouble = pollingInterval.doubleValue;
    if (pollingIntervalDouble < 1000) {
        pollingIntervalDouble = 1000;
    }
    config.cardListRefreshInterval = pollingIntervalDouble;
    
    __block NSString* token;
    token = [AACSession observeStreamContainerWithIdentifier:containerId configuration:config completionHandler:^(NSArray<AACCardInstance *> * _Nullable cards) {
        NSMutableArray<NSDictionary<NSString*, id>*>* cardJsonList = [NSMutableArray array];
        for (AACCardInstance* card in cards) {
            NSMutableDictionary<NSString*, id>* runtimeVariablesJson = [NSMutableDictionary dictionary];
            for (AACCardRuntimeVariable* runtimeVar in card.runtimeVariables) {
                runtimeVariablesJson[runtimeVar.name] = runtimeVar.defaultValue;
            }
            
            NSMutableArray<NSDictionary<NSString*, id>*>* defaultViewNodes = @[].mutableCopy;
            for (AACCardNode* node in card.defaultLayout.nodes) {
                [defaultViewNodes addObject:toJsonFromNode(node)];
            }
            
            NSDictionary<NSString*, id>* cardJson = @{
                @"instance" : @{
                    @"id" : card.detail.cardId,
                    @"eventName" : card.detail.eventName,
                    @"lifecycleId" : card.lifecycleId,
                    @"status" : card.detail.status,
                },
                @"actions" : @{
                    @"dismiss" : @{
                        @"swipe" : @(!card.actionFlags.dismissSwipeDisabled),
                        @"overflow" : @(!card.actionFlags.dismissOverflowDisabled),
                    },
                    @"snooze" : @{
                        @"swipe" : @(!card.actionFlags.snoozeSwipeDisabled),
                        @"overflow" : @(!card.actionFlags.snoozeOverflowDisabled),
                    },
                    @"voteUp" : @{
                        @"overflow" : @(!card.actionFlags.voteUpOverflowDisabled),
                    },
                    @"voteDown" : @{
                        @"overflow" : @(!card.actionFlags.voteDownOverflowDisabled),
                    },
                },
                @"defaultView" : @{
                    @"nodes" : defaultViewNodes,
                },
                @"subviews" : @{
                    // NOTICE not implemented in iOS yet. It has a layoutWithName()
                    // TODO once iOS has added a way to retrieve all subview names, I need to implement it here.
                    @"" : @{
                        @"title" : @"",
                        @"nodes" : @[],
                    },
                },
                @"metadata" : @{
                    // NOTICE there is no title property in iOS, but there is on Android.
                    // TODO set title once we figure out where it is.
                    @"title" : @"",
                    @"receivedAt" : card.metadata.updatedTime.aacFlutter_ISONSStringFromNSDate,
                    @"lastCardActiveTime" : card.metadata.lastCardActiveTime.aacFlutter_ISONSStringFromNSDate,
                    @"priority" : card.metadata.priority,
                },
                @"runtimeVariables" : runtimeVariablesJson,
            };
            
            [cardJsonList addObject:cardJson];
        }
        
        [self.channel invokeMethod:@"onStreamContainerObserved" arguments:@{
            @"identifier" : token,
            @"cards": cardJsonList
        }];
    }].description;
    result(token);
}

- (void)stopObservingStreamContainer:(NSString*) observerToken result:(FlutterResult)result {
    [AACSession stopObservingStreamContainer:observerToken];
    result(@(YES));
}

- (void)settingUpSessionDelegate {
    if(self.sessionDelegate != nil) {
        return;
    }
    self.sessionDelegate = [[AACFlutterSessionDelegate alloc] init];
    
    __weak typeof(self) weakSelf = self;
    self.sessionDelegate.authTokenCallback = ^(NSString *identifier) {
        if(weakSelf != nil) {
            [weakSelf.channel invokeMethod:@"authTokenRequested" arguments:@{
                @"identifier": identifier
            }];
        }
    };
    self.sessionDelegate.retryIntervalFromFlutter = self.authTokenRetryInterval;
    self.sessionDelegate.expiryIntervalFromFlutter = self.authTokenExpiryInterval;
    [AACSession setSessionDelegate:self.sessionDelegate];
}

- (void)setClientAppVersion:(NSString *)versionString {
    [AACSession setClientAppVersion:versionString];
}

- (AACUserNotificationTimeframeWeekdays)weekdayFromString:(NSString *)weekdayString {
    if([weekdayString isEqualToString:@"monday"]) {
        return AACUserNotificationTimeframeWeekdaysMonday;
    } else if([weekdayString isEqualToString:@"tuesday"]) {
        return AACUserNotificationTimeframeWeekdaysTuesday;
    } else if([weekdayString isEqualToString:@"wednesday"]) {
        return AACUserNotificationTimeframeWeekdaysWednesday;
    } else if([weekdayString isEqualToString:@"thursday"]) {
        return AACUserNotificationTimeframeWeekdaysThursday;
    } else if([weekdayString isEqualToString:@"friday"]) {
        return AACUserNotificationTimeframeWeekdaysFriday;
    } else if([weekdayString isEqualToString:@"saturday"]) {
        return AACUserNotificationTimeframeWeekdaysSaturday;
    } else if([weekdayString isEqualToString:@"sunday"]) {
        return AACUserNotificationTimeframeWeekdaysSunday;
    }
    return AACUserNotificationTimeframeWeekdaysDefault;
}

-(void)updateUser:(NSDictionary *)userSettings
           result:(FlutterResult)result {
    AACUserSettings *parsedSettings = [[AACUserSettings alloc] init];
    NSString *parsedStringValue = userSettings[@"externalID"];
    if(parsedStringValue.length > 0) {
        parsedSettings.externalID = parsedStringValue;
    }
    parsedStringValue = userSettings[@"name"];
    if(parsedStringValue.length > 0) {
        parsedSettings.name = parsedStringValue;
    }
    parsedStringValue = userSettings[@"email"];
    if(parsedStringValue.length > 0) {
        parsedSettings.email = parsedStringValue;
    }
    parsedStringValue = userSettings[@"phone"];
    if(parsedStringValue.length > 0) {
        parsedSettings.phone = parsedStringValue;
    }
    parsedStringValue = userSettings[@"city"];
    if(parsedStringValue.length > 0) {
        parsedSettings.city = parsedStringValue;
    }
    parsedStringValue = userSettings[@"country"];
    if(parsedStringValue.length > 0) {
        parsedSettings.country = parsedStringValue;
    }
    parsedStringValue = userSettings[@"region"];
    if(parsedStringValue.length > 0) {
        parsedSettings.region = parsedStringValue;
    }
    parsedSettings.notificationsEnabled = [userSettings[@"notificationsEnabled"] boolValue];
    
    // Custom text fields.
    if([userSettings[@"textCustomFields"] isKindOfClass:NSDictionary.class]) {
        NSDictionary *textCustomFields = userSettings[@"textCustomFields"];
        for(NSString* key in textCustomFields) {
            [parsedSettings setText:[textCustomFields objectForKey:key] forCustomField:key];
        }
    }
    
    // Custom date fields.
    if([userSettings[@"dateCustomFields"] isKindOfClass:NSDictionary.class]) {
        NSDictionary *dateCustomFields = userSettings[@"dateCustomFields"];
        for(NSString* key in dateCustomFields) {
            NSDate *date = [[dateCustomFields objectForKey:key] aacFlutter_NSDateFromDateString];
            [parsedSettings setDate:date forCustomField:key];
        }
    }
    
    if([userSettings[@"notificationTimeframes"] isKindOfClass:NSDictionary.class]) {
        NSDictionary *notificationTimeframes = userSettings[@"notificationTimeframes"];
        for(NSString *key in notificationTimeframes) {
            AACUserNotificationTimeframeWeekdays weekday = [self weekdayFromString:key];
            NSArray *timeframes = notificationTimeframes[key];
            NSMutableArray *parsedTimeframes = [NSMutableArray array];
            for(NSDictionary *timeframe in timeframes) {
                AACUserNotificationTimeframe *parsedTimeframe = [[AACUserNotificationTimeframe alloc] initWithStartHour:[timeframe[@"startHour"] intValue] startMinute:[timeframe[@"startMinute"] intValue] endHour:[timeframe[@"endHour"] intValue] endMinute:[timeframe[@"endMinute"] intValue]];
                [parsedTimeframes addObject: parsedTimeframe];
            }
            [parsedSettings setNotificationTime:parsedTimeframes weekday:weekday];
        }
    }
    
    [AACSession updateUser:parsedSettings completionHandler:^(NSError *error) {
        if(error == nil) {
            result(@(YES));
        } else {
            [AACFlutterLogger log:@"Failed to update the user. %@", error];
            NSString *errorCode = [NSString stringWithFormat:@"%@ (error code %@)", error.domain, @(error.code)];
            FlutterError *flutterError = [FlutterError errorWithCode:errorCode message:error.localizedDescription details:nil];
            result(flutterError);
        }
    }];
}

-(void)sendCustomEvent:(NSString *)eventName
            properties:(NSDictionary *)properties
                result:(FlutterResult)result {
    AACCustomEvent *event = [[AACCustomEvent alloc] initWithName:eventName properties:properties];
    [AACSession sendCustomEvent:event completionHandler:^(NSError *error) {
        if(error == nil) {
            result(@(YES));
        } else{
            [AACFlutterLogger log:@"Failed to send custom event. %@", error];
            NSString *errorCode = [NSString stringWithFormat:@"%@ (error code %@)", error.domain, @(error.code)];
            FlutterError *flutterError = [FlutterError errorWithCode:errorCode message:error.localizedDescription details:nil];
            result(flutterError);
        }
    }];
}

-(void)setSessionDelegateExpiryInterval:(NSNumber *)expiryInterval {
    if(expiryInterval.doubleValue < 0) {
        return;
    }
    self.authTokenExpiryInterval = expiryInterval.doubleValue;
    if(self.sessionDelegate != nil) {
        self.sessionDelegate.expiryIntervalFromFlutter = expiryInterval.doubleValue;
        [AACSession setSessionDelegate:self.sessionDelegate];
    }
}

-(void)setSessionDelegateRetryInterval:(NSNumber *)retryInterval {
    if(retryInterval.doubleValue < 0) {
        return;
    }
    self.authTokenRetryInterval = retryInterval.doubleValue;
    if(self.sessionDelegate != nil) {
        self.sessionDelegate.retryIntervalFromFlutter = retryInterval.doubleValue;
        [AACSession setSessionDelegate:self.sessionDelegate];
    }
}

-(void)setApiProtocol:(NSString *)protocolName {
    if([protocolName isEqualToString:@"http"]) {
        [AACSession setApiProtocol:AACApiProtocolHttp];
    } else if([protocolName isEqualToString:@"webSockets"]){
        [AACSession setApiProtocol:AACApiProtocolWebSockets];
    }
}

-(void)registerEmbeddedFonts:(NSArray*)fontList {
    NSDictionary *dicFontWeight = @{
        @"bold": @(AACFontWeightBold),
        @"regular": @(AACFontWeightRegular),
        @"weight100": @(AACFontWeight100),
        @"weight200": @(AACFontWeight200),
        @"weight300": @(AACFontWeight300),
        @"weight400": @(AACFontWeight400),
        @"weight500": @(AACFontWeight500),
        @"weight600": @(AACFontWeight600),
        @"weight700": @(AACFontWeight700),
        @"weight800": @(AACFontWeight800),
        @"weight900": @(AACFontWeight900),
        @"weight950": @(AACFontWeight950)
    };
    NSDictionary *dicFontStyle = @{
        @"italic": @(AACFontStyleItalic),
        @"normal": @(AACFontStyleNormal)
    };
    NSMutableArray<AACEmbeddedFont *> *embeddedFonts = [[NSMutableArray alloc] init];
    for(NSDictionary *fontRaw in fontList) {
        AACFontWeight weight = [dicFontWeight[fontRaw[@"weight"]] intValue];
        AACFontStyle style = [dicFontStyle[fontRaw[@"style"]] intValue];
        AACEmbeddedFont *font = [[AACEmbeddedFont alloc] initWithFamilyName:fontRaw[@"familyName"]
                                                             postscriptName:fontRaw[@"postscriptName"]
                                                                     weight:weight
                                                                      style:style];
        [embeddedFonts addObject:font];
    }
    [AACSession registerEmbeddedFonts:embeddedFonts];
}

-(void)userMetricsForStreamContainerWithIdentifier:(NSString*)containerId
                                            result:(FlutterResult)result {
    [AACSession userMetricsWithCompletionHandler:^(AACUserMetrics *response, NSError *error) {
        if(error == nil) {
            NSInteger totalCards = 0;
            NSInteger unseenCards = 0;
            
            if(containerId.length == 0) {
                totalCards = [response totalCards];
                unseenCards = [response unseenCards];
            } else {
                totalCards = [response totalCardsForStreamContainerWithId:containerId];
                unseenCards = [response unseenCardsForStreamContainerWithId:containerId];
            }
            
            result(@{
                @"totalCards": @(totalCards),
                @"unseenCards": @(unseenCards)
            });
        } else {
            [AACFlutterLogger log:@"Failed to request user metrics. %@", error];
            NSString *errorCode = [NSString stringWithFormat:@"%@ (error code %@)", error.domain, @(error.code)];
            FlutterError *flutterError = [FlutterError errorWithCode:errorCode message:error.localizedDescription details:nil];
            result(flutterError);
        }
    }];
}

-(void)requestCardCountForStreamContainerWithIdentifier:(NSString*)containerId
                                                 result:(FlutterResult)result {
    [AACSession requestCardCountForStreamContainerWithIdentifier:containerId handler:^(NSNumber *cardCount) {
        if(cardCount != nil) {
            result(@([cardCount intValue]));
        } else {
            NSString *errMsg = [NSString stringWithFormat:@"The card count is not available for this stream container (%@).", containerId];
            [AACFlutterLogger log:errMsg];
            FlutterError *flutterError = [FlutterError errorWithCode:@"AACSessionRequestCardCountForStreamContainerErrorDomain (error code 1)" message:errMsg details:nil];
            result(flutterError);
        }
    }];
}

-(void)sendEvent:(NSDictionary*)payload
          result:(FlutterResult)result {
    AACEventPayload *eventPayload = [[AACEventPayload alloc] initWithName:payload[@"name"]];
    eventPayload.lifecycleId = payload[@"lifecycleId"];
    id dicValue = payload[@"detail"];
    if([dicValue isKindOfClass:NSDictionary.class] == YES) {
        eventPayload.detail = (NSDictionary*)dicValue;
    }
    dicValue = payload[@"metadata"];
    if([dicValue isKindOfClass:NSDictionary.class] == YES) {
        eventPayload.metadata = (NSDictionary*)dicValue;
    }
    dicValue = payload[@"notificationDetail"];
    if([dicValue isKindOfClass:NSDictionary.class] == YES) {
        eventPayload.notificationDetail = (NSDictionary*)dicValue;
    }
    
    [AACSession sendEvent:eventPayload withCompletionHandler:^(AACEventResponse *response, NSError *error) {
        if(error == nil) {
            NSMutableArray *processedEvents = [[NSMutableArray alloc] init];
            for(AACProcessedEvent *event in response.processedEvents) {
                [processedEvents addObject:@{
                    @"name":event.name,
                    @"lifecycleId":event.lifecycleId,
                    @"version":@(event.version)
                }];
            }
            result(@{
                @"batchId": response.batchId,
                @"processedEvents": processedEvents
            });
        } else {
            [AACFlutterLogger error:@"Failed to send event payload. %@", error];
            NSString *errorCode = [NSString stringWithFormat:@"%@ (error code %@)", error.domain, @(error.code)];
            FlutterError *flutterError = [FlutterError errorWithCode:errorCode message:error.localizedDescription details:nil];
            result(flutterError);
        }
    }];
}

- (void)setApiBaseUrl:(NSString*)url {
    NSURL *parsedUrl = [NSURL URLWithString:url];
    
    if(parsedUrl) {
        [AACSession setApiBaseUrl:parsedUrl];
    } else {
        [AACFlutterLogger error:@"Failed to set API base URL: `%@` is not a valid URL.", url];
    }
}

- (void)initialiseWithEnvironmentId:(NSString*)envId apiKey:(NSString*)apiKey {
    [AACSession initialiseWithEnvironmentId:envId apiKey:apiKey];
}

- (void)enableDebugMode:(NSInteger)level {
    [AACSession enableDebugMode:level];
    [AACFlutterLogger setLoggingEnabled:level > 0];
}

- (FlutterError *)generateFlutterErrorWithError:(NSError *)error {
    NSString *errorCode = [NSString stringWithFormat:@"%@ (error code %@)", error.domain, @(error.code)];
    NSError *underlyingError = (NSError*)error.userInfo[NSUnderlyingErrorKey];
    NSString *underlyingErrorDescription;
    if(underlyingError != nil) {
        underlyingErrorDescription = [NSString stringWithFormat:@"Underlying error: %@", underlyingError.localizedDescription];
    }
    return [FlutterError errorWithCode:errorCode message:error.localizedDescription details:underlyingErrorDescription];
}

- (void)logout:(FlutterResult)result {
    // Stop all card count observers.
    for(id key in self.cardCountObservers) {
        [AACSession stopObservingCardCount:self.cardCountObservers[key]];
    }
    [self.cardCountObservers removeAllObjects];
    [AACSession logout:^(NSError * error) {
        self.sessionDelegate = nil;
        if(error != nil) {
            [AACFlutterLogger error:@"Errors when logging out. %@", error];
            result([self generateFlutterErrorWithError:error]);
        } else {
            result(@(YES));
        }
    }];
}

- (void)trackPushNotificationReceived:(NSDictionary*)payload
                               result:(FlutterResult)result {
    [AACSession trackPushNotificationReceived:payload completionHandler:^(NSError * _Nullable error) {
        if(error == nil) {
            result(@(YES));
        } else {
            [AACFlutterLogger log:@"Failed to track push notification receipt. The push notification payload may not be for an Atomic notification. %@", error];
            result([self generateFlutterErrorWithError:error]);
        }
    }];
}

- (void)registerStreamContainersForNotifications:(NSArray*)containerIds
                                          result:(FlutterResult)result {
    [AACSession registerStreamContainersForPushNotifications:containerIds completionHandler:^(NSError *error) {
        if(error == nil) {
            result(@(YES));
        } else {
            if(containerIds.count > 0) {
                [AACFlutterLogger error:@"Failed to register push notifications for stream containers %@ etc. %@", containerIds[0], error];
            } else {
                [AACFlutterLogger error:@"Failed to register push notifications for stream containers. %@", error];
            }
            result([self generateFlutterErrorWithError:error]);
        }
    }];
}

- (void)registerStreamContainersForNotifications:(NSArray*)containerIds
                                         enabled:(BOOL)notificationsEnabled
                                          result:(FlutterResult)result {
    
    [AACSession registerStreamContainersForPushNotifications:containerIds
                                        notificationsEnabled:notificationsEnabled
                                           completionHandler:^(NSError *error) {
        if(error == nil) {
            result(@(YES));
        } else {
            if(containerIds.count > 0) {
                [AACFlutterLogger error:@"Failed to register push notifications for stream containers %@ etc. %@", containerIds[0], error];
            } else {
                [AACFlutterLogger error:@"Failed to register push notifications for stream containers. %@", error];
            }
            result([self generateFlutterErrorWithError:error]);
        }
    }];
}

- (void)registerDeviceForNotifications:(NSString*)pushToken
                                result:(FlutterResult)result {
    NSData *tokenData = [pushToken aacFlutter_dataFromHexString];
    
    if(tokenData == nil) {
        [AACFlutterLogger error:@"Empty or invalid token provided when registering for push notifications."];
        return;
    }
    
    /// If the Flutter host app requests push notification, the Flutter plugin framework could
    /// call this method before any other initialisation codes being executed. This is not like
    /// in iOS app where registration for notification is manually triggered by calling
    /// [[UIApplication sharedApplication] registerForRemoteNotifications].
    /// Therefore we need a special treatment to handle exceptions from none-initialised session delegate.
    @try {
        [AACSession registerDeviceForNotifications:tokenData completionHandler:^(NSError *error) {
            if(error == nil) {
                result(@(YES));
            } else {
                result([self generateFlutterErrorWithError:error]);
            }
        }];
    } @catch (NSException *exception) {
        if([exception.name isEqualToString:@"NSInternalInconsistencyException"]) {
            [AACFlutterLogger warn:@"Failed to register push notifications for the device because it's called before initialisation."];
            FlutterError *flutterError = [FlutterError errorWithCode:@"Failed to register push notifications for the device."
                                                             message:@"Called before SDK initialisation."
                                                             details:nil];
            result(flutterError);
        } else {
            @throw exception;
        }
    }
}

- (void)deregisterDeviceForNotifications:(FlutterResult)result {
    [AACSession deregisterDeviceForNotificationsWithCompletionHandler:^(NSError *error) {
        if(error == nil) {
            result(@(YES));
        } else {
            [AACFlutterLogger error:@"Failed to deregister device for push notifications. %@", error];
            result([self generateFlutterErrorWithError:error]);
        }
    }];
}

- (void)notificationFromPushPayload:(NSDictionary*)payload result:(FlutterResult)result {
    AACPushNotification *notification = [AACSession notificationFromPushPayload:payload];
    
    if(notification != nil) {
        result(@{
            @"containerId": notification.containerId ?: @"",
            @"cardInstanceId": notification.cardInstanceId ?: @"",
            @"detail": notification.detail ?: @{}
        });
    } else {
        result(nil);
    }
}

- (void)stopObservingSDKEvents:(FlutterResult)result {
    [AACSession stopObservingSDKEvents];
    result(@(YES));
}

NSString *eventTypeString(AACSDKEventType eventType) {
    switch(eventType) {
        case AACSDKEventTypeUserRedirected:
            return @"UserRedirected";
        case AACSDKEventTypeRuntimeVarsUpdated:
            return @"RuntimeVarsUpdated";
        case AACSDKEventTypeCardVotedDown:
            return @"CardVotedDown";
        case AACSDKEventTypeRequestFailed:
            return @"RequestFailed";
        case AACSDKEventTypeVideoPlayed:
            return @"VideoPlayed";
        case AACSDKEventTypeVideoCompleted:
            return @"VideoCompleted";
        case AACSDKEventTypeCardSubviewExited:
            return @"CardSubviewExited";
        case AACSDKEventTypeCardSubviewDisplayed:
            return @"CardSubviewDisplayed";
        case AACSDKEventTypeCardCompleted:
            return @"Submitted";
        case AACSDKEventTypeCardDismissed:
            return @"Dismissed";
        case AACSDKEventTypeCardDisplayed:
            return @"CardDisplayed";
        case AACSDKEventTypeCardVotedUp:
            return @"CardVotedUp";
        case AACSDKEventTypeSnoozeOptionsDisplayed:
            return @"SnoozeOptionsDisplayed";
        case AACSDKEventTypeSnoozeOptionsCanceled:
            return @"SnoozeOptionsCanceled";
        case AACSDKEventTypeCardSnoozed:
            return @"Snoozed";
        case AACSDKEventTypeCardFeedUpdated:
            return @"CardFeedUpdated";
        case AACSDKEventTypeStreamDisplayed:
            return @"StreamDisplayed";
        case AACSDKEventTypeSdkInitialized:
            return @"SdkInitialized";
        case AACSDKEventTypeNotificationReceived:
            return @"NotificationsReceived";
        default:
            return @"UnknownEvent";
    }
}

NSString *cardViewStateString(AACSDKEventCardViewState cardViewState) {
    switch (cardViewState) {
        case AACSDKEventCardViewStateDefaultView:
            return @"topview";
        case AACSDKEventCardViewStateSubview:
            return @"subview";
        default:
            [AACFlutterLogger warn:@"Unknown AACSDKEventCardViewState"];
            return nil;
    }
}

NSString *downVoteReasonString(AACSDKEventVoteDownReason reason) {
    switch (reason) {
        case AACSDKEventVoteDownReasonTooOften:
            return @"too-often";
        case AACSDKEventVoteDownReasonOther:
            return @"other";
        case AACSDKEventVoteDownReasonNotRelevant:
            return @"not-relevant";
        default:
            [AACFlutterLogger warn:@"Unknown AACSDKEventVoteDownReason"];
            return nil;
    }
}

NSString *redirectMethodString(AACSDKEventRedirectLinkMethod redirectMethod) {
    switch (redirectMethod) {
        case AACSDKEventRedirectLinkMethodPayload:
            return @"payload";
            break;
        case AACSDKEventRedirectLinkMethodUrl:
            return @"url";
        default:
            [AACFlutterLogger warn:@"Unknown AACSDKEventRedirectLinkMethod"];
            return nil;
    }
}

NSString *streamModeString(AACSDKEventStreamMode streamMode) {
    switch (streamMode) {
        case AACSDKEventStreamModeVertical:
            return @"stream";
            break;
        case AACSDKEventStreamModeHorizontal:
            return @"horizon";
        case AACSDKEventStreamModeSingle:
            return @"single";
        default:
            [AACFlutterLogger warn:@"Unknown AACSDKEventStreamMode"];
            return nil;
    }
}
                
- (void)startObservingSDKEvents:(FlutterResult)result {
    [AACSession observeSDKEventsWithCompletionHandler:^(AACSDKEvent * _Nonnull sdkEvent) {
        NSString *userId = nil;
        NSNumber *cardCount = nil;
        NSMutableDictionary<NSString *, id> *propertiesJson = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSString *> *cardContextJson = [NSMutableDictionary dictionary];
        NSString *containerId = nil;
        NSMutableDictionary<NSString *, id> *streamContextJson = [NSMutableDictionary dictionary];
        if ([sdkEvent isKindOfClass:AACSDKEventRequestFailed.class]) {
            AACSDKEventRequestFailed *requestFailed = (AACSDKEventRequestFailed *)sdkEvent;
            propertiesJson[@"path"] = requestFailed.failedEndpoint;
            propertiesJson[@"statusCode"] = [NSNumber numberWithInteger:requestFailed.failedStatusCode];
            userId = requestFailed.endUserId;
            containerId = requestFailed.streamContainerId;
            cardContextJson[@"cardInstanceId"] = requestFailed.cardInstanceId;
        }
        else if ([sdkEvent isKindOfClass:AACSDKEventAuthEVT.class]) {
            AACSDKEventAuthEVT *authEVT = (AACSDKEventAuthEVT *)sdkEvent;
            userId = authEVT.endUserId;
            if ([sdkEvent isKindOfClass:AACSDKEventSTEVT.class]) {
                AACSDKEventSTEVT *sTEVT = (AACSDKEventSTEVT *)sdkEvent;
                containerId = sTEVT.streamContainerId;
                if ([sdkEvent isKindOfClass:AACSDKEventCardFeedUpdated.class]) {
                    AACSDKEventCardFeedUpdated *cardFeedUpdated = (AACSDKEventCardFeedUpdated *) sdkEvent;
                    cardCount = [NSNumber numberWithInteger:cardFeedUpdated.cardCount];
                }
                else if ([sdkEvent isKindOfClass:AACSDKEventStreamDisplayed.class]) {
                    AACSDKEventStreamDisplayed *streamDisplayed = (AACSDKEventStreamDisplayed *) sdkEvent;
                    streamContextJson[@"streamLength"] = [NSNumber numberWithInteger:streamDisplayed.streamLength];
                    streamContextJson[@"streamLengthVisible"] =[NSNumber numberWithInteger: streamDisplayed.streamLengthVisible];
                    streamContextJson[@"displayMode"] = streamModeString(streamDisplayed.streamMode);
                }
                else if ([sdkEvent isKindOfClass:AACSDKEventCREVT.class]) {
                    AACSDKEventCREVT *cREVT = (AACSDKEventCREVT *)sdkEvent;
                    cardContextJson[@"cardInstanceId"] = cREVT.cardInstanceId;
                    if ([sdkEvent isKindOfClass:AACSDKEventCardSnoozed.class]){
                        AACSDKEventCardSnoozed *cardSnoozed = (AACSDKEventCardSnoozed *)sdkEvent;
                        propertiesJson[@"unsnooze"] = cardSnoozed.unsnoozeDate.aacFlutter_ISONSStringFromNSDate;
                    }
                    else if ([sdkEvent isKindOfClass:AACSDKEventCardCompleted.class]) {
                        AACSDKEventCardCompleted *cardCompleted = (AACSDKEventCardCompleted *)sdkEvent;
                        propertiesJson[@"submittedValues"] = cardCompleted.submittedValues;
                    }
                    else if ([sdkEvent isKindOfClass:AACSDKEventCardVotedDown.class]) {
                        AACSDKEventCardVotedDown *cardVotedDown = (AACSDKEventCardVotedDown *)sdkEvent;
                        propertiesJson[@"message"] = cardVotedDown.otherMessage;
                        propertiesJson[@"reason"] = downVoteReasonString(cardVotedDown.reason);
                    }
                    else if ([sdkEvent isKindOfClass:AACSDKEventRuntimeVarsUpdated.class]) {
                        AACSDKEventRuntimeVarsUpdated *runtimeVarsUpdated = (AACSDKEventRuntimeVarsUpdated *)sdkEvent;
                        propertiesJson[@"resolvedVariables"] = runtimeVarsUpdated.resolvedVariables;
                    }
                    else if ([sdkEvent isKindOfClass:AACSDKEventUserRedirected.class]) {
                        AACSDKEventUserRedirected *userRedirected = (AACSDKEventUserRedirected *)sdkEvent;
                        propertiesJson[@"linkMethod"] = redirectMethodString(userRedirected.redirectMethod);
                        propertiesJson[@"redirectPayload"] = userRedirected.redirectPayload;
                        propertiesJson[@"url"] = userRedirected.redirectUrl.description;
                    }
                    else if ([sdkEvent isKindOfClass:AACSDKEventCardSubEVT.class]) {
                        AACSDKEventCardSubEVT *cardSubEVT = (AACSDKEventCardSubEVT *)sdkEvent;
                        propertiesJson[@"subviewId"] = cardSubEVT.subviewId;
                        propertiesJson[@"subviewLevel"] = [NSNumber numberWithInteger:cardSubEVT.subviewLevel];
                        propertiesJson[@"subviewTitle"] = cardSubEVT.subviewTitle;
                    }
                    else if ([sdkEvent isKindOfClass:AACSDKEventVideoEvent.class]) {
                        AACSDKEventVideoEvent *videoEvent = (AACSDKEventVideoEvent *)sdkEvent;
                        propertiesJson[@"url"] = videoEvent.videoUrl.description;
                    }
                }
            }
        }
        
        if ([sdkEvent conformsToProtocol:@protocol(AACSDKEventHasViewState)]) {
            id<AACSDKEventHasViewState> eventHavingViewState = (id<AACSDKEventHasViewState>)sdkEvent;
            propertiesJson[@"subviewId"] = eventHavingViewState.subviewId;
            propertiesJson[@"subviewLevel"] = [NSNumber numberWithInteger:eventHavingViewState.subviewLevel];
            propertiesJson[@"subviewTitle"] = eventHavingViewState.subviewTitle;
            cardContextJson[@"cardViewState"] = cardViewStateString(eventHavingViewState.cardViewState);
        }
        
        // NOTICE `source` currently has to be retrieved from rawContents because it isn't in iOS sdk at the moment: https://linear.app/atomic-app/issue/SDK-1804/[ios]-add-missing-property-source-for-vote-events
        NSDictionary<NSString *, id> *rawContents = sdkEvent.getRawContents;
        propertiesJson[@"source"] = rawContents[@"properties"][@"source"];
        
         // NOTICE Just like `source`, these three values can only be seen in getRawContents
        cardContextJson[@"cardPresentation"] = rawContents[@"cardContext"][@"cardPresentation"];
        cardContextJson[@"cardInstanceStatus"] = rawContents[@"cardContext"][@"cardInstanceStatus"];
        streamContextJson[@"cardPositionInStream"] = rawContents[@"streamContext"][@"cardPositionInStream"];

        NSDictionary<NSString *, id> *sdkEventJson = @{
            @"identifier": sdkEvent.eventId,
            @"eventName": eventTypeString(sdkEvent.eventType),
            @"timestamp": sdkEvent.timeStamp.aacFlutter_ISONSStringFromNSDate,
            @"userId": userId ?: [NSNull null],
            @"cardCount": cardCount ?: [NSNull null],
            @"cardContext": cardContextJson,
            @"properties": propertiesJson,
            @"containerId": containerId ?: [NSNull null],
            @"streamContext": streamContextJson
        };
        
        [self.channel invokeMethod:@"onSDKEvent" arguments:@{
            @"sdkEventJson": sdkEventJson
        }];
    }];
    result(@(YES));
}

- (void)observeCardCount:(NSString*)containerId
       atPollingInterval:(NSNumber*)interval
             filterJsonList:(NSArray<NSDictionary<NSString *, id> *>*)filterJsons
                  result:(FlutterResult)result {
    AACFlutterCardCountObserver *observer = [[AACFlutterCardCountObserver alloc] init];
    
    NSString *identifier = [NSString stringWithFormat:@"AACFlutterCardCountObserver-%@", @(kAACFlutterCardCountObserverId++)];
    observer.identifier = identifier;
    
    NSArray<AACCardFilter *> *filters = [AACFilterParser parseFiltersFromJson:filterJsons];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        id<NSObject> token = [AACSession observeCardCountForStreamContainerWithIdentifier:containerId
                                                                                 interval:interval.doubleValue
                                                                                  filters:filters
                                                                                  handler:^(NSNumber *cardCount) {
            if(cardCount != nil) {
                [self.channel invokeMethod:@"cardCountChanged" arguments:@{
                    @"streamContainerId": containerId,
                    @"identifier": identifier,
                    @"cardCount": cardCount
                }];
            }
        }];
        observer.token = token;
        
        self.cardCountObservers[identifier] = observer;
        result(identifier);
    });
}

- (void)stopObservingCardCount:(NSString*)identifier
                        result:(FlutterResult)result {
    AACFlutterCardCountObserver *observer = self.cardCountObservers[identifier];
    
    if(observer.token != nil) {
        [AACSession stopObservingCardCount:observer.token];
        self.cardCountObservers[identifier] = nil;
    }
    
    result(@(YES));
}

@end
