import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/news/staff_news_list_screen.dart';

/// Repo giả: trả về [responder] cho mỗi lần gọi và ghi lại từ khoá.
class _FakeNewsRepository implements NewsRepository {
  final ApiResponse<NewsPage> Function(String? search) responder;
  final List<String?> searches = [];

  _FakeNewsRepository(this.responder);

  @override
  Future<ApiResponse<NewsPage>> getNews({int page = 1, int size = 10, String? search, DateTime? from, DateTime? to}) async {
    searches.add(search);
    return responder(search);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ApiResponse<NewsPage> _page(int count) => ApiResponse(
      success: true,
      message: 'ok',
      data: NewsPage(
        items: [for (var i = 0; i < count; i++) NewsModel(id: 'n$i', title: 'Tin số $i', content: 'Nội dung $i')],
        currentPage: 1,
        totalPages: count == 0 ? 0 : 1,
        totalElements: count,
      ),
    );

Future<void> _pump(WidgetTester tester, _FakeNewsRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [newsListProvider.overrideWith((ref) => NewsListNotifier(repo))],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: [...AppLocalizations.localizationsDelegates, SharedLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StaffNewsListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Đã tải: ô tìm kiếm và nút lịch cùng một hàng, dòng meta nêu tổng số tin', (tester) async {
    await _pump(tester, _FakeNewsRepository((_) => _page(2)));

    expect(find.text('2 tin tức'), findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsNothing, reason: 'Không lọc gì thì không có nút xoá lọc');
    expect(find.byTooltip('Lọc theo ngày'), findsOneWidget);

    final searchY = tester.getCenter(find.byType(TextField)).dy;
    final dateY = tester.getCenter(find.byType(DateFilterIconButton)).dy;
    expect((searchY - dateY).abs(), lessThan(1), reason: 'Bộ lọc gọn trong một hàng');
  });

  testWidgets('Lỗi tải: câu L10n + Thử lại, không lộ lỗi kỹ thuật', (tester) async {
    await _pump(
      tester,
      _FakeNewsRepository((_) => ApiResponse(success: false, message: 'DioException [connection error]: boom')),
    );

    expect(find.text('Không tải được tin tức.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);
  });

  testWidgets('Tìm không ra: nêu đúng từ khoá; Xoá bộ lọc làm trống ô tìm kiếm và tải lại', (tester) async {
    final repo = _FakeNewsRepository((search) => search == null || search.isEmpty ? _page(3) : _page(0));
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'đèn đường');
    await tester.pump(const Duration(milliseconds: 300)); // debounce
    await tester.pumpAndSettle();

    expect(find.text('Không có tin nào khớp “đèn đường”'), findsOneWidget);
    expect(find.text('0 tin tức'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc').last);
    await tester.pumpAndSettle();

    expect(find.text('3 tin tức'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(repo.searches.last, '');
  });
}
