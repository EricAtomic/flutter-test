package io.atomic.atomic_sdk_flutter.model

import io.atomic.atomic_sdk_flutter.utils.asListOfType
import io.atomic.atomic_sdk_flutter.utils.asStringMap
import io.atomic.atomic_sdk_flutter.utils.asStringMapOfType
import io.atomic.atomic_sdk_flutter.utils.toMap
import org.json.JSONObject

/**
 * Represents features that can be turned on or off in the Atomic SDK.
 */
data class AACFeatureFlags(var runtimeVariableAnalyticsEnabled: Boolean)

/**
 * AACContainerSettings manages AAC Stream Container settings.
 * An app could have as many of these as required.
 */
data class AACContainerSettings(
  val containerId: String, // Y
  val pollingInterval: Int,
  val cardVotingOptions: String,
  val customStrings: Map<String, String>?,
  val enabledUiElements: List<String>?,
  val presentationStyle: String,
  val statusBarBackgroundColor: Int,
  val runtimeVariableResolutionTimeout: Long,
  val features: AACFeatureFlags,

  val launchColorBackground: Int,
  val launchColorLoadingIndicator: Int,
  val launchColorButton: Int,
  val launchColorText: Int
) {

  companion object {
    fun create(json: JSONObject): AACContainerSettings {
      return json.toMap().let {
        val containerId = it["containerId"] as? String
          ?: throw IllegalArgumentException("You must provide a stream container ID when creating a stream container.")
        val configuration = (it["configuration"] as Map<*, *>).asStringMap()
          ?: throw java.lang.IllegalArgumentException("You must supply a Map when passing settings to the stream container.")
        val pollingInterval = configuration["pollingInterval"] as? Int
        val cardVotingOptions = configuration["cardVotingOptions"] as? String
        val customStrings = (configuration["customStrings"] as? Map<*, *>)?.asStringMapOfType<String>()
        val enabledUiElements = configuration["enabledUiElements"]?.asListOfType<String>()
        val presentationStyle = configuration["presentationStyle"] as? String
        val runtimeVariableResolutionTimeout =
          (configuration["runtimeVariableResolutionTimeout"] as? Int)?.toLong()?.times(1000)
        val runtimeVariableAnalyticsEnabled = configuration["runtimeVariableAnalytics"] as? Boolean
        // Launch colors.
        val launchColors = configuration["launchColors"] as Map<*, *>
        val statusBarBackgroundColor = (launchColors["statusBarBackground"] as? Long)?.toInt()
        val background = (launchColors["background"] as? Long)?.toInt()
        val loadingIndicator = (launchColors["loadingIndicator"] as? Long)?.toInt()
        val buttonColor = (launchColors["button"] as? Long)?.toInt()
        val textColor = (launchColors["text"] as? Long)?.toInt()
        AACContainerSettings(
          containerId,
          pollingInterval ?: 15,
          cardVotingOptions ?: "none",
          customStrings,
          enabledUiElements,
          presentationStyle ?: "withoutButton",
          statusBarBackgroundColor ?: 0,
          runtimeVariableResolutionTimeout ?: 5000,
          AACFeatureFlags(runtimeVariableAnalyticsEnabled ?: false),
          background ?: 0,
          loadingIndicator ?: 0,
          buttonColor ?: 0,
          textColor ?: 0
        )
      }
    }
  }
}

