package com.kw.kw_amap_search

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.poisearch.PoiSearch
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import org.mockito.ArgumentCaptor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

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
    fun nearby_validatesCoordinates_andPassesZeroAndSortToSdk() = withHandler { handler, searches, _ ->
        val invalid = mockResult()
        handler.searchAround(aroundCall(latitude = 91.0), invalid)
        Mockito.verify(invalid).error(Mockito.eq("invalid_argument"), Mockito.anyString(), Mockito.isNull())
        assertEquals(0, searches.size)

        val result = mockResult()
        handler.searchAround(aroundCall(), result)
        val search = searches.single()
        Mockito.verify(search).searchPOIAsyn()
        val bound = ArgumentCaptor.forClass(PoiSearch.SearchBound::class.java)
        Mockito.verify(search).setBound(bound.capture())
        assertEquals(0.0, bound.value.center.latitude)
        assertEquals(300, bound.value.range)
        assertEquals(true, bound.value.isDistanceSort)
        assertEquals("060000", search.query.category)
        assertEquals(25, search.query.pageSize)
        assertEquals(2, search.query.pageNum)
        listener(search).onPoiSearched(null, 1000)
        Mockito.verify(result).success(emptyList<Map<String, Any?>>())
        Mockito.verifyNoMoreInteractions(result)
    }

    @Test
    fun cancelAndTimeout_ignoreOldCallbacksWhenIdIsReused() = withHandler { handler, searches, timer ->
        val first = mockResult()
        handler.searchAround(aroundCall(), first)
        val firstListener = listener(searches[0])

        val duplicate = mockResult()
        handler.searchAround(aroundCall(), duplicate)
        Mockito.verify(duplicate).error(Mockito.eq("duplicate_request_id"), Mockito.anyString(), Mockito.any())
        assertEquals(1, searches.size)

        val cancelled = mockResult()
        handler.cancelRequest(MethodCall("cancelRequest", mapOf("requestId" to "same-id")), cancelled)
        Mockito.verify(cancelled).success(true)
        Mockito.verify(first).error(Mockito.eq("cancelled"), Mockito.anyString(), Mockito.any())
        Mockito.verify(searches[0]).setOnPoiSearchListener(null)

        val second = mockResult()
        handler.searchAround(aroundCall(), second)
        val secondListener = listener(searches[1])
        firstListener.onPoiSearched(null, 1000)

        val timeouts = ArgumentCaptor.forClass(Runnable::class.java)
        Mockito.verify(timer, Mockito.times(2)).postDelayed(timeouts.capture(), Mockito.anyLong())
        timeouts.allValues[1].run()
        Mockito.verify(second).error(Mockito.eq("timeout"), Mockito.anyString(), Mockito.any())

        val third = mockResult()
        handler.searchAround(aroundCall(), third)
        timeouts.allValues[0].run()
        secondListener.onPoiSearched(null, 1000)
        listener(searches[2]).onPoiSearched(null, 1000)
        Mockito.verify(third).success(emptyList<Map<String, Any?>>())

        val ended = mockResult()
        handler.cancelRequest(MethodCall("cancelRequest", mapOf("requestId" to "same-id")), ended)
        Mockito.verify(ended).success(false)
        Mockito.verify(timer, Mockito.times(3)).removeCallbacks(Mockito.any())
        Mockito.verifyNoMoreInteractions(first, second, third)
    }

    @Test
    fun dispose_finishesPendingRequestsAndIgnoresLateCallbacks() = withHandler { handler, searches, _ ->
        val result = mockResult()
        handler.searchAround(aroundCall(), result)
        val callback = listener(searches.single())
        handler.dispose()
        callback.onPoiSearched(null, 1000)
        Mockito.verify(result).error(Mockito.eq("cancelled"), Mockito.anyString(), Mockito.any())
        Mockito.verifyNoMoreInteractions(result)
    }

    @Test
    fun poiMapper_preservesUnknownZeroAndKeywordDistanceSemantics() {
        val poi = PoiItem("sample", LatLonPoint(0.0, 0.0), "sample", "")
        assertEquals(-1, poi.distance)
        assertNull(AmapPoiMapper.toChannelList(listOf(poi)).single()["sdkDistanceMeters"])
        poi.distance = 0
        assertEquals(0.0, AmapPoiMapper.toChannelList(listOf(poi)).single()["sdkDistanceMeters"])
        assertNull(AmapPoiMapper.toChannelList(listOf(poi), false).single()["sdkDistanceMeters"])
    }

    private fun aroundCall(latitude: Double = 0.0) = MethodCall("searchAround", mapOf(
        "requestId" to "same-id", "latitude" to latitude, "longitude" to 121.4737,
        "types" to "060000", "pageSize" to 25, "pageNum" to 2,
        "radius" to 300, "sortRule" to "distance", "timeoutMs" to 1000
    ))

    private fun mockResult() = Mockito.mock(MethodChannel.Result::class.java)

    private fun listener(search: PoiSearch): PoiSearch.OnPoiSearchListener {
        val capture = ArgumentCaptor.forClass(PoiSearch.OnPoiSearchListener::class.java)
        Mockito.verify(search).setOnPoiSearchListener(capture.capture())
        return capture.value
    }

    private fun withHandler(test: (AmapSearchHandler, List<PoiSearch>, Handler) -> Unit) {
        Mockito.mockStatic(Looper::class.java).use {
            Mockito.mockConstruction(Handler::class.java).use { timers ->
                Mockito.mockConstruction(PoiSearch::class.java) { search, context ->
                    Mockito.`when`(search.query).thenReturn(context.arguments()[1] as PoiSearch.Query)
                }.use { searches ->
                    val handler = AmapSearchHandler(Mockito.mock(Context::class.java))
                    try {
                        test(handler, searches.constructed(), timers.constructed().single())
                    } finally {
                        handler.dispose()
                    }
                }
            }
        }
    }
}
