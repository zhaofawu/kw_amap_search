package com.kw.kw_amap_search

import android.content.Context
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.core.ServiceSettings
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class AmapSearchHandler(private val context: Context) {
    fun setApiKey(call: MethodCall, result: MethodChannel.Result) {
        call.argument<String>("androidKey")
            ?.takeIf { it.isNotBlank() }
            ?.let { ServiceSettings.getInstance().setApiKey(it) }
        result.success(null)
    }

    fun updatePrivacyShow(call: MethodCall, result: MethodChannel.Result) {
        val hasContains = call.argument<Boolean>("hasContains") ?: false
        val hasShow = call.argument<Boolean>("hasShow") ?: false
        ServiceSettings.updatePrivacyShow(context, hasContains, hasShow)
        result.success(null)
    }

    fun updatePrivacyAgree(call: MethodCall, result: MethodChannel.Result) {
        val hasAgree = call.argument<Boolean>("hasAgree") ?: false
        ServiceSettings.updatePrivacyAgree(context, hasAgree)
        result.success(null)
    }

    fun searchKeyword(call: MethodCall, result: MethodChannel.Result) {
        runSearch(result) {
            PoiSearch(context, createQuery(call))
        }
    }

    fun searchAround(call: MethodCall, result: MethodChannel.Result) {
        val latitude = call.argument<Double>("latitude") ?: 0.0
        val longitude = call.argument<Double>("longitude") ?: 0.0
        val radius = call.argument<Int>("radius") ?: DEFAULT_RADIUS_METERS

        // The legacy Android plugin treated a missing/zero coordinate as "no
        // nearby search can be performed" and returned an empty list without
        // touching the AMap SDK. Keep that behavior so existing callers that
        // pass placeholder coordinates do not suddenly receive SDK errors.
        if (latitude == 0.0 || longitude == 0.0) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        runSearch(result) {
            PoiSearch(context, createQuery(call)).apply {
                bound = PoiSearch.SearchBound(
                    LatLonPoint(latitude, longitude),
                    radius.coerceIn(MIN_RADIUS_METERS, MAX_RADIUS_METERS)
                )
            }
        }
    }

    @Throws(AMapException::class)
    private fun createQuery(call: MethodCall): PoiSearch.Query {
        val keyword = call.argument<String>("keyword") ?: ""
        val city = call.argument<String>("city") ?: ""
        val types = call.argument<String>("types") ?: ""
        val pageSize = call.argument<Int>("pageSize") ?: DEFAULT_PAGE_SIZE
        val pageNum = call.argument<Int>("pageNum") ?: DEFAULT_PAGE_NUM

        return PoiSearch.Query(keyword, types, city).apply {
            this.pageSize = pageSize
            this.pageNum = pageNum
        }
    }

    private fun runSearch(
        result: MethodChannel.Result,
        searchFactory: () -> PoiSearch
    ) {
        try {
            val poiSearch = searchFactory()
            poiSearch.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
                override fun onPoiSearched(poiResult: PoiResult?, errorCode: Int) {
                    // AMap uses 1000 as success across Android and iOS SDKs. Any
                    // other code is a real SDK failure and must not be collapsed
                    // into an empty result list.
                    if (errorCode != AMAP_SUCCESS_CODE) {
                        result.error(
                            "AMAP_SEARCH_ERROR",
                            "AMap POI search failed with code $errorCode",
                            mapOf("errorCode" to errorCode)
                        )
                        return
                    }

                    val pois = poiResult?.pois
                    if (pois.isNullOrEmpty()) {
                        result.success(emptyList<Map<String, Any?>>())
                    } else {
                        result.success(AmapPoiMapper.toChannelList(pois))
                    }
                }

                override fun onPoiItemSearched(poiItem: PoiItem?, errorCode: Int) = Unit
            })
            poiSearch.searchPOIAsyn()
        } catch (exception: AMapException) {
            result.error(
                "AMAP_SEARCH_ERROR",
                exception.message,
                mapOf("errorCode" to exception.errorCode)
            )
        } catch (exception: RuntimeException) {
            result.error("AMAP_SEARCH_ERROR", exception.message, null)
        }
    }

    private companion object {
        const val AMAP_SUCCESS_CODE = 1000
        const val DEFAULT_PAGE_SIZE = 20
        const val DEFAULT_PAGE_NUM = 1
        const val DEFAULT_RADIUS_METERS = 1000
        const val MIN_RADIUS_METERS = 1
        const val MAX_RADIUS_METERS = 50000
    }
}
