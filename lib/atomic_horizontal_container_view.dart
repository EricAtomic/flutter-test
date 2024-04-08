import 'package:atomic_sdk_flutter/atomic_card_event.dart';
import 'package:atomic_sdk_flutter/atomic_card_runtime_variable.dart';
import 'package:atomic_sdk_flutter/atomic_container_view_state.dart';
import 'package:atomic_sdk_flutter/atomic_stream_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Creates a view designed to display a horizontal list of cards for a given stream container.
/// Cards in a horizontal list have the same card width, which must be specified during initialisation.
/// The stream container it displays is identified by its ID in the Workbench.
class AACHorizontalContainerView extends StatefulWidget {
  const AACHorizontalContainerView({
    required this.containerId,
    required this.configuration,
    super.key,
    this.runtimeVariableDelegate,
    this.actionDelegate,
    this.eventDelegate,
    this.onSizeChanged,
    this.onViewLoaded,
  });
  final String containerId;
  final AACHorizontalContainerConfiguration configuration;
  final AACRuntimeVariableDelegate? runtimeVariableDelegate;
  final void Function(double width, double height)? onSizeChanged;
  final AACStreamContainerActionDelegate? actionDelegate;
  final AACCardEventDelegate? eventDelegate;
  final void Function(AACHorizontalContainerViewState containerState)?
      onViewLoaded;

  @override
  AACHorizontalContainerViewState createState() =>
      AACHorizontalContainerViewState();
}

class AACHorizontalContainerViewState
    extends AACContainerViewState<AACHorizontalContainerView> {
  double horizontalCardHeight = 1;

  @override
  String get viewType => 'io.atomic.sdk.horizontalContainer';

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      "containerId": widget.containerId,
      "configuration": widget.configuration,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnimplementedError(
          "Horizontal container is not available on Android yet.",
        );
      case TargetPlatform.iOS:
        return SizedBox(
          width: double.infinity,
          height: horizontalCardHeight,
          child: UiKitView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            gestureRecognizers: <Factory<PanGestureRecognizer>>{}..add(
                const Factory<PanGestureRecognizer>(
                  PanGestureRecognizer.new,
                ),
              ),
            onPlatformViewCreated: createMethodChannel,
            creationParamsCodec: const JSONMessageCodec(),
          ),
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

        /// Indicate that the native container has been completely loaded
        widget.onViewLoaded?.call(this);
      case 'sizeChanged':
        if (args == null) {
          break;
        }
        final width = (args['width'] as num).toDouble();
        final height = (args['height'] as num).toDouble();
        setState(() {
          horizontalCardHeight = height;
        });
        widget.onSizeChanged?.call(width, height);
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
        final cardsToResolveRaw = args['cardsToResolve'] as List;
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
