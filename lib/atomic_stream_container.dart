import 'package:atomic_sdk_flutter/atomic_card_event.dart';
import 'package:atomic_sdk_flutter/atomic_card_runtime_variable.dart';
import 'package:atomic_sdk_flutter/atomic_container_view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Supported options for card voting.
enum AACVotingOption { none, useful, notUseful, both }

extension VotingOptionSerialised on AACVotingOption {
  String get stringValue {
    switch (this) {
      case AACVotingOption.none:
        return 'none';
      case AACVotingOption.useful:
        return 'useful';
      case AACVotingOption.notUseful:
        return 'notUseful';
      case AACVotingOption.both:
        return 'both';
    }
  }
}

/// Supported flags for interface style.
enum AACInterfaceStyle { automatic, light, dark }

extension InterfaceStyleSerialised on AACInterfaceStyle {
  String get stringValue {
    switch (this) {
      case AACInterfaceStyle.automatic:
        return "automatic";
      case AACInterfaceStyle.dark:
        return "dark";
      case AACInterfaceStyle.light:
        return "light";
    }
  }
}

enum AACCustomString {
  /// The title to display at the top of the card list.
  /// Defaults to `Cards`.
  cardListTitle,

  /// The title to display for the card snooze functionality.
  /// Defaults to `Remind me`.
  cardSnoozeTitle,

  /// The message displayed over the card list, when the user has never received a card before.
  /// Defaults to `Cards will appear here when there’s something to action.`.
  awaitingFirstCard,

  /// The message displayed when the user has received at least one card before, and there are no cards to show.
  /// Defaults to `All caught up`.
  allCardsCompleted,

  /// The title to display for the action a user taps when they flag a card as useful.
  /// Defaults to `This is useful`.
  votingUseful,

  /// The title to display for the action a user taps when they flag a card as not useful.
  /// Defaults to `This isn't useful`.
  votingNotUseful,

  /// The title to display at the top of the screen allowing a user to provide feedback on why
  /// they didn't find a card useful.
  /// Defaults to `Send feedback`.
  votingFeedbackTitle,

  /// Message to display below the last card in the card list, if there is at least 1 card present.
  /// Has no effect in single card view, or if `cardListFooterMessageEnabled` is set to `false`.
  /// Defaults to an empty string.
  cardListFooterMessage,

  /// Message to display on the first load screen and card list when there is no internet connection.
  /// Defaults to `No internet connection`.
  noInternetConnectionMessage,

  /// Message to display on the first load screen and card list when data fails to load.
  /// Defaults to `Couldn't load data`.
  dataLoadFailedMessage,

  /// The title for the button on the first load screen and card list, allowing the user to retry the request.
  /// Defaults to `Try again`.
  tryAgainTitle,

  /// Customised toast message for when the user dismisses a card - defaults to "Card dismissed".
  toastCardDismissedMessage,

  /// Customised toast message for when the user completes a card - defaults to "Card completed".
  toastCardCompletedMessage,

  /// Customised toast messages for when the user snoozes a card - defaults to "Snoozed until X" where X is the time the user dismissed the card until.
  toastCardSnoozeMessage,

  /// Customised toast message for when the user sends feedback (votes) for a card - defaults to "Feedback received".
  toastCardFeedbackMessage
}

extension CustomStringSerialised on AACCustomString {
  String get stringValue {
    switch (this) {
      case AACCustomString.cardListTitle:
        return "cardListTitle";
      case AACCustomString.cardSnoozeTitle:
        return "cardSnoozeTitle";
      case AACCustomString.awaitingFirstCard:
        return "awaitingFirstCard";
      case AACCustomString.allCardsCompleted:
        return "allCardsCompleted";
      case AACCustomString.votingUseful:
        return "votingUseful";
      case AACCustomString.votingNotUseful:
        return "votingNotUseful";
      case AACCustomString.votingFeedbackTitle:
        return "votingFeedbackTitle";
      case AACCustomString.cardListFooterMessage:
        return "cardListFooterMessage";
      case AACCustomString.noInternetConnectionMessage:
        return "noInternetConnectionMessage";
      case AACCustomString.dataLoadFailedMessage:
        return "dataLoadFailedMessage";
      case AACCustomString.tryAgainTitle:
        return "tryAgainTitle";
      case AACCustomString.toastCardDismissedMessage:
        return "toastCardDismissedMessage";
      case AACCustomString.toastCardCompletedMessage:
        return "toastCardCompletedMessage";
      case AACCustomString.toastCardSnoozeMessage:
        return "toastCardSnoozeMessage";
      case AACCustomString.toastCardFeedbackMessage:
        return "toastCardFeedbackMessage";
    }
  }
}

