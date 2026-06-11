package com.kw.kw_amap_search

import android.content.Context
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.core.ServiceSettings
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class KwAmapSearchPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kw_amap_search")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "setApiKey" -> setApiKey(call, result)
            "updatePrivacyShow" -> updatePrivacyShow(call, result)
            "updatePrivacyAgree" -> updatePrivacyAgree(call, result)
            "searchKeyword" -> searchKeyword(call, result)
            "searchAround" -> searchAround(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun setApiKey(call: MethodCall, result: Result) {
        call.argument<String>("androidKey")
            ?.takeIf { it.isNotBlank() }
            ?.let { ServiceSettings.getInstance().setApiKey(it) }
        result.success(null)
    }

    private fun updatePrivacyShow(call: MethodCall, result: Result) {
        val hasContains = call.argument<Boolean>("hasContains") ?: false
        val hasShow = call.argument<Boolean>("hasShow") ?: false
        ServiceSettings.updatePrivacyShow(context, hasContains, hasShow)
        result.success(null)
    }

    private fun updatePrivacyAgree(call: MethodCall, result: Result) {
        val hasAgree = call.argument<Boolean>("hasAgree") ?: false
        ServiceSettings.updatePrivacyAgree(context, hasAgree)
        result.success(null)
    }

    private fun searchKeyword(call: MethodCall, result: Result) {
        runSearch(result) {
            val query = createQuery(call)
            PoiSearch(context, query)
        }
    }

    private fun searchAround(call: MethodCall, result: Result) {
        val latitude = call.argument<Double>("latitude") ?: 0.0
        val longitude = call.argument<Double>("longitude") ?: 0.0
        if (latitude == 0.0 || longitude == 0.0) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        runSearch(result) {
            val query = createQuery(call)
            PoiSearch(context, query).apply {
                bound = PoiSearch.SearchBound(LatLonPoint(latitude, longitude), 1000)
            }
        }
    }

    @Throws(AMapException::class)
    private fun createQuery(call: MethodCall): PoiSearch.Query {
        val keyword = call.argument<String>("keyword") ?: ""
        val city = call.argument<String>("city") ?: ""
        val types = call.argument<String>("types") ?: ""
        val pageSize = call.argument<Int>("pageSize") ?: 20
        val pageNum = call.argument<Int>("pageNum") ?: 1

        return PoiSearch.Query(keyword, types, city).apply {
            this.pageSize = pageSize
            this.pageNum = pageNum
        }
    }

    private fun runSearch(result: Result, searchFactory: () -> PoiSearch) {
        try {
            val poiSearch = searchFactory()
            poiSearch.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
                override fun onPoiSearched(poiResult: PoiResult?, errorCode: Int) {
                    val pois = poiResult?.pois
                    if (pois.isNullOrEmpty()) {
                        result.success(emptyList<Map<String, Any?>>())
                    } else {
                        result.success(PoiUtil.handlePoiResult(pois))
                    }
                }

                override fun onPoiItemSearched(poiItem: PoiItem?, errorCode: Int) = Unit
            })
            poiSearch.searchPOIAsyn()
        } catch (exception: AMapException) {
            result.error("AMAP_SEARCH_ERROR", exception.message, null)
        } catch (exception: RuntimeException) {
            result.error("AMAP_SEARCH_ERROR", exception.message, null)
        }
    }
}
