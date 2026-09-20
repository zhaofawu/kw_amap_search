package com.kw.kw_amap_search

import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.geocoder.AoiItem
import com.amap.api.services.geocoder.RegeocodeAddress
import com.amap.api.services.geocoder.RegeocodeRoad
import com.amap.api.services.geocoder.StreetNumber
import com.amap.api.services.road.Crossroad

internal object AmapRegeocodeMapper {
    fun toChannelMap(
        requestedLocation: LatLonPoint,
        address: RegeocodeAddress?,
        includeExtensions: Boolean
    ): Map<String, Any?> {
        return mapOf(
            "requestedLocation" to AmapPoiMapper.latLonPointMap(requestedLocation),
            "coordinateType" to "gcj02",
            "formattedAddress" to address?.formatAddress.orEmpty(),
            "addressComponent" to addressComponentMap(address),
            "pois" to if (includeExtensions) {
                AmapPoiMapper.toChannelList(address?.pois.orEmpty())
            } else {
                emptyList<Map<String, Any?>>()
            },
            "aois" to if (includeExtensions) {
                address?.aois.orEmpty().map(::aoiMap)
            } else {
                emptyList<Map<String, Any?>>()
            },
            "roads" to if (includeExtensions) {
                address?.roads.orEmpty().map(::roadMap)
            } else {
                emptyList<Map<String, Any?>>()
            },
            "roadIntersections" to if (includeExtensions) {
                address?.crossroads.orEmpty().map(::crossroadMap)
            } else {
                emptyList<Map<String, Any?>>()
            }
        )
    }

    private fun addressComponentMap(address: RegeocodeAddress?): Map<String, Any?>? {
        if (address == null) {
            return null
        }
        return mapOf(
            "country" to address.country.orEmpty(),
            "province" to address.province.orEmpty(),
            "city" to address.city.orEmpty(),
            "cityCode" to address.cityCode.orEmpty(),
            "district" to address.district.orEmpty(),
            "adCode" to address.adCode.orEmpty(),
            "township" to address.township.orEmpty(),
            "townCode" to address.towncode.orEmpty(),
            "neighborhood" to address.neighborhood.orEmpty(),
            "building" to address.building.orEmpty(),
            "streetNumber" to streetNumberMap(address.streetNumber)
        )
    }

    private fun streetNumberMap(streetNumber: StreetNumber?): Map<String, Any?>? {
        if (streetNumber == null) {
            return null
        }
        return mapOf(
            "street" to streetNumber.street.orEmpty(),
            "number" to streetNumber.number.orEmpty(),
            "location" to AmapPoiMapper.latLonPointMap(streetNumber.latLonPoint),
            "sdkDistanceMeters" to streetNumber.distance.toDouble(),
            "direction" to streetNumber.direction.orEmpty()
        )
    }

    private fun aoiMap(aoi: AoiItem): Map<String, Any?> {
        return mapOf(
            "id" to aoi.aoiId.orEmpty(),
            "name" to aoi.aoiName.orEmpty(),
            "adCode" to aoi.adCode.orEmpty(),
            "center" to AmapPoiMapper.latLonPointMap(aoi.aoiCenterPoint),
            "areaSquareMeters" to aoi.aoiArea?.toDouble(),
            "containsPoint" to null,
            "distanceToBoundaryMeters" to null
        )
    }

    private fun roadMap(road: RegeocodeRoad): Map<String, Any?> {
        return mapOf(
            "id" to road.id.orEmpty(),
            "name" to road.name.orEmpty(),
            "location" to AmapPoiMapper.latLonPointMap(road.latLngPoint),
            "sdkDistanceMeters" to road.distance.toDouble(),
            "direction" to road.direction.orEmpty()
        )
    }

    private fun crossroadMap(crossroad: Crossroad): Map<String, Any?> {
        return mapOf(
            "firstRoadId" to crossroad.firstRoadId.orEmpty(),
            "firstRoadName" to crossroad.firstRoadName.orEmpty(),
            "secondRoadId" to crossroad.secondRoadId.orEmpty(),
            "secondRoadName" to crossroad.secondRoadName.orEmpty(),
            "location" to AmapPoiMapper.latLonPointMap(crossroad.centerPoint),
            "sdkDistanceMeters" to crossroad.distance.toDouble(),
            "direction" to crossroad.direction.orEmpty()
        )
    }
}