enum AACPresentationStyle {
  /// The stream container should not display a button in its top left.
  /// It is your responsibility to ensure that the stream container is presented
  /// in a way that allows the user to navigate away from it.
  withoutButton,

  /// The stream container should display an action (overflow) button in its
  /// top left. When tapped, you will be notified via the action delegate, at which
  /// point you can perform your own custom action.
  withActionButton,

  /// The stream container is being presented with a Close button in its top left.
  withContextualButton
}

extension PresentationStyleSerialised on AACPresentationStyle {
  String get stringValue {
    switch (this) {
      case AACPresentationStyle.withActionButton:
        return "withActionButton";
      case AACPresentationStyle.withContextualButton:
        return "withContextualButton";
      case AACPresentationStyle.withoutButton:
        return "withoutButton";
    }
  }
}

/// Bitmask of user interface elements that should be enabled in the stream container.
/// The default value enables toast messages and the card list header.
class AACUIElement {
  const AACUIElement(this.index);
  final int index;

  /// Value indicating that none of the listed UI elements should be shown.
  static const AACUIElement none = AACUIElement(0);

  /// Value indicating that toast messages should shown over the card list.   *
  static const AACUIElement cardListToast = AACUIElement(1 << 0);

  /// Value indicating that the footer message should be shown beneath the last card in the list.   *
  static const AACUIElement cardListFooterMessage = AACUIElement(1 << 1);

  /// Value indicating that the header should be shown at the top of the card list.   *
  static const AACUIElement cardListHeader = AACUIElement(1 << 2);

  /// Value indicating that toast messages and the card list header should be shown.   *

  static final AACUIElement defaultValue =
      AACUIElement.cardListHeader | AACUIElement.cardListToast;

  AACUIElement operator |(AACUIElement other) =>
      AACUIElement(other.index | index);

  AACUIElement operator &(AACUIElement other) =>
      AACUIElement(other.index & index);

  AACUIElement operator ~() => AACUIElement(~index);

  bool contains(AACUIElement other) => (this & other).index == other.index;

  List<String> get toJson {
    final values = <String>[];
    if (contains(cardListToast)) {
      values.add('cardListToast');
    }
    if (contains(cardListFooterMessage)) {
      values.add('cardListFooterMessage');
    }
    if (contains(cardListHeader)) {
      values.add('cardListHeader');
    }
    return values;
  }
}

/// Represents features that can be turned on or off in the Atomic SDK.
class AACFeatureFlags {
  /// Whether the `runtime-vars-updated` analytics event, which includes resolved values of each
  /// runtime variable, should be sent when runtime variables are resolved. Defaults to `false`.
  ///
  /// When setting this flag to `true`, ensure that the resolved values of your runtime variables
  /// do not include any sensitive information that should not appear in analytics.
  bool runtimeVariableAnalytics = false;
}

/// Configuration object that allows integrators to tailor the stream container.
class AACStreamContainerConfiguration {
  int pollingInterval = 15;
  AACVotingOption votingOption = AACVotingOption.none;
  AACStreamContainerLaunchColors launchColors =
      AACStreamContainerLaunchColors();
  AACInterfaceStyle interfaceStyle = AACInterfaceStyle.automatic;
  Map<AACCustomString, String> customStrings = {};
  AACPresentationStyle presentationStyle = AACPresentationStyle.withoutButton;
  AACUIElement enabledUiElements = AACUIElement.defaultValue;
  int runtimeVariableResolutionTimeout = 5;
  AACFeatureFlags features = AACFeatureFlags();

