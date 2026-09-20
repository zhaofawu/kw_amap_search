package com.kw.kw_amap_search

import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem

/**
 * Converts Android AMap POI objects into the shared Flutter channel schema.
 *
 * The map keys intentionally keep the first plugin version's names (`poiId`,
 * `title`, `snippet`, etc.). Dart now exposes a cleaner immutable model on top
 * of this payload, while old apps can still parse the legacy keys.
 */
internal object AmapPoiMapper {
    fun toChannelList(poiItems: List<PoiItem>, includeDistance: Boolean = true): List<Map<String, Any?>> {
        return poiItems.map { toChannelMap(it, includeDistance) }
    }

    private fun toChannelMap(poiItem: PoiItem, includeDistance: Boolean): Map<String, Any?> {
        val distance = poiItem.distance.takeIf { includeDistance && it >= 0 }
        return mapOf(
            "adCode" to poiItem.adCode.orEmpty(),
            "adName" to poiItem.adName.orEmpty(),
            "cityName" to poiItem.cityName.orEmpty(),
            "cityCode" to poiItem.cityCode.orEmpty(),
            "indoorData" to mapOf(
                "floor" to (poiItem.indoorData?.floor ?: 0),
                "floorName" to poiItem.indoorData?.floorName.orEmpty(),
                "poiId" to poiItem.indoorData?.poiId.orEmpty()
            ),
            "businessArea" to poiItem.businessArea.orEmpty(),
            "direction" to poiItem.direction.orEmpty(),
            "distance" to distance,
            "sdkDistanceMeters" to distance?.toDouble(),
            "email" to poiItem.email.orEmpty(),
            "enter" to latLonPointMap(poiItem.enter),
            "exit" to latLonPointMap(poiItem.exit),
            "isIndoorMap" to poiItem.isIndoorMap,
            "latLonPoint" to latLonPointMap(poiItem.latLonPoint),
            "parkingType" to poiItem.parkingType.orEmpty(),
            "photos" to poiItem.photos.orEmpty().map {
                mapOf(
                    "title" to it.title.orEmpty(),
                    "url" to it.url.orEmpty()
                )
            },
            "poiExtension" to mapOf(
                "openTime" to poiItem.poiExtension?.opentime.orEmpty()
            ),
            "poiId" to poiItem.poiId.orEmpty(),
            "postcode" to poiItem.postcode.orEmpty(),
            "provinceCode" to poiItem.provinceCode.orEmpty(),
            "provinceName" to poiItem.provinceName.orEmpty(),
            "shopID" to poiItem.shopID.orEmpty(),
            "snippet" to poiItem.snippet.orEmpty(),
            "subPois" to poiItem.subPois.orEmpty().map {
                mapOf(
                    "title" to it.title.orEmpty(),
                    "snippet" to it.snippet.orEmpty(),
                    "subTypeDes" to it.subTypeDes.orEmpty(),
                    "distance" to it.distance.takeIf { distance -> distance >= 0 },
                    "sdkDistanceMeters" to it.distance.takeIf { distance -> distance >= 0 }?.toDouble(),
                    "poiId" to it.poiId.orEmpty(),
                    "subName" to it.subName.orEmpty(),
                    "subLatLonPoint" to latLonPointMap(it.latLonPoint)
                )
            },
            "tel" to poiItem.tel.orEmpty(),
            "title" to poiItem.title.orEmpty(),
            "typeCode" to poiItem.typeCode.orEmpty(),
            "typeDes" to poiItem.typeDes.orEmpty(),
            "website" to poiItem.website.orEmpty()
        )
    }

    internal fun latLonPointMap(point: LatLonPoint?): Map<String, Double>? {
        if (point == null) {
            return null
        }
        return mapOf(
            "latitude" to point.latitude,
            "longitude" to point.longitude
        )
    }
}
