import 'package:atomic_sdk_flutter/src/atomic_utils.dart';

/// Represents an instance of a filter that can be applied to containers with `applyFilters()` or `applyFilter()`.
class AACCardFilter {
  /// Takes an [AACCardFilterValue], to filter by "equalTo".
  AACCardFilter.equalTo(AACCardFilterValue filterValue)
      : _json = {"equalTo": filterValue._json};

  /// Takes an [AACCardFilterValue],to filter by "notEqualTo".
  AACCardFilter.notEqualTo(AACCardFilterValue filterValue)
      : _json = {"notEqualTo": filterValue._json};

  /// Takes an [AACCardFilterValue], to filter by "greaterThan".
  AACCardFilter.greaterThan(AACCardFilterValue filterValue)
      : _json = {"greaterThan": filterValue._json};

  /// Takes an [AACCardFilterValue], to filter by "greaterThanOrEqualTo".
  AACCardFilter.greaterThanOrEqualTo(AACCardFilterValue filterValue)
      : _json = {"greaterThanOrEqualTo": filterValue._json};

  /// Takes an [AACCardFilterValue], to filter by "lessThan".
  AACCardFilter.lessThan(AACCardFilterValue filterValue)
      : _json = {"lessThan": filterValue._json};

  /// Takes an [AACCardFilterValue], to filter by "lessThanOrEqualTo".
  AACCardFilter.lessThanOrEqualTo(AACCardFilterValue filterValue)
      : _json = {"lessThanOrEqualTo": filterValue._json};

  /// Takes a [List] of [AACCardFilterValue]s, to filter by "contains".
  AACCardFilter.contains(List<AACCardFilterValue> filterValues)
      : _json = {
          "contains":
              filterValues.map((filterValue) => filterValue._json).toList(),
        };

  /// Takes a [List] of [AACCardFilterValue]s, to filter by "notIn".
  AACCardFilter.notIn(List<AACCardFilterValue> filterValues)
      : _json = {
          "notIn":
              filterValues.map((filterValue) => filterValue._json).toList(),
        };

  /// Takes two [AACCardFilterValue]s, to filter by "between".
  AACCardFilter.between(
    AACCardFilterValue filterValue1,
    AACCardFilterValue filterValue2,
  ) {
    final filterValues = [filterValue1, filterValue2];
    _json = {
      "between": filterValues.map((filterValue) => filterValue._json).toList(),
    };
  }

  /// Takes an [String] `cardInstanceId`, to filter by "byCardInstanceId".
  AACCardFilter.byCardInstanceId(String cardInstanceId)
      : _json = {"byCardInstanceId": cardInstanceId};
  late final Map<String, dynamic> _json;

  Map<String, dynamic> get toJson => _json;

  static List<Map<String, dynamic>> toJsonList(List<AACCardFilter> filters) {
    return filters.map((filter) => filter.toJson).toList();
  }
}

/// Represents a value of one of the card’s properties supported by the SDK,
/// which can be used to filter cards. Cards are filtered by applying one or more
/// [AACCardFilterValue]s to an operator, such as equal to or less than.
/// Properties can be card’s metadata such as its priority or created date,
/// or user defined variables.
/// Combine [AACCardFilterValue] with [AACCardFilter] to create card filters.
/// For more details on card filtering, head to the Atomic documentation site.
class AACCardFilterValue {
  /// This particular [AACCardFilterValue] constructor represents a "byPriority" property
  AACCardFilterValue.byPriority(int priority) {
    _json = {"byPriority": priority};
  }

  // TODO change comment once updated
  /// Currently broken on Android.
  /// This particular [AACCardFilterValue] constructor represents a "byCreatedDate" property
  AACCardFilterValue.byCreatedDate(DateTime dateTime) {
    _json = {"byCreatedDate": AACUtils.toLocalIsoStr(dateTime)};
  }

  /// This particular [AACCardFilterValue] constructor represents a "byCardTemplateId" property
  AACCardFilterValue.byCardTemplateId(String cardTemplateId) {
    _json = {"byCardTemplateId": cardTemplateId};
  }

  /// This particular [AACCardFilterValue] constructor represents a "byCardTemplateName" property
  AACCardFilterValue.byCardTemplateName(String cardTemplateName) {
    _json = {"byCardTemplateName": cardTemplateName};
  }

  /// This particular [AACCardFilterValue] constructor represents a "byVariableNameString" property
  AACCardFilterValue.byVariableNameString(String variableName, String value) {
    _byVariableName(variableName, value);
  }

  /// This particular [AACCardFilterValue] constructor represents a "byVariableNameInt" property
  AACCardFilterValue.byVariableNameInt(String variableName, int value) {
    _byVariableName(variableName, value);
  }

  /// This particular [AACCardFilterValue] constructor represents a "byVariableNameDateTime" property
  AACCardFilterValue.byVariableNameDateTime(
    String variableName,
    DateTime value,
  ) {
    _byVariableName(variableName, AACUtils.toLocalIsoStr(value));
  }

  // TODO change comment once updated
  /// Currently broken on Android.
  /// This particular [AACCardFilterValue] constructor represents a "byVariableNameBool" property
  // ignore: avoid_positional_boolean_parameters
  AACCardFilterValue.byVariableNameBool(String variableName, bool value) {
    _byVariableName(variableName, value);
  }
  late final Map<String, dynamic> _json;

  void _byVariableName(String variableName, dynamic variableValue) {
    _json = {
      "byVariableName": {variableName: variableValue},
    };
  }
}
