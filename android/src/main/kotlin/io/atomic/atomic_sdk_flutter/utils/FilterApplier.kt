package io.atomic.atomic_sdk_flutter.utils

import android.content.Context
import androidx.fragment.app.FragmentManager
import com.atomic.actioncards.feed.feature.filter.AACCardFilterValue
import com.atomic.actioncards.feed.feature.filter.AACCardListFilter
import com.atomic.actioncards.sdk.AACStreamContainer

class FilterApplier(private val context : Context) {
    private fun tryParseFilterFromName(filterName : String, filterValues : List<AACCardFilterValue>) : AACCardListFilter? {
        when (filterName) {
            "equalTo" -> {
                return AACCardListFilter.equalTo(filterValues.first())
            }

            "notEqualTo" -> {
                return AACCardListFilter.notEqualTo(filterValues.first())
            }

            "greaterThan" -> {
                return AACCardListFilter.greaterThan(filterValues.first())
            }

            "greaterThanOrEqualTo" -> {
                return AACCardListFilter.greaterThanOrEqualTo(filterValues.first())
            }

            "lessThan" -> {
                return AACCardListFilter.lessThan(filterValues.first())
            }

            "lessThanOrEqualTo" -> {
                return AACCardListFilter.lessThanOrEqualTo(filterValues.first())
            }

            "contains" -> {
                return AACCardListFilter.contains(filterValues)
            }

            "notIn" -> {
                return AACCardListFilter.notIn(filterValues)
            }

            "between" -> {
                return AACCardListFilter.between(filterValues)
            }
        }
        return null
    }

    private fun tryParseFilterValue(rawOperator : String, rawValue : Any?) : AACCardFilterValue? {
        when(rawOperator) {
            "byPriority" -> {
                return (rawValue as? Int)?.let { AACCardFilterValue.byPriority(it) }
            }

            "byCreatedDate" -> {
                val date = (rawValue as? String)?.let { tryParseDate(context.resources.configuration, it) }
                return date?.let { AACCardFilterValue.byCardCreated(it) }
            }

            "byCardTemplateId" -> {
                return (rawValue as? String)?.let { AACCardFilterValue.byCardTemplateId(it) }
            }

            "byCardTemplateName" -> {
                return (rawValue as? String)?.let { AACCardFilterValue.byCardTemplateName(it) }
            }

            "byVariableName" -> {
                val customVar = rawValue as? Map<String, *> // e.g {customStringVar=stringValue}
                customVar?.firstNotNullOfOrNull { (name, value) ->
                    if (value != null) {
                        (value as? String)?.let {
                            tryParseDate(context.resources.configuration, it)?.let {
                                parsedDate -> return AACCardFilterValue.byVariableName(name, parsedDate)
                            }
                        }

                        return AACCardFilterValue.byVariableName(name, value)
                    }
                }
                return null
            }

            else -> return null;
        }
    }

    private fun tryParseFilterFromJson(filterName : String, filterValueJson : Any?) : AACCardListFilter? {
        val filterValues = ArrayList<AACCardFilterValue>()

        // If it's a filter that uses 1 value, for example: filter: equalTo={byPriority=4}
        (filterValueJson as? Map<String, *>)?.firstNotNullOfOrNull {  (rawOperator, rawValue) ->
            tryParseFilterValue(rawOperator, rawValue)?.let { filterValues.add(it) }
        }

        // OR

        // If it's a filter that uses multiple values, for example: filter: notIn=[{byPriority=1}, {byPriority=5}]
        (filterValueJson as? List<Map<String, *>>)?.forEach { rawFilter ->
            rawFilter.firstNotNullOfOrNull { (rawOperator, rawValue) ->
                tryParseFilterValue(rawOperator, rawValue)?.let { filterValues.add(it) }
            }
        }
        if (filterValues.isEmpty()) {
            return null
        }

        return tryParseFilterFromName(filterName, filterValues)
    }

    /// If fragmentManager is set to null, it won't check for the ByCardInstanceId legacy filter, which is the only filter that requires a fragment.
    internal fun tryApplyFiltersFromJson(filtersJsonList : List<Map<String, *>>, container : AACStreamContainer, fragmentManager: FragmentManager? = null) {
        val filters = ArrayList<AACCardListFilter>()
        filtersJsonList.forEach { filterJson ->
            filterJson.forEach fJ@ { (filterName, rawValue) ->
                if (fragmentManager != null && filterName == "byCardInstanceId") {
                    container.filterCardsById(fragmentManager, rawValue as String)
                }
                else {
                    tryParseFilterFromJson(filterName, rawValue)?.let { filters.add(it) }
                }
            }
        }
        container.applyFilter(filters)
    }
}