package io.atomic.atomic_sdk_flutter

import android.content.Context
import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.Observer
import com.atomic.actioncards.feed.data.model.Card
import com.atomic.actioncards.sdk.AACCardAction
import com.atomic.actioncards.sdk.AACCardActionResult
import com.atomic.actioncards.sdk.AACSDK
import com.atomic.actioncards.sdk.AACSDKLogoutResult
import com.atomic.actioncards.sdk.AACStreamContainer
import com.atomic.actioncards.sdk.events.AACEventPayload
import com.atomic.actioncards.sdk.events.AACProcessedEvent
import com.atomic.actioncards.sdk.notifications.AACSDKRegistrationCallback
import io.atomic.atomic_sdk_flutter.utils.FilterApplier
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

private var flutterLogger: AACFlutterLogger = AACFlutterLogger()
/**
 * Manages Android AACSDK
 */
class AACFlutterSDK {
  private var cardCountObservers = mutableMapOf<String, CardCountObserver>()
  private var cardCountInstanceCount = 0
  private lateinit var context : Context

  /**
   * Initialises the components of the Atomic SDK. This method must be called before
   * using any other methods.
   */
  fun initSDK(context: Context) {
    this.context = context
    AACSDK.init(context)
  }

  fun setClientAppVersion(version: String) {
    AACSDK.setClientAppVersion(version)
  }

  fun trackPushNotificationReceived(data: Map<String, String>): Boolean {
    return run {
      AACSDK.notificationFromPushNotificationPayload(data)
    } != null
  }

  fun userMetrics(streamContainerId: String, result: Result) {
    AACSDK.userMetrics { userMetrics ->
      CoroutineScope(Dispatchers.Main + NonCancellable).launch {
        if (userMetrics != null) {
          with(userMetrics) {
            val totalCardsFinal: Int
            val unseenCardsFinal: Int
            if (streamContainerId.isEmpty()) {
              totalCardsFinal = totalCards
              unseenCardsFinal = unseenCards
            } else {
              totalCardsFinal = totalCardsForStreamContainer(streamContainerId)
              unseenCardsFinal = unseenCardsForStreamContainer(streamContainerId)
            }
            result.success(
              mapOf(
                "totalCards" to totalCardsFinal,
                "unseenCards" to unseenCardsFinal
              )
            )
          }
        } else {
          result.error(
            "User metrics could not be retrieved - the authentication token may be invalid.",
            "Failed to request user metrics.",
            null
          )
        }
      }
    }
  }

  fun sendEvent(eventPayload: AACEventPayload, result: Result) {
    AACSDK.sendEvent(eventPayload, object : AACSDK.SendEventListener {
      override fun onSuccess(batchId: String, processedEvents: Array<AACProcessedEvent>) {
        // Handle success case - the batch ID and processed events are supplied.
        val processedEventsRaw = mutableListOf<Map<String, *>>()
        for (processedEvent in processedEvents) {
          processedEventsRaw.add(
            mapOf(
              "name" to processedEvent.name,
              "lifecycleId" to processedEvent.lifecycleId,
              "version" to processedEvent.version
            )
          )
        }
        CoroutineScope(Dispatchers.Main + NonCancellable).launch {
          result.success(mapOf("batchId" to batchId, "processedEvents" to processedEventsRaw))
        }
      }

      override fun onError(e: Exception) {
        CoroutineScope(Dispatchers.Main + NonCancellable).launch {
          // Handle error case - error details are provided in the exception.
          result.error(
            "Failed to send event. The event name may be invalid or not enabled for client-side triggers in the Atomic Workbench.",
            e.localizedMessage ?: "",
            null
          )
        }
      }
    })
  }

  fun requestCardCountForStreamContainerWithIdentifier(
    streamContainerId: String,
    result: Result
  ) {
    AACSDK.getCardCountForStreamContainer(
      streamContainerId
    ) { cardCount ->
      CoroutineScope(Dispatchers.Main + NonCancellable).launch {
        if (cardCount != null) {
          result.success(cardCount)
        } else {
          result.error(
            "Failed to retrieve card count. The authentication token or stream container ID may be invalid.",
            "The card count is not available for this stream container ($streamContainerId)",
            null
          )
        }
      }
    }
  }