  Map<String, dynamic> toJson() {
    final jsonValue = {
      'pollingInterval': pollingInterval,
      'cardVotingOptions': votingOption.stringValue,
      'launchColors': launchColors,
      'interfaceStyle': interfaceStyle.stringValue,
      'presentationStyle': presentationStyle.stringValue,
      'enabledUiElements': enabledUiElements.toJson,
      'runtimeVariableResolutionTimeout': runtimeVariableResolutionTimeout,
      'runtimeVariableAnalytics': features.runtimeVariableAnalytics,
    };
    if (customStrings.isNotEmpty) {
      jsonValue['customStrings'] =
          customStrings.map((key, value) => MapEntry(key.stringValue, value));
    }
    return jsonValue;
  }

  /// Assigns the given value to the custom string defined by the given key.
  /// `value` must be non-empty.
  void setValueForCustomString(AACCustomString key, String value) {
    if (value.isEmpty) {
      // Don't allow empty strings.
      return;
    }
    customStrings[key] = value;
  }
}

/// Specialised configuration object for use with a single card view.
class AACSingleCardConfiguration extends AACStreamContainerConfiguration {
  /// Whether the single card view should automatically display the next card in the list, if there is one,
  /// once the current card is actioned.
  /// Defaults to `false`.
  bool automaticallyLoadNextCard = false;

  @override
  Map<String, dynamic> toJson() {
    final jsonValue = super.toJson();
    jsonValue["automaticallyLoadNextCard"] = automaticallyLoadNextCard;
    return jsonValue;
  }
}

/// The style of empty state (when there are no cards) for the horizontal container.
enum AACHorizontalContainerConfigurationEmptyStyle {
  /// The horizontal container should always display a no card user interface.
  standard("standard"),

  /// The horizontal container should shrink itself when there are no cards.
  shrink("shrink");

  const AACHorizontalContainerConfigurationEmptyStyle(this.value);
  final String value;
}

/// Options that specify the alignment of the title in the horizontal header.
enum AACHorizontalContainerConfigurationHeaderAlignment {
  /// The title is aligned in the middle of the header.
  center("center"),

  /// The title is aligned to the left of the header.
  left("left");

  const AACHorizontalContainerConfigurationHeaderAlignment(this.value);
  final String value;
}

/// Options that control the alignment of the last card in the horizontal container.
/// This option only applies when there is only one card in the container.
enum AACHorizontalContainerConfigurationLastCardAlignment {
  /// The last card is aligned to the left of the container.
  left("left"),

  /// The last card is aligned in the middle of the container.
  center("center");

  const AACHorizontalContainerConfigurationLastCardAlignment(this.value);
  final String value;
}

/// Options that control the scroll mode of the horizontal container.
enum AACHorizontalContainerConfigurationScrollMode {
  /// The container scrolls over one card at a time, where applicable the card is placed
  /// in the middle of the view port when the scroll terminates.
  snap("snap"),

  /// The container scrolls freely.
  free("free");

  const AACHorizontalContainerConfigurationScrollMode(this.value);
  final String value;
}

/// Specialised configuration object for use with a horizontal container view.
class AACHorizontalContainerConfiguration
    extends AACStreamContainerConfiguration {
  AACHorizontalContainerConfiguration({
    required this.cardWidth,
  });

  /// The width of every card displayed in the horizontal container view.
  final double cardWidth;

  /// The empty style of a horizontal container view. It determines how the view displays
  /// when there are no cards. Defaults to [AACHorizontalContainerConfigurationEmptyStyle.standard].
  AACHorizontalContainerConfigurationEmptyStyle emptyStyle =
      AACHorizontalContainerConfigurationEmptyStyle.standard;

  /// The option for aligning the title of the header horizontally.
  /// Defaults to [AACHorizontalContainerConfigurationHeaderAlignment.center].
  AACHorizontalContainerConfigurationHeaderAlignment headerAlignment =
      AACHorizontalContainerConfigurationHeaderAlignment.center;

  /// The option for aligning the last card in a horizontal container.
  /// Defaults to [AACHorizontalContainerConfigurationLastCardAlignment.left].
  AACHorizontalContainerConfigurationLastCardAlignment lastCardAlignment =
      AACHorizontalContainerConfigurationLastCardAlignment.left;

  /// The option for controlling the scroll mode of the container. Defaults to [AACHorizontalContainerConfigurationScrollMode.snap].
  AACHorizontalContainerConfigurationScrollMode scrollMode =
      AACHorizontalContainerConfigurationScrollMode.snap;

  @override
  Map<String, dynamic> toJson() {
    final jsonValue = super.toJson();
    jsonValue["cardWidth"] = cardWidth;
    jsonValue["emptyStyle"] = emptyStyle.value;
    jsonValue["headerAlignment"] = headerAlignment.value;
    jsonValue["lastCardAlignment"] = lastCardAlignment.value;
    jsonValue["scrollMode"] = scrollMode.value;
    return jsonValue;
  }
}

