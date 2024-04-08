package io.atomic.atomic_sdk_flutter

import android.util.Log
import java.lang.Exception

class AACFlutterLogger {
  fun error(e: Exception) {
    if (enabled) {
      Log.e("AACSDK-Flutter", "$e")
    }
  }

  companion object {
    var enabled = false
  }
}