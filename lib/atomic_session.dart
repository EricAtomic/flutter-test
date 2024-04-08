import 'dart:async';
import 'dart:developer';

import 'package:atomic_sdk_flutter/atomic_card_filter.dart';
import 'package:atomic_sdk_flutter/atomic_data_interface.dart';
import 'package:atomic_sdk_flutter/atomic_embedded_font.dart';
import 'package:atomic_sdk_flutter/atomic_event_payload.dart';
import 'package:atomic_sdk_flutter/atomic_sdk_event.dart';
import 'package:atomic_sdk_flutter/atomic_stream_container.dart';
import 'package:atomic_sdk_flutter/src/atomic_literals.dart';
import 'package:atomic_sdk_flutter/src/atomic_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A time frame in which notifications can be pushed to the user. The frame includes two timestamps: the start and end of the time frame.
/// These times are in the format of 24 hour, the end time must be later than the start time.
class AACUserNotificationTimeframe {
  AACUserNotificationTimeframe({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  Map<String, dynamic> toJsonValue() {
    return {
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }
}

enum AACUserNotificationTimeframeWeekdays {
  anyDay,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

extension StringValue on AACUserNotificationTimeframeWeekdays {
  String get stringValue => toString().split('.').last;
}

/// Represents a user setting object, exclusively for the user identified by the authentication token provided by the
/// session delegate that is registered when initiating the SDK. A user setting object is equivalent to those settings
/// in the `Customers` page on the Workbench.
///
/// All properties in `AACUserSettings` are optional.
class AACUserSettings {
  /// An external ID of the user.
  String? externalID;

  /// The name of the user.
  String? name;

  /// The email address of the user.
  String? email;

  /// The phone number of the user.
  String? phone;

  /// The city of the user.
  String? city;

  /// The country of the user.
  String? country;

  /// The region of the user.
  String? region;

  /// Whether push notifications are enabled for this user. Default to true.
  bool notificationsEnabled = true;

  final Map<String, dynamic> _timeframesMap = {};
  final Map<String, String> _customTextFields = {};
  final Map<String, String> _customDateFields = {};

  /// Set up a notification timeframe or timeframes for the user.
  ///
  /// [timeframes] is the array of notification time frames.
  ///
  /// [weekday] is the day of the week when the time frame array apply to.
  void setNotificationTime(
    List<AACUserNotificationTimeframe> timeframes,
    AACUserNotificationTimeframeWeekdays weekday,
  ) {
    _timeframesMap[weekday.stringValue] =
        timeframes.map((e) => e.toJsonValue()).toList();
  }

  /// Assigns the given text to a custom field defined by the given name, which is defined as type 'text' on Atomic Workbench.
  void setTextForCustomField(String text, String customField) {
    _customTextFields[customField] = text;
  }

  /// Assigns the given date to a custom field defined by the given name, which is defined as type 'date' on Atomic Workbench.
  /// Note: custom fields defined as 'date' must be updated by this method.
  void setDateForCustomField(DateTime dateTime, String customField) {
    _customDateFields[customField] = AACUtils.toLocalIsoStr(dateTime);
  }

  Map<String, dynamic> toJsonValue() {
    final mapData = <String, dynamic>{};
    if (externalID != null) {
      mapData['externalID'] = externalID;
    }
    if (name != null) {
      mapData['name'] = name;
    }
    if (email != null) {
      mapData['email'] = email;
    }
    if (phone != null) {
      mapData['phone'] = phone;
    }
    if (city != null) {
      mapData['city'] = city;
    }
    if (country != null) {
      mapData['country'] = country;
    }
    if (region != null) {
      mapData['region'] = region;
    }
    mapData['notificationsEnabled'] = notificationsEnabled;
    mapData['textCustomFields'] = _customTextFields;
    mapData['dateCustomFields'] = _customDateFields;
    mapData['notificationTimeframes'] = _timeframesMap;
    return mapData;
  }
}

/// Returns card-related metrics for the current user.
class AACUserMetrics {
  AACUserMetrics.fromJson(Map<String, dynamic> json)
      : totalCards = json['totalCards'] as int,
        unseenCards = json['unseenCards'] as int;

  /// The total number of cards available.
  final int totalCards;

  /// The total number of cards unseen for the user.
  final int unseenCards;
}

/// Represents a push notification successfully parsed by the Atomic SDK.
class AACPushNotification {
  AACPushNotification.fromJson(Map<String, dynamic> json)
      : containerId = json["containerId"] as String,
        cardInstanceId = json["cardInstanceId"] as String,
        detail = (json["detail"] as Map).cast<String, dynamic>();
  final String containerId;
  final String cardInstanceId;
  final Map<String, dynamic> detail;
}

/// Supported network protocol types in the SDK.
enum AACApiProtocol {
  /// Represents the WebSockets protocol
  webSockets("webSockets"),

  /// Represents the HTTP protocol
  http("http");

  const AACApiProtocol(this.stringValue);
  final String stringValue;
}

/// Static methods used to initialise and configure global SDK properties.
class AACSession {
  static final MethodChannel _sessionChannel = const MethodChannel(
    'io.atomic.sdk.session',
  )..setMethodCallHandler((call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>();
      switch (call.method) {
        case 'onSDKEvent':
          if (_sdkEventObserver == null || args == null) {
            break;
          }
          final sdkEventJsonArg = args['sdkEventJson'] as Map?;
          if (sdkEventJsonArg == null) {
            _reportError(
              context: acc_error_observe_sdk_event,
              exception:
                  "Method ${call.method} does not contain an `sdkEventJson` argument",
            );
            break;
          }
          AACSDKEvent? sdkEvent;
          try {
            sdkEvent = AACSDKEvent.tryParseFromJson(
              sdkEventJsonArg.cast<String, dynamic>(),
            );
          } catch (error) {
            _reportError(
              context: acc_error_observe_sdk_event,
              exception:
                  "Method ${call.method} couldn't parse the sdkEventJsonArg to an AACSDKEvent object. sdkEventJsonArg: $sdkEventJsonArg. Error: $error.",
            );
            break;
          }
          if (sdkEvent == null) {
            _reportError(
              context: acc_error_observe_sdk_event,
              exception:
                  "Method ${call.method}'s `sdkEventJson` argument can't be parsed into an AACSDKEvent object.",
            );
            break;
          }
          _sdkEventObserver?.call(sdkEvent);
        case 'cardCountChanged':
          if (args == null) {
            break;
          }
          final identifier = args['identifier'] as String?;
          if (identifier == null) {
            _reportError(
              context: acc_error_observe_card_count_changed,
              exception:
                  "Method ${call.method} does not contain an `identifier` argument",
            );
            break;
          }
          _cardCountObservers[identifier]?.call(args['cardCount'] as int);
        case 'onStreamContainerObserved':
          if (args == null) {
            break;
          }
          final token = args['identifier'] as String?;
          if (token == null || token.isEmpty) {
            _reportError(
              context: "while observing a stream container",
              exception:
                  "Method ${call.method} does not contain a `token` argument: $token",
            );
            break;
          }
          final cardsJsonList =
              (args['cards'] as List?)?.cast<Map<dynamic, dynamic>>();
          final List<AACCard>? cards;
          if (cardsJsonList == null) {
            cards = null;
          } else {
            cards = [];
            if (kDebugMode) {
              log("observeStreamContainer-flutter cardsJsonList: $cardsJsonList");
            }

            try {
              for (final cardJson in cardsJsonList) {
                final card = AACCard.fromJson(cardJson.cast<String, dynamic>());
                cards.add(card);
              }
            } catch (e, st) {
              _reportError(
                context: "while observing a stream container",
                exception: "Error: $e. Stacktrace: $st",
              );
            }
          }

          _streamContainerObservers[token]?.call(cards);
        case 'authTokenRequested':
          if (args == null) {
            break;
          }
          final identifier = args['identifier'] as String?;
          if (identifier == null) {
            _reportError(
              exception:
                  "Method ${call.method} does not contain an `identifier` argument",
              context: aac_error_auth_token_context,
            );
          }
          if (_sessionDelegate == null) {
            _reportError(
              exception:
                  'An authentication token was requested by the Atomic SDK but no session delegate has been configured. Ensure you have called `AACSession.setSessionDelegate`, providing a delegate that extends AACSessionDelegate and resolves to a JWT.',
              context: aac_error_auth_token_context,
            );
          }
          try {
            final token = await _sessionDelegate?.authToken();
            if (token != null) {
              unawaited(
                _sessionChannel
                    .invokeMethod('onAuthTokenReceived', [token, identifier]),
              );
            } else {
              unawaited(
                _sessionChannel
                    .invokeMethod('onAuthTokenReceived', ["", identifier]),
              );
              _reportError(
                exception:
                    "Failed to get authentication token. Null token returned.",
                context: aac_error_auth_token_context,
              );
            }
          } catch (error) {
            unawaited(
              _sessionChannel
                  .invokeMethod('onAuthTokenReceived', ["", identifier]),
            );
            _reportError(
              exception: error,
              context: aac_error_auth_token_context,
            );
          }
        default:
          throw MissingPluginException("No handler for method ${call.method}");
      }
    });
  static final Map<String, void Function(int)> _cardCountObservers = {};
  static final Map<String, void Function(List<AACCard>? cards)>
      _streamContainerObservers = {};

  static void Function(AACSDKEvent)? _sdkEventObserver;
  static AACSessionDelegate? _sessionDelegate;

  static void _reportError({
    required Object exception,
    required String context,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: exception,
        library: aac_framework_name,
        context: ErrorSummary(context),
      ),
    );
  }

  /// Sets the time interval used to determine whether Atomic SDK should retry to fetch a token from the session delegate.
  /// The SDK won't fetch the JWT in a frequency higher than `1/[retryInterval]`. The interval must not be smaller than zero.
  /// If this method is not called, the default retry interval is 0 seconds, which means the SDK will retry immediately
  /// after failing to get a valid token.
  static Future<void> setTokenRetryInterval(double retryInterval) async {
    await _sessionChannel
        .invokeMethod('setSessionDelegateRetryInterval', [retryInterval]);
  }

  /// Sets the time interval used to determine whether the authentication token has expired. If the interval between the
  /// current time and the token's `exp` field is smaller than [expiryInterval], the token is considered to be expired.
  /// The interval must not be smaller than zero.
  /// If this method is not called, the default expiry interval is 60 seconds.
  static Future<void> setTokenExpiryInterval(double expiryInterval) async {
    await _sessionChannel
        .invokeMethod('setSessionDelegateExpiryInterval', [expiryInterval]);
  }

  /// Configures the Atomic SDK to use the provided base URL when making API requests.
  /// The base URL can be found in the Atomic Workbench.
  static Future<void> setApiBaseUrl(String url) async {
    await _sessionChannel.invokeMethod('setApiBaseUrl', [url]);
  }

  /// Set up a [sessionDelegate] used by the SDK to acquire an authentication token.
  /// The token is requested once by the SDK, and provided that the token is valid and contains a user ID, the
  /// token is retained in memory by the SDK until it is due to expire - at which point, a new token is requested.
  static Future<void> setSessionDelegate(
    AACSessionDelegate sessionDelegate,
  ) async {
    _sessionDelegate = sessionDelegate;
    await _sessionChannel.invokeMethod('setSessionDelegate', <dynamic>[]);
  }

  /// Initialises the Atomic SDK with the provided environment ID and API key.
  /// You must call this before attempting to use any Atomic SDK functionality.
  static Future<void> initialise(String environmentId, String apiKey) async {
    await _sessionChannel.invokeMethod('initialise', [environmentId, apiKey]);
  }

  /// Sets the debug logging level within the SDK. This can be useful in debug
  /// builds when integrating the SDK. Defaults to `0`, which means no logs. Setting this takes immediate effect.
  /// - [level] The logging message level that controls the details of logging information.
  /// Must be one of the following values: 0, 1, 2, 3.
  static Future<void> enableDebugMode(int level) async {
    await _sessionChannel.invokeMethod('enableDebugMode', [level]);
  }

  /// Purges all cached card data stored by the SDK. Call this method when a user logs out of your app
  /// or the active user changes.
  /// If the registration does not succeed, this method has no effect and throws out an error.
  static Future<void> logout() async {
    try {
      await _sessionChannel.invokeMethod('logout', <dynamic>[]);
      unawaited(setSDKEventObserver(null));
    } catch (exception) {
      _reportError(exception: exception, context: aac_error_logout_context);
      rethrow;
    }
  }

  /// Sets up the network protocol used by the SDK to acquire cards. Calling it takes immediate effect.
  static Future<void> setApiProtocol(AACApiProtocol protocol) async {
    await _sessionChannel
        .invokeMethod('setApiProtocol', [protocol.stringValue]);
  }

  /// Asks the SDK to register the currently logged in user for push notifications on the stream container IDs in the provided
  /// array with notifications enabled or disabled.
  /// Push notifications will not be delivered to a user unless they have registered for push notifications first.
  /// However, the registration of device token and registration of stream container IDs can occur in either order.
  ///
  /// If the registration does not success, this method has no effect and throws out an error.
  ///
  /// The [notificationsEnabled] parameter is optional and will set the user's preference in the Atomic Platform to true or false accordingly.
  static Future<void> registerStreamContainersForNotifications(
    List<String> containerIds, {
    bool? notificationsEnabled,
  }) async {
    try {
      if (notificationsEnabled == null) {
        await _sessionChannel.invokeMethod(
          'registerStreamContainersForNotifications',
          [containerIds],
        );
      } else {
        await _sessionChannel.invokeMethod(
          'registerStreamContainersForNotificationsEnabled',
          [containerIds, notificationsEnabled],
        );
      }
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_register_stream_container_push_notifications_context,
      );
      rethrow;
    }
  }

  /// Asks the SDK to register the given device token against the currently logged in user identified by the authentication token returned by the
  /// session delegate that is registered when initiating the SDK.
  /// If the registration does not succeed, this method has no effect and throws out an error.
  static Future<void> registerDeviceForNotifications(String pushToken) async {
    try {
      await _sessionChannel
          .invokeMethod('registerDeviceForNotifications', [pushToken]);
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_register_device_push_notifications_context,
      );
      rethrow;
    }
  }

  /// Asks the SDK to deregister the current device for Atomic push notifications, within the current app.
  /// If the deregistration fails, it throws out an error.
  static Future<void> deregisterDeviceForNotifications() async {
    try {
      await _sessionChannel
          .invokeMethod('deregisterDeviceForNotifications', <dynamic>[]);
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_deregister_device_push_notifications_context,
      );
      rethrow;
    }
  }

