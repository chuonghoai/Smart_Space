import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:mobile_shared/features/news/data/news_repository.dart';
import 'package:mobile_shared/features/news/models/news_page.dart';
import 'package:smartspace_admin/features/news/application/news_providers.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_model.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_admin/features/notifications/services/notification_service.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_detail_model.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/news/admin_news_list_screen.dart';
import 'package:smartspace_admin/ui/screen/notifications/admin_notification_screen.dart';
import 'package:smartspace_admin/ui/screen/reports/admin_report_detail_screen.dart';
import 'package:smartspace_admin/ui/screen/search/search_screen.dart';

class _TestNotificationRepo implements NotificationRepo {
  const _TestNotificationRepo();

  @override
  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    return ApiResponse(
      success: true,
      message: 'OK',
      data: NotificationCountModel(notifNumber: 0),
    );
  }

  @override
  Future<ApiResponse<List<NotificationModel>>> getMyNotifications(
      {int page = 0, int size = 20}) async {
    return ApiResponse(success: true, message: 'OK', data: []);
  }

  @override
  Future<ApiResponse<void>> markAllAsRead() async {
    return ApiResponse(success: true, message: 'OK');
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    return ApiResponse(success: true, message: 'OK');
  }
}

class _MockStaffsNotifier extends StaffsNotifier {
  @override
  Future<List<StaffModel>> build() async {
    return [];
  }
}

class _MockReportDetailNotifier extends ReportDetailNotifier {
  final ReportDetailModel model;
  _MockReportDetailNotifier(this.model);

  @override
  Future<ReportDetailModel> build(String arg) async {
    return model;
  }
}

/// Repo tin tức giả: luôn trả về trang rỗng.
class _EmptyNewsRepository implements NewsRepository {
  @override
  Future<ApiResponse<NewsPage>> getNews({int page = 1, int size = 10, String? search, DateTime? from, DateTime? to}) async {
    return ApiResponse(
      success: true,
      message: 'ok',
      data: const NewsPage(items: [], currentPage: 1, totalPages: 0, totalElements: 0),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({
  required Widget child,
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      notificationProvider.overrideWith(
        (ref) => NotificationNotifier(
          const NotificationService(notificationRepo: _TestNotificationRepo()),
        ),
      ),
      staffsProvider.overrideWith(() => _MockStaffsNotifier()),
      ...extraOverrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLayout bottomNavigationBar Tests', () {
    testWidgets('renders bottomNavigationBar in Mobile layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const AppLayout(
            bottomNavigationBar: Text('BottomBarTest'),
            child: Text('ContentTest'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BottomBarTest'), findsOneWidget);
      expect(find.text('ContentTest'), findsOneWidget);
    });
  });

  group('AdminSearchScreen Tests', () {
    testWidgets('renders correctly on Mobile size (arrow_back, search TextField, and results)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const AdminSearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('AdminNewsListScreen Tests', () {
    testWidgets('renders news management header and create button on Mobile view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          extraOverrides: [
            newsListProvider.overrideWith((ref) => NewsListNotifier(_EmptyNewsRepository())),
          ],
          child: const AdminNewsListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quản lý tin tức'), findsOneWidget);
      expect(find.byIcon(Icons.post_add), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });

  group('AdminReportDetailScreen Tests', () {
    testWidgets('renders correctly on Mobile view (keeping original mobile scaffold & aspect ratios)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockReport = ReportDetailModel(
        id: 'rep-001',
        title: 'Bóng đèn hành lang bị cháy',
        description: 'Bóng đèn tầng 2 dãy A không sáng',
        status: 'PENDING',
        severity: 'LOW',
        images: ['https://example.com/lamp.jpg'],
        isAnonymous: false,
        createdAt: DateTime(2026, 11, 1, 8, 0),
        updatedAt: DateTime(2026, 11, 1, 8, 0),
      );

      await tester.pumpWidget(
        _buildTestApp(
          extraOverrides: [
            reportDetailProvider.overrideWith(
              () => _MockReportDetailNotifier(mockReport),
            ),
          ],
          child: const AdminReportDetailScreen(reportId: 'rep-001'),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile view retains AppBar with title
      expect(find.text('Chi tiết phản ánh'), findsOneWidget);
      expect(find.text('Bóng đèn hành lang bị cháy'), findsOneWidget);
      // Retains AspectRatio(16/9) on mobile
      expect(find.byType(AspectRatio), findsWidgets);
    });

    testWidgets('renders report info without overflow on small screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockReport = ReportDetailModel(
        id: 'rep-002',
        title: 'Báo cáo sự cố rò rỉ nước tại khu vực nhà vệ sinh tầng 3',
        description: 'Nước tràn ra sàn gây trơn trượt',
        status: 'PENDING',
        severity: 'HIGH',
        images: [],
        isAnonymous: false,
        createdAt: DateTime(2026, 11, 1, 14, 30),
        updatedAt: DateTime(2026, 11, 1, 14, 30),
      );

      await tester.pumpWidget(
        _buildTestApp(
          extraOverrides: [
            reportDetailProvider.overrideWith(
              () => _MockReportDetailNotifier(mockReport),
            ),
          ],
          child: const AdminReportDetailScreen(reportId: 'rep-002'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo sự cố rò rỉ nước tại khu vực nhà vệ sinh tầng 3'), findsOneWidget);
    });
  });

  group('AdminNotificationScreen Tests', () {
    testWidgets('renders notification screen on Mobile view (retains mobile layout & actions)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const AdminNotificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
