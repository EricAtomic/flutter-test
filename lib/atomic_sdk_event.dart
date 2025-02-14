import 'package:atomic_sdk_flutter/atomic_session.dart';
import 'package:flutter/foundation.dart';

/// Represents an SDK event. An SDK event symbolises an identifiable SDK activity such as card feed changes or user interactions with cards.
/// This acts as the base class for all SDK events.
/// For specific properties related to particular events, refer to the relevant instance variables of `AACSDKEvent`. E.g. [properties], [cardContext], [streamContext]
/// The instance variables that are not applicable for the [eventType] of the event are set to null.
/// An instance of this class can be found from [AACSession.setSDKEventObserver]'s callback.
class AACSDKEvent {
  AACSDKEvent({
    required this.identifier,
    required this.eventType,
    required this.timestamp,
    required this.userId,
    this.containerId,
    this.properties,
    this.cardCount,
    this.cardContext,
    this.streamContext,
  });

  /// A GUID generated by the SDK to represent this event.
  final String identifier;

  /// The type of this event.
  final AACSDKEventType eventType;

  /// The exact timestamp when this event was triggered.
  final DateTime timestamp;

  /// The user ID identified by the authentication token provided by the session delegate that is registered when initiating the SDK.
  /// `null` if the request is unauthenticated.
  final String? userId;

  /// The ID of the stream container that the event pertains to.
  /// `null` if the request isn't related to a stream container.
  final String? containerId;

  /// The [AACSDKEventProperties] of an [AACSDKEvent]. Depending on the [eventType], it can be set to `null`, as well as it's instance variables, if not applicable.
  final AACSDKEventProperties? properties;

  /// Represents the card count of the stream container where the update happens.
  /// - If this event occurs within a card count observer, it will be equal to the card count returned by that observer.
  /// - If this event occurs within an instantiated stream container, it will be equal to the number of visible cards in that container.
  final int? cardCount;

  /// The [AACSDKEventCardContext] of an [AACSDKEvent]. Depending on the [eventType], it can be set to `null`, as well as it's instance variables, if not applicable.
  final AACSDKEventCardContext? cardContext;

  /// The [AACSDKEventStreamContext] of an [AACSDKEvent]. Depending on the [eventType], it can be set to `null`, as well as it's instance variables, if not applicable.
  final AACSDKEventStreamContext? streamContext;