  /// This helper method checks if the value of a key is another Map<Object?, Object?>. If so, it calls the castMap() function
  /// recursively to cast the nested map to Map<String, dynamic> as well.
  /// This will ensure that all nested maps are properly cast to the desired type.
  static Map<String, dynamic> _castMap(Map<Object?, Object?> originalMap) {
    return originalMap.map<String, dynamic>((key, value) {
      if (value is Map<Object?, Object?>) {
        return MapEntry<String, dynamic>(key! as String, _castMap(value));
      }
      return MapEntry<String, dynamic>(key! as String, value);
    });
  }

  /// Determines whether the given push notification payload is for a push notification sent by the Atomic Platform.
  /// If the push payload is for an Atomic push notification, this method returns an instance of [AACPushNotification] populated with
  /// details of the notification. Otherwise, it returns null.
  static Future<AACPushNotification?> notificationFromPushPayload(
    Map<String, dynamic> payload,
  ) async {
    final rawData = await _sessionChannel.invokeMethod<Map<dynamic, dynamic>>(
      'notificationFromPushPayload',
      [payload],
    );
    if (rawData == null) {
      return null;
    }
    final castedData = _castMap(rawData);
    if (castedData.isNotEmpty) {
      return AACPushNotification.fromJson(castedData);
    } else {
      return null;
    }
  }

