package io.atomic.atomic_sdk_flutter

import android.content.Context
import android.view.View
import com.atomic.actioncards.sdk.AACSingleCardView
import com.atomic.actioncards.sdk.AACStreamContainer
import io.atomic.atomic_sdk_flutter.model.AACContainerSettings
import io.atomic.atomic_sdk_flutter.utils.MeasureUtils
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * AACFlutterSingleCardView
 * Flutter view that wraps an AACSingleCardView.
 * */
internal class AACFlutterSingleCardView(
  context: Context,
  settings: AACContainerSettings,
  viewId: Int, binaryMessenger: BinaryMessenger
) : AACFlutterStreamContainer(context, settings, viewId, binaryMessenger) {

  override val channel: MethodChannel = MethodChannel(binaryMessenger,
    "io.atomic.sdk.singleCard/${viewId}")

  override fun buildContainer(): AACStreamContainer =
    AACSingleCardView.create(settings.containerId)

  private var height: Int = 0
  private var width: Int = 0

  override fun onChangeSize() {
    val wrapper = view.findViewById<View>(R.id.aac_cardItemCardView)
    wrapper?.let {
      val nh =
        MeasureUtils.pxToDp(wrapper.context.resources.displayMetrics.density, wrapper.height)
      val nw =
        MeasureUtils.pxToDp(wrapper.context.resources.displayMetrics.density, wrapper.width)
      if (nh != height || nw != width) {
        height = nh
        width = nw
        val sizes = mapOf("height" to height, "width" to width)
        channel.invokeMethod("sizeChanged", sizes)
      }
    }
  }

}