  fun setApiBaseUrl(arguments: ArrayList<String>): Boolean {
    val baseUrl = arguments[0]
    AACSDK.setApiHost(baseUrl)
    return true
  }

  fun initialise(arguments: ArrayList<String>): Boolean {
    val environmentId = arguments[0]
    val apiKey = arguments[1]
    AACSDK.setEnvironmentId(environmentId)
    AACSDK.setApiKey(apiKey)
    return true
  }

  private fun dealRegistrationCallback(errorCode: String, callback: AACSDKRegistrationCallback, result: Result) {
    when(callback) {
      is AACSDKRegistrationCallback.Success -> result.success(true)
      is AACSDKRegistrationCallback.NetworkError ->
        result.error(errorCode, "Failed due to a network error; i.e. the device is offline.", null)
      is AACSDKRegistrationCallback.DataError ->
        result.error(errorCode, "Failed due to a data error or the Atomic Platform being unavailable.", null)
      else -> result.error(errorCode, "Unknown error.", null)
    }
  }

  fun registerDeviceForNotifications(fcmToken: String, result: Result) {
    val errorCode = "Error when registering the device for notifications."
    try {
      AACSDK.registerDeviceForNotifications(fcmToken) {
       dealRegistrationCallback(errorCode, it, result)
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(errorCode, e.message, null)
    }
  }

  fun registerStreamContainersForNotifications(streamContainerIds: ArrayList<String>, result: Result, notificationEnabled: Boolean? = null) {
    val errorCode = "Error when registering stream containers for notifications."
    try {
      if(notificationEnabled != null) {
        AACSDK.registerStreamContainersForNotifications(streamContainerIds, notificationsEnabled = notificationEnabled) {
          dealRegistrationCallback(errorCode, it, result)
        }
      } else {
        AACSDK.registerStreamContainersForNotifications(streamContainerIds) {
          dealRegistrationCallback(errorCode, it, result)
        }
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(errorCode, e.message, null)
    }
  }

  fun deregisterDeviceForNotifications(result: Result) {
    val errorCode = "Error when de-registering the device for notifications."
    try {
      AACSDK.deregisterDeviceForNotifications {
        dealRegistrationCallback(errorCode, it, result)
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(errorCode, e.message, null)
    }
  }

  fun notificationFromPushPayload(payload: Map<String, String>): Map<String, Any>? {
    try {
      AACSDK.notificationFromPushNotificationPayload(payload)?.let {
        return mapOf(
          "containerId" to it.streamContainerId,
          "cardInstanceId" to it.cardInstanceId,
          "detail" to it.details
        )
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
    }
    return null
  }

  fun enableDebugMode(arguments: ArrayList<Int>): Boolean {
    try {
      AACSDK.enableDebugMode(arguments[0])
      AACFlutterLogger.enabled = arguments[0] > 0
    } catch (e: Exception) {
      flutterLogger.error(e)
    }
    return true
  }

  fun logout(result: Result) {
    AACSDK.logout(false) {
      when (it) {
        is AACSDKLogoutResult.Success -> result.success(true)
        is AACSDKLogoutResult.NetworkError -> {
          result.error("Error when logging out.", "Analytics events failed to send due to a network error; i.e. the device is offline.", null)
        }
        is AACSDKLogoutResult.DataError -> {
          result.error("Error when logging out.", "Analytics events failed to send due to malformed data or the Atomic Platform being unavailable.", null)
        }
      }
    }
  }

  private class CardCountObserver(context : Context, identifier : String, containerId : String, interval : Long, filtersJsonList: List<Map<String, *>>, onCount: ((Int, String) -> Unit)) {
    private var observer : Observer<Int?>
    private var container : AACStreamContainer
    private var liveCount : LiveData<Int?>
    init {
      container = AACStreamContainer.create(containerId)
      container.cardListRefreshInterval = interval
      if (filtersJsonList.isNotEmpty()) {
        FilterApplier(context).tryApplyFiltersFromJson(filtersJsonList, container)
      }

      container.startUpdates()

      observer = Observer { count: Int? ->
        if (count != null) {
          Log.i("cardCount", "$identifier has a new count: $count")
          onCount(count, identifier)
        }
      }
      liveCount = AACSDK.getLiveCardCountForStreamContainer(container)
      liveCount.observeForever(observer)
    }
    fun stop() {
      liveCount.removeObserver(observer)
      container.stopUpdates()
    }
  }

  fun observeCardCount(
    containerId: String,
    pollingInterval: Int,
    filtersJsonList:  List<Map<String, *>>,
    onCount: ((Int, String) -> Unit)
  ): String {
    val interval = if (pollingInterval < 1000) {
      1000
    } else {
      pollingInterval.toLong()
    }
    val identifier = getNextObsCardCountIdentifier()
    cardCountObservers[identifier] = CardCountObserver(context, identifier, containerId, interval, filtersJsonList, onCount)
    return identifier
  }

  private fun getNextObsCardCountIdentifier(): String {
    cardCountInstanceCount += 1
    return "AACFlutterCardCountObserver-${cardCountInstanceCount}"
  }

  fun stopObservingCardCount(identifier: String): Boolean {
    if (cardCountObservers[identifier] == null) {
      Log.i("cardCount", "Observer $identifier doesn't exist")
      return false;
    }
    else {
      cardCountObservers[identifier]!!.stop()
      cardCountObservers.remove(identifier)
      Log.i("cardCount", "Observer $identifier removed")
    }
    return true
  }

  fun observeStreamContainer(
          container:  AACStreamContainer,
          runtimeVariables: Map<String, String>?,
          runtimeVariableAnalytics: Boolean,
          runtimeVariableResolutionTimeout: Int,
          filtersJsonList: List<Map<String, *>>?,
          pollingInterval: Int,
          onUpdate: (List<Card>?) -> Unit)
          : String {
    val interval = if (pollingInterval < 1000) {
      1000
    } else {
      pollingInterval.toLong()
    }

    container.cardListRefreshInterval = interval

    if (!filtersJsonList.isNullOrEmpty()) {
      FilterApplier(context).tryApplyFiltersFromJson(filtersJsonList, container)
    }

    container.runtimeVariableResolutionTimeout = runtimeVariableResolutionTimeout.toLong()
    container.runtimeVariableAnalyticsEnabled = runtimeVariableAnalytics
    if (!runtimeVariables.isNullOrEmpty()) {
      container.cardDidRequestRunTimeVariablesHandler = { cards, done ->
        for (card in cards) {
          runtimeVariables.forEach { (name, value) ->
            card.resolveVariableWithNameAndValue(name, value)
          }
        }
        done(cards)
      }
    }

    return AACSDK.observeStreamContainer(container, onUpdate)
  }

  fun executeCardAction(containerId: String, cardInstanceId : String, actionType : String, arg : Any?, result : Result) {
    val card : Card = Card.createWithId(cardInstanceId)
    val action : AACCardAction = when (actionType) {
      "Dismiss" -> AACCardAction.Dismiss(card)
      "Snooze" -> AACCardAction.Snooze(card, (arg as Int).toLong())
      "Submit" -> {
        val submittedValues = arg as? Map<String, Any>
        if (submittedValues == null) {
          result.error("submittedValues not given for the Submit card action.", "Failed to execute card action.", null)
          return
        }
        AACCardAction.Submit(card, submittedValues.toMutableMap())
      }
      else -> {
        result.error("Action type not found.", "Failed to execute card action.", null)
        return
      }
    }
    AACSDK.onCardAction(AACStreamContainer.create(containerId), action) { actionResult ->
      // result.success even for AACCardActionResult errors might be confusing here.
      // It's because a String result is returned to the wrapper,
      // and the "result" variable is completely different to "actionResult", despite similar names.
      when (actionResult) {
        AACCardActionResult.Success -> {
          result.success("Success")
        }
        AACCardActionResult.DataError -> {
          result.success("DataError")
        }
        AACCardActionResult.NetworkError -> {
          result.success("NetworkError")
        }
      }
    }
  }
}