  /// Sets the `Function(AACSDKEvent)? sdkEventObserver` callback to listen to all important SDK events.
  /// The [AACSDKEvent] paramter in the callback holds all the relevant sdk event information.
  /// To remove the observer, simply set it to `null`.
  static Future<void> setSDKEventObserver(
    void Function(AACSDKEvent)? sdkEventObserver,
  ) async {
    if (sdkEventObserver == null) {
      await _sessionChannel.invokeMethod('stopObservingSDKEvents', <dynamic>[]);
    } else {
      await _sessionChannel
          .invokeMethod('startObservingSDKEvents', <dynamic>[]);
    }
    _sdkEventObserver = sdkEventObserver;
  }

  /// Asks the SDK to observe the card count for the given stream container on the frequency of the [pollingInterval], calling the [callback] every time
  /// calling the [callback] every time the count changes.
  /// The [pollingInterval] must be at least 1 second, otherwise it defaults to 1 second.
  /// You can provide a list of [AACCardFilter]s to the observer, optionally.
  /// The SDK returns a [String] observer token to distinguish card count observers.
  static Future<String> observeCardCount({
    required String containerId,
    required void Function(int cardCount) callback,
    Duration pollingInterval = const Duration(seconds: 1),
    List<AACCardFilter>? filters,
  }) async {
    var filtersJsonList = <Map<String, dynamic>>[];
    if (filters != null) {
      filters.removeWhere((f) => f.toJson["byCardInstanceId"] != null);
      filtersJsonList = AACCardFilter.toJsonList(filters);
    }
    final observerToken = await _sessionChannel.invokeMethod<String>(
      'observeCardCount',
      [
        containerId,
        pollingInterval.inMilliseconds,
        filtersJsonList,
      ],
    );
    if (observerToken == null) {
      throw Exception(
        "observerToken, from session channel call 'observeCardCount', is null",
      );
    }
    _cardCountObservers[observerToken] = callback;
    return observerToken;
  }

