package io.atomic.atomic_sdk_flutter

import android.util.Log
import com.atomic.actioncards.analytics.services.AACEventName
import com.atomic.actioncards.feed.data.model.CardActions
import com.atomic.actioncards.feed.data.model.CardIdentifier
import com.atomic.actioncards.feed.data.model.CardMetadata
import com.atomic.actioncards.feed.data.model.CardSubview
import com.atomic.actioncards.feed.data.model.CardView
import com.atomic.actioncards.sdk.AACSDK
import com.atomic.actioncards.sdk.AACSDKSendUserSettingsResult
import com.atomic.actioncards.sdk.AACStreamContainer
import com.atomic.actioncards.sdk.AACUserNotificationTimeframe
import com.atomic.actioncards.sdk.AACUserSettings
import com.atomic.actioncards.sdk.events.AACEventPayload
import com.squareup.moshi.Moshi
import io.atomic.atomic_sdk_flutter.helpers.AACFlutterSessionDelegate
import io.atomic.atomic_sdk_flutter.utils.asListOfType
import io.atomic.atomic_sdk_flutter.utils.asStringMap
import io.atomic.atomic_sdk_flutter.utils.asStringMapOfType
import io.atomic.atomic_sdk_flutter.utils.longLog
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.launch

/**
 * Flutter plugin for Atomic SDK on Android
 * AACFlutterPlugin is the entry point between Flutter and Android by using a
 * Flutter Method Channel.
 **/
class AACFlutterPlugin : FlutterPlugin, MethodCallHandler {

  private val aacFlutterSDK = AACFlutterSDK()
  private lateinit var channel: MethodChannel
  private val flutterLogger = AACFlutterLogger()
  private var flutterSessionDelegate: AACFlutterSessionDelegate? = null

  override fun onAttachedToEngine(binding: FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, SESSION_CHANNEL)
    channel.setMethodCallHandler(this)

    aacFlutterSDK.initSDK(binding.applicationContext)

    val singleCardViewFactory = AACFlutterSingleCardViewFactory(binding.binaryMessenger)
    binding
      .platformViewRegistry
      .registerViewFactory("io.atomic.sdk.singleCard", singleCardViewFactory)

