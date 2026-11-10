import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/news/application/news_providers.dart';
import 'package:mobile_shared/features/news/data/news_repository.dart';
import 'package:mobile_shared/features/news/models/news_model.dart';
import 'package:mobile_shared/features/news/models/news_page.dart';

typedef _Call = ({int page, int size, String? search, DateTime? from, DateTime? to});

/// Repo giả: ghi lại tham số; mỗi lần gọi trả về một Completer để test tự quyết thứ tự response.
class _FakeNewsRepository implements NewsRepository {
  final List<_Call> calls = [];
  final List<Completer<ApiResponse<NewsPage>>> pending = [];

  @override
  Future<ApiResponse<NewsPage>> getNews({int page = 1, int size = 10, String? search, DateTime? from, DateTime? to}) {
    calls.add((page: page, size: size, search: search, from: from, to: to));
    final completer = Completer<ApiResponse<NewsPage>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NewsModel _news(String id) => NewsModel(id: id, title: id, content: '');

ApiResponse<NewsPage> _page(List<String> ids, {int page = 1, int totalPages = 1, int? total}) => ApiResponse(
      success: true,
      message: 'ok',
      data: NewsPage(
        items: ids.map(_news).toList(),
        currentPage: page,
        totalPages: totalPages,
        totalElements: total ?? ids.length,
      ),
    );

void main() {
  late _FakeNewsRepository repo;
  late NewsListNotifier notifier;

  setUp(() {
    repo = _FakeNewsRepository();
    notifier = NewsListNotifier(repo);
  });

  tearDown(() => notifier.dispose());

  Future<void> respond(int index, ApiResponse<NewsPage> response) async {
    repo.pending[index].complete(response);
    await pumpEventQueue();
  }

  test('Mở màn hình: tải trang 1, không bộ lọc', () async {
    expect(notifier.state.isLoading, isTrue);
    await respond(0, _page(['a', 'b'], totalPages: 3, total: 25));

    final call = repo.calls.single;
    expect(call.page, 1);
    expect(call.size, NewsListNotifier.pageSize);
    expect(call.search, '');
    expect(call.from, isNull);
    expect(notifier.state.items.map((n) => n.id), ['a', 'b']);
    expect(notifier.state.hasMore, isTrue);
    expect(notifier.state.totalElements, 25);
    expect(notifier.state.isFiltering, isFalse);
  });

  test('Tải thêm: sang trang kế, nối vào danh sách, hết trang thì dừng', () async {
    await respond(0, _page(['a'], totalPages: 2));

    notifier.loadMore();
    notifier.loadMore(); // đang tải thì bỏ qua
    expect(repo.calls, hasLength(2));
    await respond(1, _page(['b'], page: 2, totalPages: 2));

    expect(repo.calls.last.page, 2);
    expect(notifier.state.items.map((n) => n.id), ['a', 'b']);
    expect(notifier.state.hasMore, isFalse);

    notifier.loadMore();
    expect(repo.calls, hasLength(2), reason: 'Không còn trang để tải');
  });

  test('Tải thêm lỗi: giữ danh sách cũ và báo lỗi riêng', () async {
    await respond(0, _page(['a'], totalPages: 2));
    notifier.loadMore();
    await respond(1, ApiResponse(success: false, message: 'mất mạng'));

    expect(notifier.state.items.map((n) => n.id), ['a']);
    expect(notifier.state.loadMoreError, 'mất mạng');
    expect(notifier.state.error, isNull);
    expect(notifier.state.hasMore, isTrue, reason: 'Vẫn cho thử tải lại');
  });

  testWidgets('Tìm kiếm: debounce, chỉ gọi 1 lần với từ khoá cuối đã trim', (tester) async {
    repo.pending[0].complete(_page([]));
    await tester.pump();

    notifier.setSearch('đèn');
    await tester.pump(const Duration(milliseconds: 100));
    notifier.setSearch('  đèn đường ');
    await tester.pump(const Duration(milliseconds: 299));
    expect(repo.calls, hasLength(1), reason: 'Chưa hết thời gian debounce');

    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.calls, hasLength(2));
    expect(repo.calls.last.search, 'đèn đường');
    expect(repo.calls.last.page, 1);
    expect(notifier.state.isFiltering, isTrue);
    repo.pending[1].complete(_page([]));
    await tester.pump();
  });

  test('Lọc theo ngày: bỏ giờ, đảo nếu ngược; chọn lại đúng khoảng cũ thì không gọi API', () async {
    await respond(0, _page([]));

    notifier.setDateRange(DateTime(2026, 3, 15, 18, 30), DateTime(2026, 3, 1, 7));
    await respond(1, _page([]));

    final call = repo.calls.last;
    expect(call.from, DateTime(2026, 3, 1));
    expect(call.to, DateTime(2026, 3, 15));

    notifier.setDateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 15));
    expect(repo.calls, hasLength(2));
  });

  test('Response của bộ lọc cũ về muộn bị bỏ qua', () async {
    notifier.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31)); // lần gọi đầu chưa trả về

    await respond(1, _page(['new']));
    await respond(0, _page(['old']));

    expect(notifier.state.items.map((n) => n.id), ['new']);
    expect(notifier.state.isLoading, isFalse);
  });

  test('Trang tải thêm của bộ lọc cũ không bị nối vào danh sách mới', () async {
    await respond(0, _page(['a'], totalPages: 2));

    notifier.loadMore(); // lần gọi 1, chưa trả về
    notifier.setDateRange(DateTime(2026, 2, 1), DateTime(2026, 2, 1)); // lần gọi 2
    await respond(2, _page(['fresh']));
    await respond(1, _page(['stale'], page: 2, totalPages: 2));

    expect(notifier.state.items.map((n) => n.id), ['fresh']);
  });

  test('Lỗi trang đầu: danh sách trống và có thông báo lỗi', () async {
    await respond(0, ApiResponse(success: false, message: 'Lỗi máy chủ'));

    expect(notifier.state.items, isEmpty);
    expect(notifier.state.error, 'Lỗi máy chủ');
    expect(notifier.state.isLoading, isFalse);
  });

  test('Xoá lọc: về mặc định; không lọc gì thì không gọi lại API', () async {
    await respond(0, _page([]));
    notifier.setDateRange(DateTime(2026, 4, 1), DateTime(2026, 4, 2));
    await respond(1, _page([]));

    notifier.clearFilters();
    await respond(2, _page([]));

    final call = repo.calls.last;
    expect(call.search, '');
    expect(call.from, isNull);
    expect(call.to, isNull);
    expect(notifier.state.isFiltering, isFalse);

    notifier.clearFilters();
    expect(repo.calls, hasLength(3));
  });
}
