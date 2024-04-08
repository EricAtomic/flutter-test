import 'package:atomic_sdk_flutter/atomic_card_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class AACContainerViewState<T extends StatefulWidget>
    extends State<T> {
  late MethodChannel _channel;
  Future<void> applyFilter(AACCardFilter? filter) async {
    /// Applies a specified filter to the card list, showing only cards that match this filters.
    /// Each `applyFilter` call overrides the previous call (not incremental). So use `applyFilter`s to apply multiple filters at the same time.
    /// To remove all filters, pass `null` to the [filter] argument.
    await applyFilters(filter == null ? null : [filter]);
  }

  Future<void> applyFilters(List<AACCardFilter>? filters) async {
    /// Applies the specified filters to the card list, showing only cards that match these filters.
    /// Each `applyFilter` call overrides the previous call (not incremental). So use this method, `applyFilter`s, to apply multiple filters at the same time.
    /// To remove all filters, pass `null` or an empty list `[]` to the [filters] argument.
    await _channel.invokeMethod(
      "applyFilters",
      // Arguments explanation: argument is passed as an array to native wrapper, to align with other channel methods.
      // The first argument is a [List] of [AACCardFilter] objects, future arguments can be added in line with it
      [AACCardFilter.toJsonList(filters ?? [])],
    );
  }

  /// This method is just for internal use and isn't intended for public access.
  @protected
  String get viewType;

  Future<dynamic> handleMethodCall(MethodCall call);

  /// This method is just for internal use and isn't intended for public access.
  @protected
  void createMethodChannel(int viewId) {
    _channel = MethodChannel("$viewType/$viewId");
    _channel.setMethodCallHandler(handleMethodCall);
  }

  // NOTICE this doesn't do anything at the moment
  Future<void> refresh() async {
    await _channel.invokeMethod("refresh");
  }

  Future<void> updateVariables() async {
    await _channel.invokeMethod("updateVariables");
  }
}
