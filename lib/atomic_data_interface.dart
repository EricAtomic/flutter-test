import 'dart:io';

import 'package:atomic_sdk_flutter/atomic_card_filter.dart';
import 'package:atomic_sdk_flutter/atomic_card_runtime_variable.dart';
import 'package:atomic_sdk_flutter/atomic_session.dart';
import 'package:atomic_sdk_flutter/atomic_stream_container.dart';
import 'package:meta/meta.dart';

/// Supports configuration of stream container behaviors.
class AACStreamContainerObserverConfiguration {
  AACStreamContainerObserverConfiguration({
    this.runtimeVariables,
    this.filters,
    bool runtimeVariableAnalytics = false,
    int? runtimeVariableResolutionTimeout,
    int? pollingInterval,
  }) {
    this.runtimeVariableAnalytics = runtimeVariableAnalytics;
    if (runtimeVariableResolutionTimeout != null) {
      this.runtimeVariableResolutionTimeout = runtimeVariableResolutionTimeout;
    }
    if (pollingInterval != null) {
      this.pollingInterval = pollingInterval;
    }
  }
  final AACStreamContainerConfiguration _streamConfig =
      AACStreamContainerConfiguration();

  /// Optional runtime variables that resolves for the cards.
  final Map<String, String>? runtimeVariables;

  /// Optional filters applied when fetching cards of the stream container, or `null` to observe without filters.
  /// Filters are obtained from static methods on [AACCardFilter].
  final List<AACCardFilter>? filters;

  ///  Whether the `runtime-vars-updated` analytics event, which includes resolved values of each
  ///  runtime variable, should be sent when runtime variables are resolved.
  ///  Defaults to `false`. When setting this flag to `true`, ensure that the resolved values of your runtime variables
  ///  do not include any sensitive information that should not appear in analytics.
  bool get runtimeVariableAnalytics =>
      _streamConfig.features.runtimeVariableAnalytics;
  set runtimeVariableAnalytics(bool value) =>
      _streamConfig.features.runtimeVariableAnalytics = value;

  ///  The maximum amount of time allocated when resolving variables in the delegate
  ///  If the tasks inside of the delegate method take longer than this timeout, or the completionHandler is
  ///  not called in this time, default values will be used for all runtime variables.
  ///  Defaults to 5 seconds, and cannot be negative.
  int get runtimeVariableResolutionTimeout =>
      _streamConfig.runtimeVariableResolutionTimeout;
  set runtimeVariableResolutionTimeout(int value) =>
      _streamConfig.runtimeVariableResolutionTimeout = value;

  ///  The frequency at which updates are checked when WebSockets service is not available.
  ///  Defaults to 15 seconds if unspecified.
  ///  Must be at least 1 second. If less than 1 second is specified, it defaults to 1 second.
  int get pollingInterval => _streamConfig.pollingInterval;
  set pollingInterval(int value) => _streamConfig.pollingInterval = value;

  Map<String, dynamic> toJson() {
    return {
      "runtimeVariables": runtimeVariables,
      "filters": filters == null ? null : AACCardFilter.toJsonList(filters!),
      "runtimeVariableAnalytics": runtimeVariableAnalytics,
      "runtimeVariableResolutionTimeout": runtimeVariableResolutionTimeout,
      "pollingInterval": pollingInterval,
    };
  }
}

/// Represents an individual card displayed to the end user.
@immutable
class AACCard {
  const AACCard({
    required this.defaultView,
    required this.subviews,
    required this.metaData,
    required this.instance,
    required this.id,
    required this.actions,
  });

  factory AACCard.fromJson(Map<String, dynamic> json) {
    final defaultViewJson =
        (json["defaultView"] as Map).cast<String, dynamic>();
    final instanceJson = (json["instance"] as Map).cast<String, dynamic>();
    final metadataJson = (json["metadata"] as Map).cast<String, dynamic>();
    final actionsJson = (json["actions"] as Map).cast<String, dynamic>();
    final subviews = <String, AACCardSubview>{};
    (json["subviews"] as Map).cast<String, Map<dynamic, dynamic>>().forEach(
      (key, subviewJson) {
        subviews[key] =
            AACCardSubview._fromJson(subviewJson.cast<String, dynamic>());
      },
    );
    final runtimeVariables = <AACCardRuntimeVariable>[];
    (json["runtimeVariables"] as Map)
        .cast<String, String>()
        .forEach((name, resolvedValue) {
      runtimeVariables.add(
        AACCardRuntimeVariable.fromJson(
          // Made a new Map to match how AACCardRuntimeVariable.fromJson parses arguments
          <String, String>{"name": name, "defaultValue": resolvedValue},
        ),
      );
    });
    return AACCard(
      defaultView: AACCardView._fromJson(defaultViewJson),
      subviews: subviews,
      metaData: AACCardMetaData(
        title: metadataJson["title"] as String,
        receivedAt: DateTime.parse(metadataJson["receivedAt"] as String),
        lastCardActiveTime:
            DateTime.parse(metadataJson["lastCardActiveTime"] as String),
        priority: metadataJson["priority"] as int,
      ),
      instance: AACCardInstance(
        instanceJson["eventName"] as String,
        instanceJson["lifecycleId"] as String,
        runtimeVariables,
      ),
      id: instanceJson["id"] as String,
      actions: AACCardActionPropertiesGroup._fromJson(actionsJson),
    );
  }

