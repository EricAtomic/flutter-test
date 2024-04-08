package io.atomic.atomic_sdk_flutter.utils

import org.json.JSONArray
import org.json.JSONObject

/**
 * Extension function to support a JsonObject conversion into a Map
 * Following https://stackoverflow.com/a/64002903/1476228
 */
fun JSONObject.toMap(): Map<String, *> = keys().asSequence().associateWith { key ->
  when (val value = this[key]) {
    is JSONArray -> {
      val map = (0 until value.length()).associate { Pair(it.toString(), value[it]) }
      JSONObject(map).toMap().values.toList()
    }
    is JSONObject -> value.toMap()
    JSONObject.NULL -> null
    else -> value
  }
}

/**
 * Converters to convert a general collection to a specified one.
 * Following https://kotlinlang.org/docs/typecasts.html#unchecked-casts
 */

inline fun  <reified T> Any.asListOfType(): ArrayList<T>? = (this as? List<*>)?.asListOfType()

inline fun <reified T> ArrayList<*>.asListOfType(): ArrayList<T>? =
  if (all { it is T })
    @Suppress("UNCHECKED_CAST")
    this as ArrayList<T> else
    null

inline fun <reified T> List<*>.asListOfType(): ArrayList<T>? =
  if(all { it is T}) {
          val list = arrayListOf<T>()
    @Suppress("UNCHECKED_CAST")
    list.addAll(this as List<T>)
    list
  } else null


fun Map<*, *>.asStringMap(): Map<String, *>? =
  if (all { it.key is String })
    @Suppress("UNCHECKED_CAST")
    this as Map<String, *> else null

inline fun <reified T> Map<*, *>.asStringMapOfType(): Map<String, T>? =
  if (all { it.key is String && it.value is T })
    @Suppress("UNCHECKED_CAST")
    this as Map<String, T> else null