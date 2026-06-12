package com.kw.kw_amap_search

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class KwAmapSearchPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var searchHandler: AmapSearchHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kw_amap_search")
        channel.setMethodCallHandler(this)
        searchHandler = AmapSearchHandler(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "setApiKey" -> searchHandler.setApiKey(call, result)
            "updatePrivacyShow" -> searchHandler.updatePrivacyShow(call, result)
            "updatePrivacyAgree" -> searchHandler.updatePrivacyAgree(call, result)
            "searchKeyword" -> searchHandler.searchKeyword(call, result)
            "searchAround" -> searchHandler.searchAround(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
