import 'package:mobile_shared/features/map/models/map_bounds.dart';

/// Một lần tải dữ liệu theo khung nhìn.
/// [bounds] là khung thực sự gửi lên server (đã mở rộng so với [viewport]).
class ViewportRequest {
  final int id;
  final MapBounds viewport;
  final MapBounds bounds;

  const ViewportRequest._(this.id, this.viewport, this.bounds);
}

/// Quyết định khi nào cần tải lại dữ liệu bản đồ theo khung nhìn (dùng chung Client/Admin).
///
/// - Tải khung rộng hơn màn hình ([prefetchFactor]) để kéo nhẹ không phải tải lại.
/// - Bỏ qua khi khung mới nằm trọn trong vùng đã tải, dữ liệu còn mới và không bị cắt bớt.
/// - Bỏ qua khi đúng khung vừa yêu cầu (map idle lặp lại sau render) → tránh vòng lặp request.
/// - Chỉ response của request mới nhất được chấp nhận ([isCurrent]).
class ViewportLoadGate {
  final double prefetchFactor;
  final Duration freshness;
  final DateTime Function() _now;

  int _requestId = 0;
  MapBounds? _lastViewport;
  MapBounds? _lastRequestedViewport;
  DateTime? _lastRequestedAt;
  MapBounds? _fetchedBounds;
  DateTime? _fetchedAt;
  bool _truncated = false;
  bool _hasError = false;

  ViewportLoadGate({
    this.prefetchFactor = 1.5,
    this.freshness = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Khung nhìn gần nhất được báo về (dùng cho refresh).
  MapBounds? get lastViewport => _lastViewport;

  /// Trả về request cần thực hiện, hoặc null nếu không cần tải.
  ViewportRequest? begin(MapBounds viewport, {bool force = false}) {
    _lastViewport = viewport;
    if (!force && (_isCovered(viewport) || _isRepeatRequest(viewport))) return null;

    _lastRequestedViewport = viewport;
    _lastRequestedAt = _now();
    return ViewportRequest._(++_requestId, viewport, viewport.expandBy(prefetchFactor));
  }

  bool isCurrent(ViewportRequest request) => request.id == _requestId;

  void succeed(ViewportRequest request, {required bool truncated}) {
    if (!isCurrent(request)) return;
    _fetchedBounds = request.bounds;
    _fetchedAt = _now();
    _truncated = truncated;
    _hasError = false;
  }

  void fail(ViewportRequest request) {
    if (!isCurrent(request)) return;
    _hasError = true;
  }

  /// Dữ liệu đã tải không còn đúng (vd. đổi bộ lọc) → lần sau luôn tải lại.
  void invalidate() {
    _fetchedBounds = null;
    _fetchedAt = null;
    _lastRequestedViewport = null;
    _lastRequestedAt = null;
    _truncated = false;
    _hasError = false;
  }

  bool _isFresh(DateTime? time) => time != null && _now().difference(time) < freshness;

  bool _isCovered(MapBounds viewport) {
    final fetched = _fetchedBounds;
    return fetched != null &&
        !_hasError &&
        !_truncated &&
        _isFresh(_fetchedAt) &&
        fetched.contains(viewport);
  }

  /// Lỗi thì cho phép thử lại cùng khung.
  bool _isRepeatRequest(MapBounds viewport) =>
      !_hasError && viewport == _lastRequestedViewport && _isFresh(_lastRequestedAt);
}
