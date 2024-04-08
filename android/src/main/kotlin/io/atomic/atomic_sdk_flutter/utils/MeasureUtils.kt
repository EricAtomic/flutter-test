package io.atomic.atomic_sdk_flutter.utils

object MeasureUtils {

  fun dpToPx(density: Float, dp: Int): Int {
    return ((dp * density) + 0.5).toInt()
  }

  fun pxToDp(density: Float, px: Int): Int {
    return ((px / density) + 0.5).toInt()
  }
}