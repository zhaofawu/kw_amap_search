package com.kw.kw_amap_search

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.core.ServiceSettings
import com.amap.api.services.geocoder.GeocodeAddress
import com.amap.api.services.geocoder.GeocodeResult
import com.amap.api.services.geocoder.GeocodeSearch
import com.amap.api.services.geocoder.RegeocodeQuery
import com.amap.api.services.geocoder.RegeocodeResult
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

internal class AmapSearchHandler(private val context: Context) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingRequests = mutableMapOf<String, PendingRequest>()
    private var disposed = false

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
        val keyword = call.argument<String>("keyword")?.trim().orEmpty()
        if (keyword.isEmpty()) {
            invalidArgument(result, "keyword must not be empty.")
            return
        }
        val request = registerRequest(call, result, "searchKeyword") ?: return
        runPoiSearch(request) {
            PoiSearch(context, createQuery(call, keyword))
        }
    }

    fun searchAround(call: MethodCall, result: MethodChannel.Result) {
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")
        if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
            invalidArgument(result, "center must be finite latitude/longitude.")
            return
        }
        val radius = call.argument<Int>("radius") ?: DEFAULT_RADIUS_METERS
        if (radius !in MIN_RADIUS_METERS..MAX_RADIUS_METERS) {
            invalidArgument(result, "radius must be 1..50000 meters.")
            return
        }
        val distanceSort = when (call.argument<String>("sortRule") ?: "distance") {
            "distance" -> true
            "comprehensive" -> false
            else -> {
                invalidArgument(result, "sortRule must be distance or comprehensive.")
                return
            }
        }
        val center = LatLonPoint(latitude!!, longitude!!)
        val request = registerRequest(call, result, "searchAround") ?: return
        runPoiSearch(request) {
            PoiSearch(context, createQuery(call, call.argument<String>("keyword")?.trim().orEmpty())).apply {
                query.setDistanceSort(distanceSort)
                bound = PoiSearch.SearchBound(center, radius, distanceSort)
            }
        }
    }

    fun reverseGeocode(call: MethodCall, result: MethodChannel.Result) {
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")
        if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
            invalidArgument(result, "point must be finite latitude/longitude.")
            return
        }
        val radius = call.argument<Int>("radius") ?: DEFAULT_REGEOCODE_RADIUS_METERS
        if (radius !in MIN_RADIUS_METERS..MAX_REGEOCODE_RADIUS_METERS) {
            invalidArgument(result, "radius must be 1..3000 meters.")
            return
        }

        val includeExtensions = call.argument<Boolean>("includeExtensions") ?: true
        val point = LatLonPoint(latitude!!, longitude!!)
        val query = RegeocodeQuery(point, radius.toFloat(), GeocodeSearch.AMAP).apply {
            setExtensions(
                if (includeExtensions) {
                    GeocodeSearch.EXTENSIONS_ALL
                } else {
                    GeocodeSearch.EXTENSIONS_BASE
                }
            )
        }
        val request = registerRequest(call, result, "reverseGeocode") ?: return
        try {
            val geocodeSearch = GeocodeSearch(context)
            request.nativeRequest = geocodeSearch
            geocodeSearch.setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
                override fun onRegeocodeSearched(regeocodeResult: RegeocodeResult?, errorCode: Int) {
                    if (errorCode != AMAP_SUCCESS_CODE) {
                        completeError(
                            request,
                            "sdk_error",
                            "AMap reverse geocode failed with code $errorCode",
                            mapOf("nativeCode" to errorCode, "platform" to "android")
                        )
                        return
                    }
                    completeSuccess(
                        request,
                        AmapRegeocodeMapper.toChannelMap(
                            point,
                            regeocodeResult?.regeocodeAddress,
                            includeExtensions
                        )
                    )
                }

                override fun onGeocodeSearched(geocodeResult: GeocodeResult?, errorCode: Int) = Unit
            })
            geocodeSearch.getFromLocationAsyn(query)
        } catch (exception: AMapException) {
            completeAmapException(request, exception)
        } catch (exception: RuntimeException) {
            completeError(request, "sdk_error", exception.message, null)
        }
    }

    fun cancelRequest(call: MethodCall, result: MethodChannel.Result) {
        val requestId = call.argument<String>("requestId")?.trim().orEmpty()
        val request = pendingRequests[requestId]
        if (request == null) {
            result.success(false)
            return
        }
        completeError(
            request,
            "cancelled",
            "AMap search request was cancelled.",
            mapOf("requestId" to request.id, "operation" to request.operation)
        )
        result.success(true)
    }

    fun dispose() {
        disposed = true
        val requests = pendingRequests.values.toList()
        requests.forEach {
            completeError(
                it,
                "cancelled",
                "AMap search handler was disposed.",
                mapOf("requestId" to it.id, "operation" to it.operation)
            )
        }
    }

    @Throws(AMapException::class)
    private fun createQuery(call: MethodCall, keyword: String): PoiSearch.Query {
        val city = call.argument<String>("city") ?: ""
        val types = call.argument<String>("types") ?: ""
        val pageSize = call.argument<Int>("pageSize") ?: DEFAULT_PAGE_SIZE
        val pageNum = call.argument<Int>("pageNum") ?: DEFAULT_PAGE_NUM
        if (pageSize !in 1..25 || pageNum < 1) {
            throw IllegalArgumentException("pageSize must be 1..25 and pageNum must be >= 1.")
        }

        return PoiSearch.Query(keyword, types, city).apply {
            this.pageSize = pageSize
            this.pageNum = pageNum
        }
    }

    private fun runPoiSearch(
        request: PendingRequest,
        searchFactory: () -> PoiSearch
    ) {
        try {
            val poiSearch = searchFactory()
            request.nativeRequest = poiSearch
            poiSearch.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
                override fun onPoiSearched(poiResult: PoiResult?, errorCode: Int) {
                    if (errorCode != AMAP_SUCCESS_CODE) {
                        completeError(
                            request,
                            "sdk_error",
                            "AMap POI search failed with code $errorCode",
                            mapOf("nativeCode" to errorCode, "platform" to "android")
                        )
                        return
                    }

                    val pois = poiResult?.pois
                    completeSuccess(
                        request,
                        if (pois.isNullOrEmpty()) {
                            emptyList<Map<String, Any?>>()
                        } else {
                            AmapPoiMapper.toChannelList(pois, request.operation != "searchKeyword")
                        }
                    )
                }

                override fun onPoiItemSearched(poiItem: PoiItem?, errorCode: Int) = Unit
            })
            poiSearch.searchPOIAsyn()
        } catch (exception: AMapException) {
            completeAmapException(request, exception)
        } catch (exception: IllegalArgumentException) {
            completeError(request, "invalid_argument", exception.message, null)
        } catch (exception: RuntimeException) {
            completeError(request, "sdk_error", exception.message, null)
        }
    }

    private fun registerRequest(
        call: MethodCall,
        result: MethodChannel.Result,
        operation: String
    ): PendingRequest? {
        if (disposed) {
            result.error("cancelled", "AMap search handler was disposed.", null)
            return null
        }
        val requestId = call.argument<String>("requestId")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "android-${UUID.randomUUID()}"
        if (pendingRequests.containsKey(requestId)) {
            result.error(
                "duplicate_request_id",
                "AMap requestId is already active.",
                mapOf("requestId" to requestId, "operation" to operation)
            )
            return null
        }

        val timeoutMs = call.argument<Int>("timeoutMs") ?: DEFAULT_TIMEOUT_MS
        if (timeoutMs <= 0) {
            invalidArgument(result, "timeoutMs must be positive.")
            return null
        }
        val request = PendingRequest(requestId, operation, result)
        request.timeoutRunnable = Runnable {
            completeError(
                request,
                "timeout",
                "AMap search request timed out.",
                mapOf("requestId" to requestId, "operation" to operation)
            )
        }
        pendingRequests[requestId] = request
        mainHandler.postDelayed(request.timeoutRunnable, timeoutMs.toLong())
        return request
    }

    private fun completeAmapException(request: PendingRequest, exception: AMapException) {
        completeError(
            request,
            "sdk_error",
            exception.message,
            mapOf(
                "nativeCode" to exception.errorCode,
                "requestId" to request.id,
                "operation" to request.operation,
                "platform" to "android"
            )
        )
    }

    private fun completeSuccess(request: PendingRequest, value: Any?) {
        if (!finish(request)) {
            return
        }
        request.result.success(value)
    }

    private fun completeError(
        request: PendingRequest,
        code: String,
        message: String?,
        details: Any?
    ) {
        if (!finish(request)) {
            return
        }
        request.result.error(code, message, details)
    }

    private fun finish(request: PendingRequest): Boolean {
        if (pendingRequests[request.id] !== request) {
            return false
        }
        pendingRequests.remove(request.id)
        mainHandler.removeCallbacks(request.timeoutRunnable)
        when (val nativeRequest = request.nativeRequest) {
            is PoiSearch -> nativeRequest.setOnPoiSearchListener(null)
            is GeocodeSearch -> nativeRequest.setOnGeocodeSearchListener(null)
        }
        request.nativeRequest = null
        return true
    }

    private fun invalidArgument(result: MethodChannel.Result, message: String) {
        result.error("invalid_argument", message, null)
    }

    private fun isValidLatitude(value: Double?): Boolean {
        return value != null && value.isFinite() && value >= -90.0 && value <= 90.0
    }

    private fun isValidLongitude(value: Double?): Boolean {
        return value != null && value.isFinite() && value >= -180.0 && value <= 180.0
    }

    private class PendingRequest(
        val id: String,
        val operation: String,
        val result: MethodChannel.Result
    ) {
        lateinit var timeoutRunnable: Runnable
        var nativeRequest: Any? = null
    }

    private companion object {
        const val AMAP_SUCCESS_CODE = 1000
        const val DEFAULT_PAGE_SIZE = 20
        const val DEFAULT_PAGE_NUM = 1
        const val DEFAULT_RADIUS_METERS = 1000
        const val DEFAULT_REGEOCODE_RADIUS_METERS = 300
        const val DEFAULT_TIMEOUT_MS = 10000
        const val MIN_RADIUS_METERS = 1
        const val MAX_RADIUS_METERS = 50000
        const val MAX_REGEOCODE_RADIUS_METERS = 3000
    }
}
