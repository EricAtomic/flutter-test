/// Represents a runtime variable for a given card.
/// Runtime variables are resolved by the host app via `AACSessionDelegate`.
class AACCardRuntimeVariable {
  AACCardRuntimeVariable.fromJson(Map<String, dynamic> arguments)
      : name = arguments['name'] as String,
        defaultValue = arguments['defaultValue'] as String;

  /// The name used to identify the runtime variable in a card.
  final String name;

  /// The default value to use for the runtime variable, used if the host app cannot provide a value.
  final String defaultValue;
}

/// Represents an individual card displayed to the end user.
class AACCardInstance {
  AACCardInstance(this.eventName, this.lifecycleId, this.runtimeVariables);

  AACCardInstance.fromJson(Map<String, dynamic> arguments)
      : eventName = arguments['eventName'] as String,
        lifecycleId = arguments['lifecycleId'] as String,
        runtimeVariables = [] {
    for (final runtimeVarRaw in arguments['runtimeVariables'] as Iterable) {
      final runtimeVar = AACCardRuntimeVariable.fromJson(
        (runtimeVarRaw as Map).cast<String, dynamic>(),
      );
      if (runtimeVar.name.isNotEmpty) {
        runtimeVariables.add(runtimeVar);
        _variableValues[runtimeVar.name] = runtimeVar.defaultValue;
      }
    }
  }

  /// The name of the event, as defined in the Atomic Workbench, that caused this card
  /// to be created.
  final String eventName;

  /// The lifecycle ID sent with the event that created this card.
  final String lifecycleId;

  /// All runtime variables in use by this card.
  final List<AACCardRuntimeVariable> runtimeVariables;

  final Map<String, String> _variableValues = {};

  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'lifecycleId': lifecycleId,
      'runtimeVariables': [
        for (final e in _variableValues.entries)
          {'name': e.key, 'runtimeValue': e.value},
      ],
    };
  }

  /// Assigns the given `value` to the variable with the given `name`.
  /// If the variable with the given name does not exist on this card, this method does nothing for that variable.
  void resolveRuntimeVariable(String name, String value) {
    if (name.isNotEmpty && value.isNotEmpty && _variableValues[name] != null) {
      _variableValues[name] = value;
    }
  }
}