/// Object that stores customisable colours for first time launch, before a
/// theme has been loaded.
class AACStreamContainerLaunchColors {
  Color background = const Color.fromRGBO(255, 255, 255, 1);
  Color loadingIndicator = const Color.fromRGBO(0, 0, 0, 1);
  Color button = const Color.fromRGBO(0, 0, 0, 1);
  Color text = const Color.fromRGBO(0, 0, 0, 0.5);
  Color statusBarBackground = const Color.fromRGBO(0, 0, 0, 1);

  Map<String, dynamic> toJson() {
    return {
      'background': background.value,
      'loadingIndicator': loadingIndicator.value,
      'button': button.value,
      'text': text.value,
      "statusBarBackground": statusBarBackground.value,
    };
  }
}

/// Extend this class to provide a session delegate that supplies authentication tokens
/// when requested by the SDK.
/// The method [authToken] must be implemented, and is used to supply an authentication token to the SDK.
/// If you do not supply a valid authentication token, API requests within the SDK will fail.
abstract class AACSessionDelegate {
  /// Called when the SDK has requested an authentication token.
  Future<String?> authToken();
}

/// Implements logic to resolve runtime variables on cards, when requested by the SDK.
///
abstract class AACRuntimeVariableDelegate {
  /// Delegate method that can be implemented when one or more cards include runtime variables.
  /// If the card includes runtime variables to be resolved, the SDK will call this method to ask that you resolve them.
  /// If this method is not implemented, or you do not resolve a given variable, the default values for that variable
  /// will be used (as defined in the Atomic Workbench).
  /// Variables are resolved on each card by calling `resolveRuntimeVariableWithName:value:`.
  ///
  /// - [cardInstances] An array of cards containing runtime variables that need to be resolved.
  Future<List<AACCardInstance>?> requestRuntimeVariables(
    List<AACCardInstance> cardInstances,
  ) async {
    return null;
  }
}

/// Represents a custom action triggered by a link button or submit button on a card.
class AACCardCustomAction {
  const AACCardCustomAction({
    required this.cardInstanceId,
    required this.containerId,
    required this.actionPayload,
  });

  /// The instance ID of the card where the action was triggered.
  final String cardInstanceId;

  /// The ID of the stream container that the card is contained within.
  final String containerId;

  /// A custom action payload that is associated with the link/submit button.
  /// Inspect the data in this payload to determine which action to take.
  final Map<String, dynamic> actionPayload;
}

/**
 * Represents an instance of a filter that can be applied to a list of cards.
 */

/// Extend this class to provide a delegate that responds to the event of tapping the
/// action button.
abstract class AACStreamContainerActionDelegate {
  /// The user tapped on the button in the top left of the stream container.
  ///
  /// This method is only called when the `presentationStyle` of the stream container is set
  /// to [AACPresentationStyle.withActionButton].
  void didTapActionButton() {}

  /// The user tapped on a link button, which is configured with a custom [action] in the Atomic Workbench.
  ///
  /// The [action] object provided here includes a payload - a set of key-value pairs assigned in the Workbench to this link button.
  /// Use the information in this object to determine which action to take in your app.
  void didTapLinkButton(AACCardCustomAction action) {}

