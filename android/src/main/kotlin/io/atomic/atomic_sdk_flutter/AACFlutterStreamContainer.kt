package io.atomic.atomic_sdk_flutter

import android.content.Context
import android.content.ContextWrapper
import android.view.View
import androidx.fragment.app.FragmentActivity
import com.atomic.actioncards.feed.data.model.AACCardEvent
import com.atomic.actioncards.feed.data.model.AACCardInstance
import com.atomic.actioncards.sdk.AACStreamContainer
import com.atomic.actioncards.sdk.PresentationMode
import com.atomic.actioncards.sdk.VotingOption
import io.atomic.atomic_sdk_flutter.helpers.AACFlutterWrapperFragment
import io.atomic.atomic_sdk_flutter.model.AACContainerSettings
import io.atomic.atomic_sdk_flutter.utils.FilterApplier
import io.atomic.atomic_sdk_flutter.utils.asListOfType
import io.atomic.atomic_sdk_flutter.utils.asStringMapOfType
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.*
import java.util.*

/**
 * AACFlutterStreamContainer
 * Flutter view that wraps an AACStreamContainer.
 * */
internal open class AACFlutterStreamContainer(
  private val context: Context,
  internal val settings: AACContainerSettings,
  viewId: Int, binaryMessenger: BinaryMessenger
) : PlatformView {

  private var fragment = AACFlutterWrapperFragment()
  private lateinit var container: AACStreamContainer
  internal open val channel: MethodChannel =
    MethodChannel(binaryMessenger, "io.atomic.sdk.streamContainer/${viewId}")

  /// To prevent loading event being triggered multiple times
  private var isInitialised = false

  init {
    initAACSDK()
  }

  override fun getView(): View {
    return fragment.requireView()
  }

  override fun dispose() {
    container.destroy(fragment.childFragmentManager)
    isInitialised = false
  }

  @Throws(Exception::class)
  private fun initAACSDK() {
    val manager = when (context) {
      is FragmentActivity -> {
        context.supportFragmentManager
      }
      is ContextWrapper -> {
        (context.baseContext as FragmentActivity).supportFragmentManager
      }
      else -> {
        throw Exception("Cannot create AACStreamContainer. Unknown context: $context")
      }
    }

    manager.beginTransaction().add(fragment, "AACFlutterWrapperFragment").commitNow()

    val fm = fragment.childFragmentManager
    /**
     * Due to limitations in the Android SDK, we have to request the authentication token once
     * when creating the container, rather than requesting it on-demand.
     */
    CoroutineScope(Dispatchers.Main + NonCancellable).launch {
      container = buildContainer()

      with(container) {
        cardEventHandler = ::cardEventHandler
        // The Android SDK expresses the polling interval in milliseconds
        cardListRefreshInterval = settings.pollingInterval * 1000L

        cardVotingOptions = when (settings.cardVotingOptions) {
          "none" -> EnumSet.of(VotingOption.None)
          "useful" -> EnumSet.of(VotingOption.Useful)
          "notUseful" -> EnumSet.of(VotingOption.NotUseful)
          "both" -> EnumSet.of(VotingOption.Useful, VotingOption.NotUseful)
          else -> EnumSet.of(VotingOption.None)
        }

        configuration.apply {
          launchBackgroundColor = settings.launchColorBackground
          launchLoadingColor = settings.launchColorLoadingIndicator
          launchButtonColor = settings.launchColorButton
          launchTextColor = settings.launchColorText
          statusBarBackgroundColor = settings.statusBarBackgroundColor
          settings.customStrings?.let { customStrings ->
            customStrings["cardListFooterMessage"]?.let {
              cardListFooterMessage = it
            }
            customStrings["cardListTitle"]?.let {
              cardListTitle = it
            }
            customStrings["noInternetConnectionMessage"]?.let {
              noInternetMessage = it
            }
            customStrings["tryAgainTitle"]?.let {
              tryAgainButtonTitle = it
            }
            customStrings["dataLoadFailedMessage"]?.let {
              apiErrorMessage = it
            }
            customStrings["allCardsCompleted"]?.let {
              allCardsCompleted = it
            }
            customStrings["awaitingFirstCard"]?.let {
              awaitingFirstCard = it
            }
            customStrings["cardSnoozeTitle"]?.let {
              cardSnoozeTitle = it
            }
            customStrings["votingUseful"]?.let {
              votingUsefulTitle = it
            }
            customStrings["votingNotUseful"]?.let {
              votingNotUsefulTitle = it
            }
            customStrings["votingFeedbackTitle"]?.let {
              votingFeedbackTitle = it
            }
          }
          settings.enabledUiElements?.let {
            cardListHeaderEnabled = it.contains("cardListHeader")
            toastMessagesEnabled = it.contains("cardListToast")
          }
          presentationStyle = when (settings.presentationStyle) {
            "withoutButton" -> PresentationMode.WITHOUT_ACTION_BUTTON
            "withActionButton" -> PresentationMode.WITH_ACTION_BUTTON
            else -> PresentationMode.WITHOUT_ACTION_BUTTON
          }

          cardDidRequestRuntimeVariablesHandler = ::cardDidRequestRuntimeVariables
          runtimeVariableResolutionTimeout = settings.runtimeVariableResolutionTimeout
          runtimeVariableAnalyticsEnabled = settings.features.runtimeVariableAnalyticsEnabled

          actionDelegate = {
            channel.invokeMethod("didTapActionButton", null)
          }
          linkButtonWithPayloadActionHandler = {
            channel.invokeMethod(
              "didTapLinkButton",
              mapOf(
                "cardInstanceId" to it.cardInstanceId,
                "containerId" to it.streamContainerId,
                "actionPayload" to it.payload
              )
            )
          }
          submitButtonWithPayloadActionHandler = {
            channel.invokeMethod(
              "didTapSubmitButton",
              mapOf(
                "cardInstanceId" to it.cardInstanceId,
                "containerId" to it.streamContainerId,
                "actionPayload" to it.payload
              )
            )
          }
        }
      }

      // Following: https://stackoverflow.com/a/22312916/1476228
      view.viewTreeObserver?.addOnGlobalLayoutListener {
        if (!isInitialised) {
          container.start(fragment.requireView().id, fm)
          channel.invokeMethod("viewLoaded", null)
          isInitialised = true
        }
        onChangeSize()
      }
      channel.setMethodCallHandler(::onMethodCall)
    }


  }

  private fun cardDidRequestRuntimeVariables(
    cards: List<AACCardInstance>,
    done: (cardWithResolvedVariables: List<AACCardInstance>) -> Unit
  ) {

    if (cards.isEmpty()) {
      done(cards)
      return
    }

    val cardsToResolveList = mutableListOf<Any>()
    for (card in cards) {
      val variables = mutableListOf<Any>()
      for (variable in card.variables) {
        variables.add(mapOf("name" to variable.name, "defaultValue" to variable.resolvedVariable))
      }
      cardsToResolveList.add(
        mapOf(
          "eventName" to card.eventName,
          "lifecycleId" to card.lifecycleIdentifier,
          "runtimeVariables" to variables
        )
      )
    }

    CoroutineScope(Dispatchers.Main + NonCancellable).launch {
      channel.invokeMethod("requestRuntimeVariables",
        mapOf("cardsToResolve" to cardsToResolveList),
        object : MethodChannel.Result {
          override fun success(result: Any?) {
            result?.asListOfType<Map<String, *>>()?.let { resultMap ->
              for (cardRaw in resultMap) {
                val lifecycleId = cardRaw["lifecycleId"] as String
                cardRaw["runtimeVariables"]?.asListOfType<Map<*, *>>()
                  ?.let { runtimeVariablesRaw ->
                    val matchedCards =
                      cards.filter { it.lifecycleIdentifier == lifecycleId }
                    for (matchedCard in matchedCards) {
                      for (variableRaw in runtimeVariablesRaw) {
                        variableRaw.asStringMapOfType<String>()?.let {
                          matchedCard.resolveVariableWithNameAndValue(
                            it["name"],
                            it["runtimeValue"]
                          )
                        }
                      }
                    }
                  }
              }
              done(cards)
            }
          }

          override fun error(
            errorCode: String,
            errorMessage: String?,
            errorDetails: Any?
          ) {
            AACFlutterLogger().error(Exception("Error occurred when resolving runtime variables."))
            var error = ""
            errorMessage?.let {
              error += "errorMessage:$it "
            }
            (errorDetails as? String)?.let {
              error += "errorDetails:$it "
            }
            AACFlutterLogger().error(Exception(error))
            done(cards)
          }

          override fun notImplemented() {}
        })
    }
  }

  internal open fun buildContainer(): AACStreamContainer =
    AACStreamContainer.create(settings.containerId)

  open fun onChangeSize() {
  }

  private fun applyFilters(argumentsRaw: Any) {
    val fragmentManager = fragment.childFragmentManager
    if (fragmentManager.fragments.size == 0) return
    (argumentsRaw as List<*>).firstOrNull()?.asListOfType<Map<String, *>>()?.let { FilterApplier(context).tryApplyFiltersFromJson(it, container, fragmentManager) }
  }

  private fun updateVariables() {
    container.updateVariables(fragment.childFragmentManager)
  }

  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "applyFilters" -> applyFilters(call.arguments)
      "updateVariables" -> updateVariables()
      else -> {
        result.error(
          ERROR_CODE_UNSUPPORTED_CHANNEL_COMMAND,
          "Unsupported command: ${call.method}",
          "Failed to process channel command"
        )
      }
    }
  }

  private fun cardEventHandler(event: AACCardEvent) {
    when (event) {
      AACCardEvent.Submitted -> "cardSubmitted"
      AACCardEvent.Dismissed -> "cardDismissed"
      AACCardEvent.Snoozed -> "cardSnoozed"
      AACCardEvent.VotedUseful -> "cardVotedUseful"
      AACCardEvent.VotedNotUseful -> "cardVotedNotUseful"
      AACCardEvent.SubmitFailed -> "cardSubmitFailed"
      AACCardEvent.DismissFailed -> "cardDismissFailed"
      AACCardEvent.SnoozeFailed -> "cardSnoozeFailed"
    }.let {
      CoroutineScope(Dispatchers.Main + NonCancellable).launch {
        channel.invokeMethod("didTriggerCardEvent", mapOf("cardEvent" to mapOf("kind" to it)))
      }
    }
  }

  companion object {

    const val ERROR_CODE_UNSUPPORTED_CHANNEL_COMMAND = "01"
  }
}