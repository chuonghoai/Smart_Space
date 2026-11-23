package com.vn.smart_space.utils;

/**
 * Shared geographic coordinate validation and Haversine distance helpers.
 */
public final class GeoUtils {

    public static final double EARTH_RADIUS_METERS = 6371000.0;
    public static final double EARTH_RADIUS_KM = 6371.0;

    private GeoUtils() {
    }

    public static boolean isValidLatitude(Double value) {
        return value != null
                && !value.isNaN()
                && !value.isInfinite()
                && value >= -90.0
                && value <= 90.0;
    }

    public static boolean isValidLongitude(Double value) {
        return value != null
                && !value.isNaN()
                && !value.isInfinite()
                && value >= -180.0
                && value <= 180.0;
    }

    public static boolean isValidCoordinate(Double lat, Double lng) {
        return isValidLatitude(lat) && isValidLongitude(lng);
    }

    public static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                        * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(Math.max(0.0, 1.0 - a)));
        return EARTH_RADIUS_METERS * c;
    }

    public static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        return haversineMeters(lat1, lon1, lat2, lon2) / 1000.0;
    }
}
