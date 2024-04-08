package io.atomic.atomic_sdk_flutter.helpers

import java.util.UUID

typealias SessionDelegateCallback = (String?) -> Unit

private class AACFlutterSessionDelegateResolutionRequest(val handler: SessionDelegateCallback) {
  val identifier = UUID.randomUUID().toString()
}

class AACFlutterSessionDelegate {
  private var sessionDelegateRequests = mutableMapOf<String, AACFlutterSessionDelegateResolutionRequest>()
  fun didReceiveAuthenticationToken(token: String, identifier: String) {
    val handler = sessionDelegateRequests[identifier]?.handler ?: return
    handler(token)
    sessionDelegateRequests.remove(identifier)
  }

  fun didRequestNewAuthenticationToken(callback: SessionDelegateCallback): String {
    val request = AACFlutterSessionDelegateResolutionRequest(callback)
    sessionDelegateRequests[request.identifier] = request
    return request.identifier
  }

  fun clearAllRequests() {
    sessionDelegateRequests.clear()
  }
}