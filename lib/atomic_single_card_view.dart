import 'package:atomic_sdk_flutter/atomic_card_event.dart';
import 'package:atomic_sdk_flutter/atomic_card_runtime_variable.dart';
import 'package:atomic_sdk_flutter/atomic_container_view_state.dart';
import 'package:atomic_sdk_flutter/atomic_stream_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Creates an Atomic single card view, rendering the most recent card in the container.
/// You must supply a `containerId` and `configuration` object.
class AACSingleCardView extends StatefulWidget {
  const AACSingleCardView({
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
  final AACSingleCardConfiguration configuration;
  final AACRuntimeVariableDelegate? runtimeVariableDelegate;
  final void Function(double width, double height)? onSizeChanged;
  final AACStreamContainerActionDelegate? actionDelegate;
  final AACCardEventDelegate? eventDelegate;
  final void Function(AACSingleCardViewState containerState)? onViewLoaded;

  @override
  AACSingleCardViewState createState() => AACSingleCardViewState();
}

class AACSingleCardViewState extends AACContainerViewState<AACSingleCardView> {
  double singleCardHeight = 1;
  AndroidViewController? _androidController;

  @override
  void dispose() {
    _androidController?.dispose();
    super.dispose();
  }

  @override
  String get viewType => 'io.atomic.sdk.singleCard';

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      "containerId": widget.containerId,
      "configuration": widget.configuration,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SizedBox(
          width: double.infinity,
          height: singleCardHeight,
          child: PlatformViewLink(
            viewType: viewType,
            surfaceFactory:
                (BuildContext context, PlatformViewController controller) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers: <Factory<PanGestureRecognizer>>{}..add(
                    const Factory<PanGestureRecognizer>(
                      PanGestureRecognizer.new,
                    ),
                  ),
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
          ),
        );
      case TargetPlatform.iOS:
        return SizedBox(
          width: double.infinity,
          height: singleCardHeight,
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
          singleCardHeight = height;
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