  /// Holds the card's `eventName`, `runtimeVariables`, and `lifecycleId`.
  final AACCardInstance instance;

  /// The card's instance id.
  final String id;

  /// An object encapsulating the action flags of a particular card, including
  /// the flags indicating the displaying of dismissing, snoozing and voting menus.
  final AACCardActionPropertiesGroup actions;

  /// The default view that should be used when rendering this card.
  final AACCardView defaultView;

  /// The subviews inside this [AACCard]. The `key` is the name of the subview.
  final Map<String, AACCardSubview> subviews;

  /// Additional information relating to the card instance.
  final AACCardMetaData metaData;
}

@immutable
class AACCardMetaData {
  const AACCardMetaData({
    required this.title,
    required this.receivedAt,
    required this.lastCardActiveTime,
    required this.priority,
  });

  final String title;

  final DateTime receivedAt;

  /// The last active time of the card.
  final DateTime lastCardActiveTime;

  /// The priority of the card, the value of which can be any number from 1 - 10, with 1 being the highest priority,
  /// and 10 being the lowest priority. Cards with higher priority appear higher in the card feed.
  /// For example a card with priority 3 will be ordered above a card with priority 4.
  /// If no priority is supplied, the default priority is 5.
  final int priority;
}

/// A card layout, which contains a collection of [AACViewNode]s. which are
/// rendered to the screen for a user.
@immutable
class AACCardView {
  const AACCardView({
    required this.nodes,
  });

  factory AACCardView._fromJson(Map<String, dynamic> viewJson) {
    final defaultViewNodes = <AACViewNode>[];

    (viewJson["nodes"] as List)
        .cast<Map<dynamic, dynamic>>()
        .forEach((nodeJson) {
      final node = AACViewNode._fromJson(nodeJson.cast<String, dynamic>());
      defaultViewNodes.add(node);
    });

    return AACCardView(nodes: defaultViewNodes);
  }

  final List<AACViewNode> nodes;
}

/// A card's subview layout, which contains a collection of [AACViewNode]s. which are
/// rendered to the screen for a user.
/// [AACCardSubview]s have a title, but are also identified by a name key in a `Map` inside [AACCard.subviews].
@immutable
class AACCardSubview extends AACCardView {
  const AACCardSubview({
    required this.title,
    required super.nodes,
  });

  factory AACCardSubview._fromJson(Map<String, dynamic> subviewJson) {
    return AACCardSubview(
      title: subviewJson["title"] as String,
      nodes: AACCardView._fromJson(subviewJson).nodes,
    );
  }

  final String title;
}

@immutable
class AACViewNode {
  const AACViewNode({
    required this.type,
    required this.children,
    required this.attributes,
    required this.validations,
  });
  factory AACViewNode._fromJson(Map<String, dynamic> nodeJson) {
    final type = nodeJson["type"] as String;
    final children = <AACViewNode>[];
    final childrenJsonList =
        (nodeJson["children"] as List).cast<Map<dynamic, dynamic>>();
    for (final childNodeJson in childrenJsonList) {
      children
          .add(AACViewNode._fromJson(childNodeJson.cast<String, dynamic>()));
    }

    final attributes = (nodeJson["attributes"] as Map).cast<String, dynamic>();

    final validations = <String, AACValidation>{};
    (nodeJson["validations"] as Map)
        .cast<String, Map<dynamic, dynamic>>()
        .forEach((validationKey, validationsAttributes) {
      validations[validationKey] = AACValidation(
        attributes: validationsAttributes.cast<String, dynamic>(),
      );
    });
    return AACViewNode(
      type: type,
      children: children,
      attributes: attributes,
      validations: validations,
    );
  }

  /// The type of this node.
  final String type;

  /// The immediate children of this node.
  final List<AACViewNode> children;

  /// The attributes of this node - each type of node has a different set of attributes.
  final Map<String, dynamic> attributes;

  /// The validations for this node that determines whether that input is valid or invalid.
  final Map<String, AACValidation> validations;
}

/// Represents a validation that determines whether that input is valid or invalid.
@immutable
class AACValidation {
  const AACValidation({required this.attributes});

  final Map<String, dynamic> attributes;
}