    val streamContainerFactory = AACFlutterStreamContainerFactory(binding.binaryMessenger)
    binding
      .platformViewRegistry
      .registerViewFactory("io.atomic.sdk.streamContainer", streamContainerFactory)
  }

  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "setApiBaseUrl" -> setApiBaseUrl(call, result)
      "initialise" -> initialise(call, result)
      "enableDebugMode" -> enableDebugMode(call, result)
      "logout" -> logout(result)
      "registerDeviceForNotifications" -> registerDeviceForNotifications(call, result)
      "registerStreamContainersForNotifications" -> registerStreamContainersForNotifications(call, result)
      "registerStreamContainersForNotificationsEnabled" -> registerStreamContainersForNotificationsEnabled(call, result)
      "deregisterDeviceForNotifications" -> deregisterDeviceForNotifications(result)
      "notificationFromPushPayload" -> notificationFromPushPayload(call, result)
      "observeCardCount" -> observeCardCount(call, result)
      "stopObservingCardCount" -> stopObservingCardCount(call, result)
      "observeStreamContainer" -> observeStreamContainer(call, result)
      "stopObservingStreamContainer" -> stopObservingStreamContainer(call, result)
      "requestCardCount" -> requestCardCount(call, result)
      "sendEvent" -> sendEvent(call, result)
      "userMetrics" -> userMetrics(call, result)
      "trackPushNotificationReceived" -> trackPushNotificationReceived(call, result)
      "onAuthTokenReceived" -> didReceiveAuthenticationToken(call)
      "setClientAppVersion" -> setClientAppVersion(call, result)
      "setSessionDelegate" -> setSessionDelegate(result)
      "updateUser" -> updateUser(call, result)
      "startObservingSDKEvents" -> startObservingSDKEvents(call, result)
      "stopObservingSDKEvents" -> stopObservingSDKEvents(call, result)
      "executeCardAction" -> executeCardAction(call, result)
      else -> result.notImplemented()
    }
  }

  private fun updateUser(call: MethodCall, result: Result) {
    try {
      /// call.arguments is from [userSettings.toJsonValue()] in atomic_session.dart
      /// which is a List<Map<String, dynamic>>

      val userSettingsRaw = (call.arguments as? List<Map<String, *>>)?.get(0)
              ?: throw IllegalArgumentException("You must supply a user settings JSON map that will be parsed to an AACUserSettings object.")

      val userSettings = AACUserSettings()
      userSettings.externalID = userSettingsRaw["externalID"] as? String
      userSettings.name = userSettingsRaw["name"] as? String
      userSettings.email = userSettingsRaw["email"] as? String
      userSettings.phone = userSettingsRaw["phone"] as? String
      userSettings.city = userSettingsRaw["city"] as? String
      userSettings.country = userSettingsRaw["country"] as? String
      userSettings.region = userSettingsRaw["region"] as? String
      userSettings.notificationsEnabled = userSettingsRaw["notificationsEnabled"] as? Boolean

      (userSettingsRaw["textCustomFields"] as? Map<String, String>)?.forEach { (key, value) ->
        userSettings.setTextForCustomField(value, key)
      }

      // Date format in atomic_session.dart: dateTime.toUtc().toIso8601String();
      val dateCustomFields = userSettingsRaw["dateCustomFields"] as? Map<String, String>
      dateCustomFields?.forEach { (key, value) ->
        // Uses setTextForCustomField instead of setDateForCustomField to avoid Date libraries that
        // are incompatible with Android min version 21.
        userSettings.setTextForCustomField(value, key)
      }


      // e.g: notificationTimeframes = {monday=[{endHour=17, startHour=8, startMinute=0, endMinute=30}, {endHour=22, startHour=19, startMinute=0, endMinute=0}]}
      (userSettingsRaw["notificationTimeframes"] as? Map<String, List<Map<String, Int>>>)?.forEach { (key, value) ->
        var day = AACUserSettings.NotificationDays.default
        when (key) {
          "monday" -> day = AACUserSettings.NotificationDays.mon
          "tuesday" -> day = AACUserSettings.NotificationDays.tue
          "wednesday" -> day = AACUserSettings.NotificationDays.wed
          "thursday" -> day = AACUserSettings.NotificationDays.thu
          "friday" -> day = AACUserSettings.NotificationDays.fri
          "saturday" -> day = AACUserSettings.NotificationDays.sat
          "sunday" -> day = AACUserSettings.NotificationDays.sun
        }

        val timeFrames = ArrayList<AACUserNotificationTimeframe>()

        value.forEach { timeFrame ->
          timeFrames.add(AACUserNotificationTimeframe(timeFrame["startHour"]!!, timeFrame["startMinute"]!!, timeFrame["endHour"]!!, timeFrame["endMinute"]!!))
        }

        userSettings.setNotificationTime(timeFrames, day)
      }

      AACSDK.updateUser(userSettings) { sendUserSettingsResult ->
        when (sendUserSettingsResult) {
          is AACSDKSendUserSettingsResult.DataError -> {
            throw sendUserSettingsResult.error
          }

          is AACSDKSendUserSettingsResult.Success -> {
            result.success(true)
          }
        }
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
              ERROR_CODE_UPDATE_USER,
              e.message,
              "Failed to update user with the parsed AACUserSettings object."
      )
    }
  }

  private fun setSessionDelegate(result: Result) {
    if (flutterSessionDelegate == null) {
      flutterSessionDelegate = AACFlutterSessionDelegate()
    }
    flutterSessionDelegate?.clearAllRequests()
    AACSDK.setSessionDelegate {
      CoroutineScope(Dispatchers.Main + NonCancellable).launch {
        if(flutterSessionDelegate == null) {
          it(null)
        } else {
          val identifier = flutterSessionDelegate?.didRequestNewAuthenticationToken(it)
          if(identifier != null) {
            channel.invokeMethod("authTokenRequested", mapOf("identifier" to identifier))
          }
        }
      }
    }
    result.success(true)
  }

  private fun setClientAppVersion(call: MethodCall, result: Result) {
    val parameterNames =
      call.arguments.asListOfType<String>()
        ?: throw IllegalArgumentException("You must supply a version string when setting up the client App version")
    aacFlutterSDK.setClientAppVersion(parameterNames[0])
    result.success(true)
  }

  private fun didReceiveAuthenticationToken(call: MethodCall) {
    val parameters = call.arguments.asListOfType<String>() ?: throw IllegalArgumentException("You must supply a token and the linked identifier for the session delegate.")
    flutterSessionDelegate?.didReceiveAuthenticationToken(parameters[0], parameters[1])
  }

  private fun trackPushNotificationReceived(call: MethodCall, result: Result) {
    try {
      val parameters = call.arguments as ArrayList<*>
      val payloadRaw = (parameters[0] as Map<*, *>).asStringMapOfType<String>()
        ?: throw IllegalArgumentException("Notification payload was not in the expected format.")
      if (aacFlutterSDK.trackPushNotificationReceived(payloadRaw)) {
        result.success(true)
      } else {
        result.error(
          ERROR_CODE_TRACK_PUSH_NOTIFICATION,
          "Failed to convert push payload to an Atomic object.",
          "Failed to track received push notification."
        )
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_TRACK_PUSH_NOTIFICATION,
        e.message,
        "Failed to track received push notification."
      )
    }
  }

  private fun userMetrics(call: MethodCall, result: Result) {
    try {
      val parameters =
        call.arguments.asListOfType<String>()
          ?: throw IllegalArgumentException("You must supply a stream container ID and authentication token when requesting user metrics.")
      aacFlutterSDK.userMetrics(parameters[0], result)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(ERROR_CODE_USER_METRICS, e.message, "Failed to request user metrics.")
    }
  }

  private fun sendEvent(call: MethodCall, result: Result) {
    try {
      val parameters = call.arguments as ArrayList<*>
      val payloadRaw = (parameters[0] as Map<*, *>).asStringMap()
        ?: throw IllegalArgumentException("Event payload was not in the expected format.")
      val eventName = payloadRaw["name"] as? String
        ?: throw IllegalArgumentException("You must supply an event name when sending event.")
      AACEventPayload(eventName).apply {
        lifecycleId = payloadRaw["lifecycleId"] as? String
        payload.apply {
          payloadRaw["detail"]?.let {
            detail.putAll(
              (it as Map<*, *>).asStringMapOfType()
                ?: throw IllegalArgumentException("You must supply a string dictionary for the event payload.")
            )
          }
          payloadRaw["notificationDetail"]?.let {
            notificationDetail.putAll(
              (it as Map<*, *>).asStringMapOfType()
                ?: throw IllegalArgumentException("You must supply a string dictionary for the notification detail.")
            )
          }
          payloadRaw["metadata"]?.let {
            metadata.putAll(
              (it as Map<*, *>).asStringMapOfType()
                ?: throw IllegalArgumentException("You must supply a string dictionary for the event meta data.")
            )
          }
        }
      }.run {
        aacFlutterSDK.sendEvent(this, result)
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(ERROR_CODE_SEND_EVENT, e.message, "Failed to send event.")
    }
  }

  private fun requestCardCount(call: MethodCall, result: Result) {
    try {
      val parameters =
        (call.arguments as ArrayList<*>).asListOfType<String>()
          ?: throw IllegalArgumentException("You must supply a stream container ID and authentication token when requesting card count.")
      aacFlutterSDK.requestCardCountForStreamContainerWithIdentifier(parameters[0], result)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_REQUEST_CARD_COUNT, e.message,
        "Failed to request card count."
      )
    }
  }

  private fun setApiBaseUrl(call: MethodCall, result: Result) {
    try {
      val parameters =
        call.arguments.asListOfType<String>()
          ?: throw IllegalArgumentException("You must supply a valid URL when setting the API base URL.")
      result.success(aacFlutterSDK.setApiBaseUrl(parameters))
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_BASE_URL, e.message,
        "Failed to set API base URL. Check the base URL provided matches that specified in the Atomic Workbench."
      )
    }
  }

  private fun initialise(call: MethodCall, result: Result) {
    try {
      val parameters = call.arguments.asListOfType<String>() ?: throw IllegalArgumentException("You must supply a valid environment ID and API key when initialising the Atomic SDK.")
      result.success(aacFlutterSDK.initialise(parameters))
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_INITIALISE, e.message,
        "Failed to initialise SDK with provided environment ID and API key."
      )
    }
  }

  private fun enableDebugMode(call: MethodCall, result: Result) {
    try {
      val arguments =
        call.arguments.asListOfType<Int>()
          ?: throw IllegalArgumentException("You must provide an int value when setting the debug mode.")
      result.success(aacFlutterSDK.enableDebugMode(arguments))
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_LOGGING, e.message,
        "Failed to set logging enabled or disabled on the SDK."
      )
    }
  }

  private fun logout(result: Result) {
    try {
      flutterSessionDelegate = null
      aacFlutterSDK.logout(result)
    } catch (e: java.lang.Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_LOGOUT, e.message,
        "Failed to logout."
      )
    }
  }

  private fun registerDeviceForNotifications(call: MethodCall, result: Result) {
    try {
      val parameters = call.arguments.asListOfType<String>() ?: throw IllegalArgumentException("You must provide a device token when registering a device for push notifications.")
      aacFlutterSDK.registerDeviceForNotifications(parameters[0], result)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_REGISTER_DEVICE, e.message,
        "Failed to register device for notifications. Ensure you have provided a valid push token."
      )
    }
  }

  private fun registerStreamContainersForNotifications(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments.asListOfType<Any>()
        ?: throw IllegalArgumentException("Invalid call arguments for registering stream containers for notifications.")
      val streamContainerIds =
        arguments[0].asListOfType<String>() ?: throw IllegalArgumentException("You must provide an array of stream container IDs when registering stream containers for notifications.")
      aacFlutterSDK.registerStreamContainersForNotifications(streamContainerIds, result)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_REGISTER_STREAM, e.message,
        "Failed to register stream container for notifications. Ensure you have provided a valid array of container IDs."
      )
    }
  }

  private fun registerStreamContainersForNotificationsEnabled(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments.asListOfType<Any>()
        ?: throw IllegalArgumentException("Invalid call arguments for registering stream containers for notifications.")
      val streamContainerIds =
        arguments[0].asListOfType<String>() ?: throw IllegalArgumentException("You must provide an array of stream container IDs when registering stream containers for notifications.")
      val notificationEnabled = arguments[1] as Boolean
      aacFlutterSDK.registerStreamContainersForNotifications(streamContainerIds, result, notificationEnabled)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_REGISTER_STREAM, e.message,
        "Failed to register stream container for notifications. Ensure you have provided a valid array of container IDs."
      )
    }
  }

  private fun deregisterDeviceForNotifications(result: Result) {
    try {
      result.success(aacFlutterSDK.deregisterDeviceForNotifications(result))
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_DEREGISTER, e.message,
        "Failed to deregister device for notifications."
      )
    }
  }

  private fun notificationFromPushPayload(call: MethodCall, result: Result) {
    try {
      /// Legal structure of arguments: List<Map<String, String>>
      val payload = ((call.arguments as List<*>)[0] as Map<*, *>).asStringMapOfType<String>()
        ?: throw IllegalArgumentException("You must supply a push notification payload that will be parsed to an object.")
      result.success(aacFlutterSDK.notificationFromPushPayload(payload))
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_NOTIFICATION_PAYLOAD, e.message,
        "Failed to convert push payload to an Atomic object."
      )
    }
  }

  private fun observeCardCount(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as List<*>
      val containerId = arguments[0] as String
      val interval = arguments[1] as Int
      val filtersJsonList = (arguments[2] as List<*>).asListOfType<Map<String, *>>() ?: emptyList<Map<String, *>>()

      val identifier = aacFlutterSDK.observeCardCount(containerId, interval, filtersJsonList) { count, identifier ->
        channel.invokeMethod("cardCountChanged", mapOf("identifier" to identifier, "cardCount" to count))
      }
      result.success(identifier)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_CARD_COUNT, e.message,
        "Failed to observe card count."
      )
    }
  }

  private fun stopObservingCardCount(call: MethodCall, result: Result) {
    try {
      val identifier = (call.arguments as List<*>)[0] as String
      result.success(aacFlutterSDK.stopObservingCardCount(identifier))
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
        ERROR_CODE_STOP_CARD_COUNT, e.message,
        "Failed to stop observing card count."
      )
    }
  }

  private var streamContainerObserverContainers = HashMap<String, AACStreamContainer>()
  private fun observeStreamContainer(call: MethodCall, result: Result) {
    val args = call.arguments as List<*>
    val containerId = args[0] as String
    val configJson = args[1] as Map<String, *>
    val runtimeVariables = configJson["runtimeVariables"] as Map<String, String>?
    val runtimeVariableAnalytics = configJson["runtimeVariableAnalytics"] as Boolean
    val runtimeVariableResolutionTimeout = configJson["runtimeVariableResolutionTimeout"] as Int
    val filtersJsonList = configJson["filters"] as List<Map<String, *>>?
    val pollingInterval = configJson["pollingInterval"] as Int

    val container = AACStreamContainer.create(containerId)

    var identifier = ""
    identifier = aacFlutterSDK.observeStreamContainer(container, runtimeVariables, runtimeVariableAnalytics,
            runtimeVariableResolutionTimeout, filtersJsonList, pollingInterval) { cards ->

      val cardsJsonList : List<Map<String, Any?>>?
      if (cards == null) {
        cardsJsonList = null;
      }
      else {
        cardsJsonList  = ArrayList()
        cards.forEach { card ->
          Log.i("observeStreamContainer", "card title: ${card.metadata.title}")
          val moshi: Moshi = Moshi.Builder().build()
          val subviewsJson = HashMap<String, Any?>()
          card.subviews.forEach { (s, cardSubview) ->
            subviewsJson[s] = moshi.adapter(CardSubview::class.java).toJsonValue(cardSubview);
          }
          val cardJson = mapOf(
                  "instance" to moshi.adapter(CardIdentifier::class.java).toJsonValue(card.instance),
                  "actions" to moshi.adapter(CardActions::class.java).toJsonValue(card.actions),
                  "defaultView" to moshi.adapter(CardView::class.java).toJsonValue(card.defaultView),
                  "subviews" to subviewsJson,
                  "metadata" to moshi.adapter(CardMetadata::class.java).toJsonValue(card.metadata),
                  "runtimeVariables" to card.runtimeVariablesAsMap(),
          )
          cardsJsonList.add(cardJson)
        }
        //longLog("observeStreamContainer", "cardsJsonList: $cardsJsonList")
      }


      // The identifier is used here to call the Flutter callback
      CoroutineScope(Dispatchers.Main + NonCancellable).launch {
        channel.invokeMethod("onStreamContainerObserved", mapOf("identifier" to identifier, "cards" to cardsJsonList))
      }
    }
    streamContainerObserverContainers[identifier] = container
    container.startUpdates()
    // The identifier is used here to give to the user to stop the observer later.
    result.success(identifier)
  }

  private fun stopObservingStreamContainer(call: MethodCall, result: Result) {
    try {
      val identifier = (call.arguments as List<*>)[0] as String
      val container = streamContainerObserverContainers[identifier]
      if (container == null) {
        throw Exception("A container being observed with identifier ($identifier) can't be found.")
      }
      else {
        container.stopUpdates()
        result.success(AACSDK.stopObservingStreamContainer(identifier))
      }
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error( ERROR_CODE_STOP_OBSERVING_STREAM_CONTAINER, e.message, "Failed to stop observing the stream container.")
    }
  }

  private fun startObservingSDKEvents(call: MethodCall, result: Result) = try {
    AACSDK.observeSDKEvents { sdkEvent ->
      CoroutineScope(Dispatchers.Main + NonCancellable).launch {
        var cardContextJson : Map<String, String?>? = null;
        if (sdkEvent.cardContext != null) {
          cardContextJson = mapOf(
                  "cardInstanceId" to sdkEvent.cardContext!!.cardInstanceId,
                  "cardPresentation" to sdkEvent.cardContext!!.cardPresentation,
                  "cardInstanceStatus" to sdkEvent.cardContext!!.cardInstanceStatus,
                  "cardViewState" to sdkEvent.cardContext!!.cardViewState,
          );
        }

        var propertiesJson : Map<String, Any?>? = null;
        if (sdkEvent.properties != null) {
          var payload = sdkEvent.properties!!.payload
          var unsnooze : String? = null;
          payload?.forEach { (key, value) ->
            if (key == "unsnoozeISO8601") {
              unsnooze = value.toString();
              return@forEach
            }
          }
          // If the payload contains unsnooze, take it out of the payload and set the payload to null.
          if (unsnooze != null) {
            payload = null
          }

          var submittedValues : Map<String, Any>? = null;
          var redirectPayload : Map<String, Any>? = null;
          if (sdkEvent.eventName == AACEventName.UserRedirected) {
            redirectPayload = payload;
          }
          else if (sdkEvent.eventName == AACEventName.Submitted) {
            submittedValues = payload;
          }
          propertiesJson = mapOf(
                  "message" to sdkEvent.properties!!.message,
                  "linkMethod" to sdkEvent.properties!!.linkMethod,
                  "path" to sdkEvent.properties!!.path,
                  "reason" to sdkEvent.properties!!.reason,
                  "source" to sdkEvent.properties!!.source,
                  "subviewId" to sdkEvent.properties!!.subviewId,
                  "subviewTitle" to sdkEvent.properties!!.subviewTitle,
                  "url" to sdkEvent.properties!!.url,
                  "statusCode" to sdkEvent.properties!!.statusCode,
                  "subviewLevel" to sdkEvent.properties!!.subviewLevel,
                  "resolvedVariables" to sdkEvent.properties!!.resolvedVariables,
                  "unsnooze" to sdkEvent.properties!!.payload?.get("unsnoozeISO8601"),
                  "redirectPayload" to redirectPayload,
                  "submittedValues" to submittedValues,
          )
        }
        val containerId = sdkEvent.sdkContext.containerId
        var streamContextJson : Map<String, Any?>? = null;
        if (sdkEvent.streamContext != null) {
          streamContextJson = mapOf(
                  "streamLength" to sdkEvent.streamContext!!.streamLength,
                  "cardPositionInStream" to sdkEvent.streamContext!!.cardPositionInStream,
                  "streamLengthVisible" to sdkEvent.streamContext!!.streamLengthVisible,
                  "displayMode" to sdkEvent.streamContext!!.displayMode,
          );
        }
        val sdkEventJson = mapOf(
                "eventName" to sdkEvent.eventName.name,
                "timestamp" to sdkEvent.timestamp,
                "identifier" to sdkEvent.identifier,
                "userId" to sdkEvent.userId,
                "cardCount" to sdkEvent.cardCount,
                "cardContext" to cardContextJson,
                "properties" to propertiesJson,
                "containerId" to containerId,
                "streamContext" to streamContextJson,
        )
        channel.invokeMethod("onSDKEvent", mapOf("sdkEventJson" to sdkEventJson))
      }
    }
    result.success(true)
  }
  catch (e: Exception) {
    flutterLogger.error(e)
    result.error(
            ERROR_CODE_START_SDK_EVENTS, e.message,
            "Failed to start observing SDK events.")
  }

  private fun stopObservingSDKEvents(call: MethodCall, result: Result) {
    try {
      AACSDK.observeSDKEvents(null)
      result.success(true)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
              ERROR_CODE_STOP_SDK_EVENTS, e.message,
              "Failed to stop observing SDK events.")
    }
  }

  private fun executeCardAction(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as List<*>
      val containerId = arguments[0] as String
      val cardInstanceId = arguments[1] as String
      val actionType = arguments[2] as String
      val arg = arguments[3]

      aacFlutterSDK.executeCardAction(containerId, cardInstanceId, actionType, arg, result)
    } catch (e: Exception) {
      flutterLogger.error(e)
      result.error(
              ERROR_CODE_EXECUTE_CARD_ACTION, e.message,
              "Failed to execute card action."
      )
    }
  }

  companion object {
    const val SESSION_CHANNEL = "io.atomic.sdk.session"
    const val ERROR_CODE_BASE_URL = "0"
    const val ERROR_CODE_INITIALISE = "1"
    const val ERROR_CODE_LOGGING = "2"
    const val ERROR_CODE_LOGOUT = "3"
    const val ERROR_CODE_REGISTER_DEVICE = "4"
    const val ERROR_CODE_REGISTER_STREAM = "5"
    const val ERROR_CODE_DEREGISTER = "6"
    const val ERROR_CODE_CARD_COUNT = "7"
    const val ERROR_CODE_NOTIFICATION_PAYLOAD = "8"
    const val ERROR_CODE_STOP_CARD_COUNT = "9"
    const val ERROR_CODE_REQUEST_CARD_COUNT = "10"
    const val ERROR_CODE_SEND_EVENT = "11"
    const val ERROR_CODE_USER_METRICS = "12"
    const val ERROR_CODE_TRACK_PUSH_NOTIFICATION = "13"
    const val ERROR_CODE_UPDATE_USER = "14"
    const val ERROR_CODE_START_SDK_EVENTS = "15"
    const val ERROR_CODE_STOP_SDK_EVENTS = "16"
    const val ERROR_CODE_STOP_OBSERVING_STREAM_CONTAINER = "17"
    const val ERROR_CODE_EXECUTE_CARD_ACTION = "18"
  }
}