  /// This method isn't particularly intended for external access.
  /// returns `null `if:
  /// - The json can't be correctly parsed to an [AACSDKEvent].
  /// - The json is empty.
  /// - The required properties are `null`.
  static AACSDKEvent? tryParseFromJson(Map<String, dynamic> sdkEventJson) {
    // Use this print statement to check the json recieved from the native wrappers, compared to the sdk log in the shell app.
    //print("sdkeventsobserver tryParseFromJson sdkEventJson $sdkEventJson");

    if (_SDKEventUtils._isNullOrEmpty(sdkEventJson)) {
      return null;
    }

    final identifier = sdkEventJson["identifier"] as String?;
    if (identifier == null) {
      return null;
    }

    final eventNameString = sdkEventJson["eventName"] as String?;
    if (eventNameString == null) {
      return null;
    }
    final eventType = AACSDKEventType._parse(eventNameString);

    final timeStampString = sdkEventJson["timestamp"] as String?;
    if (timeStampString == null) {
      return null;
    }
    final timestamp = DateTime.tryParse(timeStampString);
    if (timestamp == null) {
      return null;
    }

    final sdkEventJsonTrimmed =
        _SDKEventUtils._setEmptyStringValuesToNull(sdkEventJson);

    return AACSDKEvent(
      identifier: identifier,
      eventType: eventType,
      timestamp: timestamp,
      userId: sdkEventJsonTrimmed["userId"] as String?,
      cardCount: sdkEventJsonTrimmed["cardCount"] as int?,
      cardContext: AACSDKEventCardContext._parseFromJson(
        (sdkEventJsonTrimmed["cardContext"] as Map?)?.cast<String, String?>(),
      ),
      properties: AACSDKEventProperties._parseFromJson(
        (sdkEventJsonTrimmed["properties"] as Map?)?.cast<String, dynamic>(),
      ),
      containerId: sdkEventJsonTrimmed["containerId"] as String?,
      streamContext: AACSDKEventStreamContext._parseFromJson(
        (sdkEventJsonTrimmed["streamContext"] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }
}

/// Represents the type of an [AACSDKEvent].
enum AACSDKEventType {
  /// The user opens a URL on a link button, opens a URL after submitting a card, or taps on a link or submit button with a custom action payload.
  /// This event can occur on either the top-level or subview of a card.
  UserRedirected,

  /// A card containing runtime variables has one or more runtime variables resolved.
  /// This event occurs on a per-card basis.
  RuntimeVarsUpdated,

  /// The user taps the "Submit" button on the card feedback screen, which is brought up by tapping on the "This isn't useful" option in the card overflow menu.
  CardVotedDown,

  /// An API request to our client API fails in the SDK. This event is also triggered when the WebSockets failed to function and fall back to HTTP polling.
  RequestFailed,

  /// The user hits the play button of a video.
  /// This event can occur on either the top-level or subview of a card.
  VideoPlayed,

  /// A video finishes playing.
  /// This event can occur on either the top-level or subview of a card.
  VideoCompleted,

  /// The user leaves the subview, either by navigating back or submitting the card.
  CardSubviewExited,

  /// The user opens a subview of a card.
  CardSubviewDisplayed,

  /// The user submits a card.
  Submitted,

  /// The user dismisses a card.
  Dismissed,

  /// An event in which a card is displayed in a container.
  /// This event monitors the following situations:
  /// - User scrolling (tracked once scrolling settles).
  /// - Initial load of the card list.
  /// - Arrival of new cards that is visible.
  CardDisplayed,

  /// The user taps on the "this is useful" option in the card overflow menu.
  CardVotedUp,

  /// The snooze date/time selection UI is displayed.
  SnoozeOptionsDisplayed,

  /// The user taps the "Cancel" button in the snooze UI.
  SnoozeOptionsCanceled,

  /// The user snoozes a card.
  Snoozed,

  /// A card feed has been updated. It occurs when a card(s) has been removed or added to the feed, or the card(s) in the feed has been updated.
  CardFeedUpdated,

  /// A stream container is first loaded or returned to.
  StreamDisplayed,

  /// An instance of the SDK is initialized, or the JWT is refreshed.
  SdkInitialized,

  /// A push notification on the user's device is received by the SDK.
  NotificationRecieved,

  /// An unknown event is observed.
  UnknownEvent;

  static AACSDKEventType _parse(String str) {
    return AACSDKEventType.values.firstWhere(
      (eT) => eT.name == str,
      orElse: () {
        if (kDebugMode) {
          print("sdkeventsobserver UnknownCardViewState: $str");
        }
        return AACSDKEventType.UnknownEvent;
      },
    );
  }
}

/// The states that the card to be in when the event happened.
enum AACSDKEventCardViewState {
  /// The user was on the cards topview (default) when the event happened.
  /// The topview view of a card is the card content a user sees in their stream container.
  TopView,

  /// The user was on a subview when the event happened.
  SubView,

  UnknownCardViewState;

  static AACSDKEventCardViewState _parse(String str) {
    if (str == "topview") {
      return AACSDKEventCardViewState.TopView;
    } else if (str == "subview") {
      return AACSDKEventCardViewState.SubView;
    }
    if (kDebugMode) {
      print("sdkeventsobserver UnknownCardViewState: $str");
    }
    return AACSDKEventCardViewState.UnknownCardViewState;
  }
}

/// Feedback reasons that the user can choose from.
/// Presented to the user after they taps on the "This is not useful" option in the card overflow menu.
enum AACSDKEventReason {
  /// The user feels that they see this card too often.
  TooOften,

  /// The user is providing free-form feedback.
  Other,

  /// The user feels that the card is not relevant to them.
  Relevant,

  UnknownReason;

  static AACSDKEventReason _parse(String str) {
    if (str == "too-often") {
      return AACSDKEventReason.TooOften;
    } else if (str == "other") {
      return AACSDKEventReason.Other;
    } else if (str == "not-relevant") {
      return AACSDKEventReason.Relevant;
    }
    if (kDebugMode) {
      print("sdkeventsobserver UnknownReason: $str");
    }
    return AACSDKEventReason.UnknownReason;
  }
}

/// The way that the user gets redirected.
enum AACSDKEventLinkMethod {
  /// The user is redirected by a custom action payload on a submit button.
  Payload,

  /// The user is redirected by a URL.
  Url,

  UnknownLinkMethod;

  static AACSDKEventLinkMethod _parse(String str) {
    if (str == "payload") {
      return AACSDKEventLinkMethod.Payload;
    } else if (str == "url") {
      return AACSDKEventLinkMethod.Url;
    }
    if (kDebugMode) {
      print("sdkeventsobserver UnknownLinkMethod: $str");
    }
    return AACSDKEventLinkMethod.UnknownLinkMethod;
  }
}

/// The mode of how a stream container displays cards.
enum AACSDKEventDisplayMode {
  /// The stream container displays the cards vertically.
  Vertical,

  /// The stream container displays the cards horizontally.
  Horizontal,

  /// The stream container displays a single card only.
  Single,

  UnknownDisplayMode;

  static AACSDKEventDisplayMode _parse(String str) {
    if (str == "stream") {
      return AACSDKEventDisplayMode.Vertical;
    } else if (str == "horizon") {
      return AACSDKEventDisplayMode.Horizontal;
    } else if (str == "single") {
      return AACSDKEventDisplayMode.Single;
    }
    if (kDebugMode) {
      print("sdkeventsobserver UnknownDisplayMode: $str");
    }
    return AACSDKEventDisplayMode.UnknownDisplayMode;
  }
}

/// Represents the card context of an [AACSDKEvent]. Some of it's instance variables can be set to `null` if not applicable for the [AACSDKEventType]
class AACSDKEventCardContext {
  AACSDKEventCardContext({
    this.cardInstanceId,
    this.cardPresentation,
    this.cardInstanceStatus,
    this.cardViewState,
  });

  /// The ID of the card that the event pertains to.
  /// `null` if the request isn't related to a specific card.
  final String? cardInstanceId;

  /// The presentation of the card at the time the event was generated.
  final String? cardPresentation;

  /// The status of the card at the time the event was generated.
  final String? cardInstanceStatus;

  /// The state that the card to be in when the event happened.
  final AACSDKEventCardViewState? cardViewState;

  static AACSDKEventCardContext? _parseFromJson(
    Map<String, String?>? cardContextJson,
  ) {
    if (_SDKEventUtils._isNullOrEmpty(cardContextJson)) {
      return null;
    }

    final cardContextJsonTrimmed =
        _SDKEventUtils._setEmptyStringValuesToNull(cardContextJson!)
            .cast<String, String?>();
    if (_SDKEventUtils._isEveryValueInsideNull(cardContextJsonTrimmed)) {
      return null;
    }

    final cardViewStateString = cardContextJsonTrimmed["cardViewState"];
    AACSDKEventCardViewState? cardViewState;
    if (cardViewStateString != null) {
      cardViewState = AACSDKEventCardViewState._parse(cardViewStateString);
    }

    return AACSDKEventCardContext(
      cardInstanceId: cardContextJsonTrimmed["cardInstanceId"],
      cardPresentation: cardContextJsonTrimmed["cardPresentation"],
      cardInstanceStatus: cardContextJsonTrimmed["cardInstanceStatus"],
      cardViewState: cardViewState,
    );
  }
}

/// Represents a stream context of an [AACSDKEvent]. Some of it's instance variables can be set to `null` if not applicable for the [AACSDKEventType]
class AACSDKEventStreamContext {
  AACSDKEventStreamContext({
    this.streamLength,
    this.cardPositionInStream,
    this.streamLengthVisible,
    this.displayMode,
  });

  /// The total number of cards available in the stream container.
  final int? streamLength;

  /// The position of the card this event pertains to, within the card list or single card view.
  final int? cardPositionInStream;

  /// The total number of cards rendered by the stream container; e.g. for single card view this is 1.
  final int? streamLengthVisible;

  /// The mode of how a stream container displays cards.
  final AACSDKEventDisplayMode? displayMode;

  static AACSDKEventStreamContext? _parseFromJson(
    Map<String, dynamic>? streamContextJson,
  ) {
    if (_SDKEventUtils._isNullOrEmpty(streamContextJson)) {
      return null;
    }

    final streamContextJsonTrimmed =
        _SDKEventUtils._setEmptyStringValuesToNull(streamContextJson!);
    if (_SDKEventUtils._isEveryValueInsideNull(streamContextJsonTrimmed)) {
      return null;
    }

    final displayModeString =
        streamContextJsonTrimmed["displayMode"] as String?;
    AACSDKEventDisplayMode? displayMode;
    if (displayModeString != null) {
      displayMode = AACSDKEventDisplayMode._parse(displayModeString);
    }

    return AACSDKEventStreamContext(
      streamLength: streamContextJsonTrimmed["streamLength"] as int?,
      cardPositionInStream:
          streamContextJsonTrimmed["cardPositionInStream"] as int?,
      streamLengthVisible:
          streamContextJsonTrimmed["streamLengthVisible"] as int?,
      displayMode: displayMode,
    );
  }
}

/// [AACSDKEventProperties] represents some properties of an [AACSDKEvent]. Some of it's instance variables can be set to `null` if not applicable for the [AACSDKEventType]
class AACSDKEventProperties {
  AACSDKEventProperties({
    this.subviewId,
    this.subviewTitle,
    this.subviewLevel,
    this.linkMethod,
    this.url,
    this.redirectPayload,
    this.submittedValues,
    this.resolvedVariables,
    this.reason,
    this.message,
    this.source,
    this.path,
    this.statusCode,
    this.unsnoozeDate,
  });

  /// The unique ID of a subview, which can be accessed on the subview page in the Workbench.
  /// Or `null` if the event does not occur in subviews.
  final String? subviewId;

  /// The title of a subview, which can be accessed on the subview page in the Workbench.
  /// Or `null` if the event does not occur in subviews.
  final String? subviewTitle;

  /// The level of a subview, currently only the value `1` is available.
  /// Or `0` if the view state is default.
  final int? subviewLevel;

  /// The way that the user gets redirected.
  final AACSDKEventLinkMethod? linkMethod;

  /// If a [AACSDKEventType.UserRedirected] event, represents:
  ///     The URL that the user was redirected to, if a URL redirection was used.
  ///     This will be `null` if the redirection did not involve a URL (for example, if it was a custom action payload).
  /// Or if a [AACSDKEventType.VideoPlayed] or [AACSDKEventType.VideoCompleted] event, The URL of this video.
  final String? url;

  /// If a [AACSDKEventType.UserRedirected] event, represents any custom action payload that was used to redirect the user.
  /// This will be `null` if the redirection did not involve a custom action payload (for example, if it was a URL redirection).
  final Map<String, dynamic>? redirectPayload;

  /// if a [AACSDKEventType.Submitted] event, represents all the input data.
  final Map<String, dynamic>? submittedValues;

  /// The values used for all runtime variables. If a variable is not resolved by the host app for a card, its default value is reported here.
  final Map<String, String>? resolvedVariables;

  /// The feedback reason for the user down voting a card. Presented to the user after they taps on the "This is not useful" option in the card overflow menu.
  final AACSDKEventReason? reason;

  /// The free-form feedback other message provided by the user. Or `null` if `reason` is not "other".
  final String? message;

  /// Dismiss invoked, Snooze invoked, Submit invoked
  final String? source;

  /// The endpoint path at which the request failure occurred.
  final String? path;

  /// The status code returned by the failed endpoint. `0` when this event represents a fallback to HTTP.
  final int? statusCode;

  /// The date and time at which the card is unsnoozed.
  final DateTime? unsnoozeDate;

  static AACSDKEventProperties? _parseFromJson(
    Map<String, dynamic>? propertiesJson,
  ) {
    if (_SDKEventUtils._isNullOrEmpty(propertiesJson)) {
      return null;
    }

    final propertiesJsonTrimmed =
        _SDKEventUtils._setEmptyStringValuesToNull(propertiesJson!);
    if (_SDKEventUtils._isEveryValueInsideNull(propertiesJsonTrimmed)) {
      return null;
    }

    DateTime? unsnoozed;
    final unsnoozedRaw = propertiesJsonTrimmed["unsnooze"] as String?;
    if (unsnoozedRaw != null) {
      unsnoozed = DateTime.tryParse(unsnoozedRaw);
    }

    final linkMethodString = propertiesJsonTrimmed["linkMethod"] as String?;
    AACSDKEventLinkMethod? linkMethod;
    if (linkMethodString != null) {
      linkMethod = AACSDKEventLinkMethod._parse(linkMethodString);
    }

    final reasonString = propertiesJsonTrimmed["reason"] as String?;
    AACSDKEventReason? reason;
    if (reasonString != null) {
      reason = AACSDKEventReason._parse(reasonString);
    }

    return AACSDKEventProperties(
      message: propertiesJsonTrimmed["message"] as String?,
      linkMethod: linkMethod,
      path: propertiesJsonTrimmed["path"] as String?,
      reason: reason,
      source: propertiesJsonTrimmed["source"] as String?,
      subviewId: propertiesJsonTrimmed["subviewId"] as String?,
      subviewTitle: propertiesJsonTrimmed["subviewTitle"] as String?,
      url: propertiesJsonTrimmed["url"] as String?,
      statusCode: propertiesJsonTrimmed["statusCode"] as int?,
      subviewLevel: propertiesJsonTrimmed["subviewLevel"] as int?,
      resolvedVariables: (propertiesJsonTrimmed["resolvedVariables"] as Map?)
          ?.cast<String, String>(),
      redirectPayload: (propertiesJsonTrimmed["redirectPayload"] as Map?)
          ?.cast<String, dynamic>(),
      submittedValues: (propertiesJsonTrimmed["submittedValues"] as Map?)
          ?.cast<String, dynamic>(),
      unsnoozeDate: unsnoozed,
    );
  }
}

class _SDKEventUtils {
  /// Only for values of type `String?` (can be null), not `String`.
  static Map<String, dynamic> _setEmptyStringValuesToNull(
    Map<String, dynamic> json,
  ) {
    return json.map((key, value) {
      if (value is String? && value != null && value.isEmpty) {
        // If the value is an optional String, and it's empty, set it to null.
        value = null;
      }
      return MapEntry(key, value);
    });
  }

  static bool _isNullOrEmpty(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return true;
    }
    return false;
  }

  static bool _isEveryValueInsideNull(Map<String, dynamic> json) {
    final isEveryValueInJsonNull = json.values.firstWhere(
          (element) => element != null,
          orElse: () => null,
        ) ==
        null;

    return isEveryValueInJsonNull;
  }
}
