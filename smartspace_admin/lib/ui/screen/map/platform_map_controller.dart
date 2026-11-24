abstract class PlatformMapController {
  Future<void> flyToUserLocation();
  Future<void> flyToCoordinate(double lat, double lng, {double zoom = 16.0});
  Future<void> refreshViewport();
}

