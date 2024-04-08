import 'package:meta/meta.dart';

/// This class isn't particularly intended for external access.
@internal
@protected
class AACUtils {
  static String toLocalIsoStr(DateTime dateTime) {
    return dateTime.toLocal().toIso8601String();
  }
}
