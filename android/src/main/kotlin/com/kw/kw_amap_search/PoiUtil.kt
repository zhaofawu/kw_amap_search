package com.kw.kw_amap_search

import com.amap.api.services.core.PoiItem

object PoiUtil {
    fun handlePoiResult(poiItems: List<PoiItem>): List<Map<String, Any?>> {
        return poiItems.map { poiItem ->
            mapOf(
                "adCode" to poiItem.adCode,
                "adName" to poiItem.adName,
                "cityName" to poiItem.cityName,
                "cityCode" to poiItem.cityCode,
                "indoorData" to mapOf(
                    "floor" to (poiItem.indoorData?.floor ?: 0),
                    "floorName" to (poiItem.indoorData?.floorName ?: ""),
                    "poiId" to (poiItem.indoorData?.poiId ?: "")
                ),
                "businessArea" to poiItem.businessArea,
                "direction" to poiItem.direction,
                "distance" to poiItem.distance,
                "email" to poiItem.email,
                "enter" to latLonPointMap(poiItem.enter),
                "exit" to latLonPointMap(poiItem.exit),
                "isIndoorMap" to poiItem.isIndoorMap,
                "latLonPoint" to latLonPointMap(poiItem.latLonPoint),
                "parkingType" to poiItem.parkingType,
                "photos" to poiItem.photos.orEmpty().map {
                    mapOf(
                        "title" to it.title,
                        "url" to it.url
                    )
                },
                "poiExtension" to mapOf(
                    "openTime" to (poiItem.poiExtension?.opentime ?: "")
                ),
                "poiId" to poiItem.poiId,
                "postcode" to poiItem.postcode,
                "provinceCode" to poiItem.provinceCode,
                "provinceName" to poiItem.provinceName,
                "shopID" to poiItem.shopID,
                "snippet" to poiItem.snippet,
                "subPois" to poiItem.subPois.orEmpty().map {
                    mapOf(
                        "title" to it.title,
                        "snippet" to it.snippet,
                        "subTypeDes" to it.subTypeDes,
                        "distance" to it.distance,
                        "poiId" to it.poiId,
                        "subName" to it.subName,
                        "subLatLonPoint" to latLonPointMap(it.latLonPoint)
                    )
                },
                "tel" to poiItem.tel,
                "title" to poiItem.title,
                "typeCode" to poiItem.typeCode,
                "typeDes" to poiItem.typeDes,
                "website" to poiItem.website
            )
        }
    }

    private fun latLonPointMap(point: com.amap.api.services.core.LatLonPoint?): Map<String, Double> {
        return mapOf(
            "latitude" to (point?.latitude ?: 0.0),
            "longitude" to (point?.longitude ?: 0.0)
        )
    }
}