/// An object encapsulating the action flags of a particular card, including
/// the flags indicating the displaying of dismissing, snoozing and voting menus.
@immutable
class AACCardActionPropertiesGroup {
  const AACCardActionPropertiesGroup({
    required this.voteDown,
    required this.snooze,
    required this.dismiss,
    required this.voteUp,
  });
  factory AACCardActionPropertiesGroup._fromJson(
    Map<String, dynamic> actionsJson,
  ) {
    final dismissActionJson = _stringBoolMapCast(actionsJson["dismiss"] as Map);
    final snoozeActionJson = _stringBoolMapCast(actionsJson["snooze"] as Map);

    return AACCardActionPropertiesGroup(
      snooze: AACSwippableCardActionProperties(
        overflow: snoozeActionJson["overflow"]!,
        swipe: snoozeActionJson["swipe"]!,
      ),
      dismiss: AACSwippableCardActionProperties(
        overflow: dismissActionJson["overflow"]!,
        swipe: dismissActionJson["swipe"]!,
      ),
      voteUp: AACCardActionProperties(
        overflow: _stringBoolMapCast(actionsJson["voteUp"] as Map)["overflow"]!,
      ),
      voteDown: AACCardActionProperties(
        overflow:
            _stringBoolMapCast(actionsJson["voteDown"] as Map)["overflow"]!,
      ),
    );
  }

  static Map<String, bool> _stringBoolMapCast(
    Map<dynamic, dynamic> uncastedMap,
  ) {
    if (Platform.isIOS) {
      final castedMap = <String, bool>{};
      uncastedMap.cast<String, int>().forEach((key, value) {
        castedMap[key] = value != 0;
      });
      return castedMap;
    } else {
      return uncastedMap.cast<String, bool>();
    }
  }

  final AACCardActionProperties voteUp;
  final AACCardActionProperties voteDown;
  final AACSwippableCardActionProperties snooze;
  final AACSwippableCardActionProperties dismiss;
}

@immutable
class AACCardActionProperties {
  const AACCardActionProperties({
    required this.overflow,
  });

  final bool overflow;
}

@immutable
class AACSwippableCardActionProperties extends AACCardActionProperties {
  const AACSwippableCardActionProperties({
    required super.overflow,
    required this.swipe,
  });

  final bool swipe;
}

@immutable
sealed class AACCardAction {
  /// A custom action payload that is associated with the action.
  dynamic get arg;

  AACCardActionType get type;

  /// An [AACCardAction] for Dismissing a card with [AACSession.executeAction].
  /// The [arg] property is not applicable for this type of [AACCardAction], and will always return `null`.
  // ignore: prefer_constructors_over_static_methods
  static AACDismissCardAction dismiss() => AACDismissCardAction();

  /// An [AACCardAction] for Submitting a card with [AACSession.executeCardAction].
  /// The [arg] property contains the submitted values that are associated with a link button.
  // ignore: prefer_constructors_over_static_methods
  static AACSubmitCardAction submit(Map<String, Object> submittedValues) =>
      AACSubmitCardAction(submittedValues: submittedValues);

  /// An [AACCardAction] for Snoozing a card with [AACSession.executeCardAction].
  /// The [arg] property contains the snooze interval.
  // ignore: prefer_constructors_over_static_methods
  static AACSnoozeCardAction snooze(int snoozeInterval) =>
      AACSnoozeCardAction(snoozeInterval: snoozeInterval);
}

enum AACCardActionType {
  Dismiss,
  Snooze,
  Submit,
}

enum AACCardActionResult {
  Success,
  DataError,
  NetworkError;

  factory AACCardActionResult.fromString(String resultString) {
    return AACCardActionResult.values
        .firstWhere((element) => element.name == resultString);
  }
}

/// An [AACCardAction] for Dismissing a card with [AACSession.executeCardAction].
/// The [arg] property is not applicable for this type of [AACCardAction], and will always return `null`.
@immutable
class AACDismissCardAction extends AACCardAction {
  AACDismissCardAction();

  @override
  AACCardActionType get type {
    return AACCardActionType.Dismiss;
  }

  /// There is no arg for this type of card action. This will return `null`
  @override
  Object? get arg {
    return null;
  }
}

/// An [AACCardAction] for Submitting a card with [AACSession.executeCardAction].
/// The [arg] property contains the submitted values that are associated with a link button.
@immutable
class AACSubmitCardAction extends AACCardAction {
  AACSubmitCardAction({
    required Map<String, Object> submittedValues,
  }) {
    _submittedValues = submittedValues;
  }
  late final Map<String, dynamic> _submittedValues;

  @override
  AACCardActionType get type {
    return AACCardActionType.Submit;
  }

  /// The submitted values that are associated with the link button.
  @override
  Map<String, dynamic> get arg {
    return _submittedValues;
  }
}

/// An [AACCardAction] for Snoozing a card with [AACSession.executeCardAction].
/// The [arg] property contains the snooze interval.
@immutable
class AACSnoozeCardAction extends AACCardAction {
  AACSnoozeCardAction({
    required int snoozeInterval,
  }) {
    _snoozeInterval = snoozeInterval;
  }
  late final int _snoozeInterval;

  @override
  AACCardActionType get type {
    return AACCardActionType.Snooze;
  }

  /// The snooze interval that is associated with the link button.
  @override
  int get arg {
    return _snoozeInterval;
  }
}