  ///  The user submitted a card from a submit button that is configured with a custom [action] in the Atomic Workbench.
  ///  The [action] object provided here includes a payload - a set of key-value pairs assigned in the Workbench to this submit button.
  ///  Use the information in this object to determine which action to take in your app after the card has been submitted.
  void didTapSubmitButton(AACCardCustomAction action) {}
}

/// Creates an Atomic stream container, rendering a list of cards.
/// You must supply a `containerId` and `configuration` object.
class AACStreamContainer extends StatefulWidget {
  const AACStreamContainer({
    required this.containerId,
    required this.configuration,
    super.key,
    this.runtimeVariableDelegate,
    this.actionDelegate,
    this.eventDelegate,
    this.onViewLoaded,
  });
  final String containerId;
  final AACStreamContainerConfiguration configuration;
  final AACRuntimeVariableDelegate? runtimeVariableDelegate;
  final AACStreamContainerActionDelegate? actionDelegate;
  final AACCardEventDelegate? eventDelegate;
  final void Function(AACStreamContainerState containerState)? onViewLoaded;

  @override
  AACStreamContainerState createState() => AACStreamContainerState();
}

class AACStreamContainerState
    extends AACContainerViewState<AACStreamContainer> {
  AndroidViewController? _androidController;

  @override
  String get viewType => 'io.atomic.sdk.streamContainer';

  @override
  void dispose() {
    _androidController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      "containerId": widget.containerId,
      "configuration": widget.configuration,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <Factory<
                  OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return _androidController =
                PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const JSONMessageCodec(),
            )
                  ..addOnPlatformViewCreatedListener(
                    params.onPlatformViewCreated,
                  )
                  ..addOnPlatformViewCreatedListener(createMethodChannel);
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          gestureRecognizers: <Factory<PanGestureRecognizer>>{}..add(
              const Factory<PanGestureRecognizer>(PanGestureRecognizer.new),
            ),
          onPlatformViewCreated: createMethodChannel,
          creationParamsCodec: const JSONMessageCodec(),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'The Atomic SDK Flutter wrapper supports iOS and Android only.',
        );
    }
  }

  @override
  Future<dynamic> handleMethodCall(MethodCall call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>();
    switch (call.method) {
      case 'viewLoaded':
        // Indicate that the native container has been completely loaded
        widget.onViewLoaded?.call(this);
      case 'didTapActionButton':
        widget.actionDelegate?.didTapActionButton();
      case 'didTapLinkButton':
        if (widget.actionDelegate != null && args != null) {
          final action = AACCardCustomAction(
            cardInstanceId: args["cardInstanceId"] as String,
            containerId: args["containerId"] as String,
            actionPayload:
                (args["actionPayload"] as Map).cast<String, dynamic>(),
          );
          widget.actionDelegate!.didTapLinkButton(action);
        }
      case 'didTapSubmitButton':
        if (widget.actionDelegate != null && args != null) {
          final action = AACCardCustomAction(
            cardInstanceId: args["cardInstanceId"] as String,
            containerId: args["containerId"] as String,
            actionPayload:
                (args["actionPayload"] as Map).cast<String, dynamic>(),
          );
          widget.actionDelegate!.didTapSubmitButton(action);
        }
      case 'requestRuntimeVariables':
        final cards = <AACCardInstance>[];
        if (args == null) {
          break;
        }
        final cardsToResolveRaw = args['cardsToResolve'] as Iterable;
        for (final cardJson in cardsToResolveRaw) {
          final card = AACCardInstance.fromJson(
            (cardJson as Map).cast<String, dynamic>(),
          );
          cards.add(card);
        }
        final results = await widget.runtimeVariableDelegate
            ?.requestRuntimeVariables(cards);
        if (results != null) {
          return results.map((e) => e.toJson()).toList();
        } else {
          return cards.map((e) => e.toJson()).toList();
        }
      case 'didTriggerCardEvent':
        if (widget.eventDelegate != null && args != null) {
          final event = AACCardEvent.fromJson(
            (args['cardEvent'] as Map).cast<String, dynamic>(),
          );
          widget.eventDelegate!.didTriggerCardEvent(event);
        }
    }
  }
}