  /// Asks the SDK to stop observing card count for the given token, which was returned from a call to
  /// [observeCardCount]. If the token does not correspond to an existing card count observer, this method does nothing.
  static Future<void> stopObservingCardCount(String observerToken) async {
    await _sessionChannel
        .invokeMethod('stopObservingCardCount', [observerToken]);
    _cardCountObservers.remove(observerToken);
  }

  /// Tracks that a push notification, with the given payload, was received by this device.
  ///
  /// If the payload does not represent an Atomic push notification, this method has no effect and throws out an error.
  /// This method dispatches an analytics event back to Atomic to indicate that the user's device received the notification.
  /// It is the responsibility of the integrator to ensure that this method is called at the correct location to ensure accurate tracking.
  static Future<void> trackPushNotificationReceived(
    Map<String, dynamic> payload,
  ) async {
    try {
      await _sessionChannel
          .invokeMethod('trackPushNotificationReceived', [payload]);
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_track_pushNotification_received_context,
      );
      rethrow;
    }
  }

  /// Triggers an event on the Atomic Platform, exclusively for the user identified by by the authentication token returned by the
  /// session delegate that is registered when initiating the SDK.
  ///
  /// Events must opt-in to be triggered from the SDK. To opt-in, turn on the 'Enable client trigger' option in the Atomic Workbench
  /// for the event.
  ///
  /// - [payload] represents the event payload used to trigger the event.
  ///
  /// If the request succeeds, details of the processed event are provided with an [AACEventResponse] object, otherwise an error is thrown out.
  @Deprecated(
    'The feature `send event` is deprecated and no longer used by Atomic Workbench.',
  )
  static Future<AACEventResponse> sendEvent(AACEventPayload payload) async {
    var result = (await _sessionChannel
        .invokeMethod('sendEvent', [payload.toJson()])) as Map?;
    result ??= {};
    return AACEventResponse.fromJson(result.cast<String, dynamic>());
  }

  /// Asks the SDK to return the number of cards for the given stream container.
  ///
  /// - [containerId] represents the stream container ID to retrieve the card count for.
  ///
  /// The function throws if the card count is not available for this stream container (the user may not have access or the internet connection
  /// may be unavailable).
  static Future<int> requestCardCount(String containerId) async {
    var count = await _sessionChannel
        .invokeMethod<int>('requestCardCount', [containerId]);
    return count ??= 0;
  }

  /// Retrieves user metrics for the user identified by by the authentication token returned by the
  /// session delegate that is registered when initiating the SDK.
  /// User metrics provide a count of the total number of cards visible to a user,as well as the total number not yet seen by the user.
  ///
  /// Pass a [streamContainerId] to get user metrics for a specific stream container, or an empty string
  /// to retrieve metrics across all containers.
  ///
  /// Use the returned [AACUserMetrics] object to obtain these values.

  static Future<AACUserMetrics> userMetrics(String streamContainerId) async {
    try {
      var result = (await _sessionChannel
          .invokeMethod('userMetrics', [streamContainerId])) as Map?;
      result ??= {};
      return AACUserMetrics.fromJson(result.cast<String, dynamic>());
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_user_metrics_context,
      );
      rethrow;
    }
  }

  /// Registers the specified local fonts with the SDK. The fonts are defined in the theme created in the Atomic Workbench
  /// and integrated locally with the app. Pass an empty [fontList] to clear the embedded fonts being used.
  static Future<void> registerEmbeddedFonts(
    List<AACEmbeddedFont> fontList,
  ) async {
    final fontListJson = <Map<String, dynamic>>[];
    for (final font in fontList) {
      fontListJson.add(font.toJson());
    }
    await _sessionChannel.invokeMethod('registerEmbeddedFonts', [fontListJson]);
  }

  /// Send out a custom event to the Atomic Platform, exclusively for the user identified by the authentication token provided by the
  /// session delegate that is registered when initiating the SDK. The [eventProperties] is optional,
  /// which is a dictionary of key-value pairs to provide to the event.
  ///
  /// Custom events are handled in the Atomic Platform.
  static Future<void> sendCustomEvent(
    String eventName, {
    Map<String, String>? eventProperties,
  }) async {
    try {
      await _sessionChannel
          .invokeMethod("sendCustomEvent", [eventName, eventProperties]);
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_custom_event_context,
      );
      rethrow;
    }
  }

  /// Update the user profile and preferences on the Atomic Platform, exclusively for the user identified by the authentication token provided by the
  /// session delegate that is registered when initiating the SDK.
  static Future<void> updateUser(AACUserSettings userSettings) async {
    try {
      await _sessionChannel
          .invokeMethod('updateUser', [userSettings.toJsonValue()]);
    } catch (exception) {
      _reportError(
        exception: exception,
        context: aac_error_update_user_context,
      );
      rethrow;
    }
  }

  /// Set the current version of your app. An app version is used with analytics to make it easy to track issues between app versions
  /// and general analytics around versions.
  ///
  /// If you do not call this method, the client app version defaults to `unknown`.
  ///
  /// Strings longer than 128 characters will be trimmed to that length.
  static Future<void> setClientAppVersion(String clientAppVersion) async {
    var clientAppVersionTrimmed = clientAppVersion;
    if (clientAppVersion.length > 128) {
      clientAppVersionTrimmed = clientAppVersionTrimmed.substring(0, 128);
    }
    await _sessionChannel
        .invokeMethod('setClientAppVersion', [clientAppVersionTrimmed]);
  }

  /// Login to the Atomic SDK with credentials. It's the equivalent of calling [initialise], [setSessionDelegate]
  /// and [setApiBaseUrl] in sequence.
  static Future<void> login(
    String environmentId,
    String apiKey,
    AACSessionDelegate sessionDelegate,
    String apiBaseUrl,
  ) async {
    await initialise(environmentId, apiKey);
    await setSessionDelegate(sessionDelegate);
    await setApiBaseUrl(apiBaseUrl);
  }

  /// Asks the SDK to monitor changes in a stream container, invoking the specified [callback] whenever there are updates.
  /// This method can be used to track changes of the card feed within the stream container.
  /// @param [containerId] The identifier of the stream container to be observed.
  /// @param [config] A configuration object for defining behaviour of the stream container observer.
  /// @param [callback] The callback handler that is invoked whenever there is a change in the stream container.
  /// The handler receives updated information, or `null` if the data is not accessible (due to reasons like lack of user access or network issues).
  /// @return A `String` token which can be used to cease monitoring changes by passing it to the [stopObservingStreamContainer] method.
  static Future<String> observeStreamContainer({
    required String containerId,
    required void Function(List<AACCard>? cards) callback,
    AACStreamContainerObserverConfiguration? config,
  }) async {
    config ??= AACStreamContainerObserverConfiguration();
    final observerToken = await _sessionChannel.invokeMethod<String>(
      "observeStreamContainer",
      [containerId, config.toJson()],
    );
    if (observerToken == null) {
      throw Exception(
        "observerToken, from session channel call 'observeStreamContainer', is null",
      );
    }
    _streamContainerObservers[observerToken] = callback;
    return observerToken;
  }

  /// Requests the SDK to cease monitoring changes in the stream container associated with the given token.
  /// This method stops the updates that were being sent to the handler registered via [observeStreamContainer].
  /// If the provided token does not correspond to an active stream container observer, this method has no effect.
  /// @param [observerToken] The `String` token obtained from [observeStreamContainer]. This token identifies the specific monitoring process to be stopped.
  static Future<void> stopObservingStreamContainer(String observerToken) async {
    await _sessionChannel.invokeMethod(
      'stopObservingStreamContainer',
      [observerToken],
    );
    _streamContainerObservers.remove(observerToken);
  }

  /// Internal method for creating a custom card action.
  /// Executes the specified card action and calls the completion handler upon completion.
  /// Card actions include dismissing, snoozing or submitting a card.
  /// @param [containerId] The ID of the stream container that the card is contained within.
  /// @param [cardId] The instance ID of the card that triggered the action.
  /// @param [action] The object representing a card action.
  /// @param [callback] The callback after the action is completed.
  static Future<void> executeCardAction(
    String containerId,
    String cardId,
    AACCardAction action,
    void Function(AACCardActionResult result) callback,
  ) async {
    try {
      final resultString = await _sessionChannel.invokeMethod<String>(
        'executeCardAction',
        [containerId, cardId, action.type.name, action.arg],
      );
      if (resultString == null) {
        throw Exception("The result is null.");
      }
      callback(AACCardActionResult.fromString(resultString));
    } catch (exception) {
      _reportError(
        exception: exception,
        context: "while executing a card action (${action.type})",
      );
    }
  }
}
