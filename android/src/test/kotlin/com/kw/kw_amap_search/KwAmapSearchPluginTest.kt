package com.kw.kw_amap_search

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class KwAmapSearchPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = KwAmapSearchPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun searchAround_withZeroCoordinate_returnsEmptyList() {
        val handler = AmapSearchHandler(Mockito.mock(Context::class.java))
        val call = MethodCall(
            "searchAround",
            mapOf(
                "latitude" to 0.0,
                "longitude" to 121.4737,
                "keyword" to "coffee",
                "city" to "Shanghai",
                "types" to "",
                "pageSize" to 20,
                "pageNum" to 1,
                "radius" to 1000
            )
        )
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        handler.searchAround(call, mockResult)

        Mockito.verify(mockResult).success(emptyList<Map<String, Any?>>())
        Mockito.verifyNoMoreInteractions(mockResult)
    }
}
