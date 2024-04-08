package io.atomic.atomic_sdk_flutter

import android.content.Context
import io.atomic.atomic_sdk_flutter.model.AACContainerSettings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject

/** Factory that generates Atomic stream containers for use in Flutter. */
class AACFlutterStreamContainerFactory(
    private val binaryMessenger: BinaryMessenger) :
    PlatformViewFactory(JSONMessageCodec.INSTANCE) {

  private val flutterLogger = AACFlutterLogger()

  @Throws(Exception::class)
  override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
    try {
      val containerSettings = AACContainerSettings.create(args as JSONObject)
      return AACFlutterStreamContainer(context!!, containerSettings, viewId, binaryMessenger)
    } catch (e: Exception){
      flutterLogger.error(e)
      throw Exception("Cannot create AACStreamContainer. Check container parameters.")
    }
  }
}
