import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:mobile_shared/features/news/application/news_providers.dart';
import 'package:mobile_shared/features/news/models/news_model.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/admin_overview_model.dart';
import 'package:smartspace_admin/features/home/models/recent_activity_model.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_model.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_admin/features/notifications/services/notification_service.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/home/admin_home_screen.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/news_card.dart';
import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';

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

class _MockAdminOverviewNotifier extends AdminOverviewNotifier {
  @override
  Future<AdminOverviewModel?> build() async {
    return const AdminOverviewModel(
      userCount: 120,
      staffCount: 15,
      adminCount: 3,
      issueCount: 45,
      pendingCount: 8,
      processingCount: 12,
      unsatisfactoryProcessedCount: 2,
    );
  }
}

class _MockRecentReportNotifier extends RecentReportNotifier {
  @override
  Future<List<RecentReportModel>> build(String arg) async {
    return [
      const RecentReportModel(
        id: 'rep-1',
        title: 'Tiêu đề ngắn có ảnh và có nhân viên',
        status: 'processing',
        imageUrl: 'https://example.com/img1.jpg',
        assignedStaffName: 'Nguyễn Văn A',
        createdAt: '2026-10-30T10:00:00Z',
      ),
      const RecentReportModel(
        id: 'rep-2',
        title: 'Tiêu đề dài hai dòng rất chi tiết về sự cố hạ tầng đường bộ ngập lụt nguy hiểm',
        status: 'processed',
        isAnonymous: true,
        createdAt: '2026-10-30T11:00:00Z',
      ),
      const RecentReportModel(
        id: 'rep-3',
        title: 'Phản ánh đang được yêu cầu xử lý lại',
        status: 'processing',
        isReviewResolved: false,
        createdAt: '2026-10-30T12:00:00Z',
      ),
    ];
  }
}

class _MockRecentActivityNotifier extends RecentActivityNotifier {
  @override
  Future<List<RecentActivityModel>> build() async {
    return [];
  }
}

void main() {
  group('Report Status Colors Tests', () {
    testWidgets('Processing color is Blue (Info) and distinctly different from Processed (Green)',
        (tester) async {
      late Color processingColorLight;
      late Color processedColorLight;
      late Color processingColorDark;
      late Color processedColorDark;

      // Verify Light mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Builder(
            builder: (context) {
              processingColorLight = reportStatusColor(context, 'processing');
              processedColorLight = reportStatusColor(context, 'processed');
              return const SizedBox();
            },
          ),
        ),
      );

      expect(processingColorLight, equals(AppSemanticColors.light.info));
      expect(processedColorLight, equals(AppSemanticColors.light.success));
      expect(processingColorLight != processedColorLight, isTrue);

      // Verify Dark mode using Theme widget
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Theme(
            data: AppTheme.darkTheme,
            child: Builder(
              builder: (context) {
                processingColorDark = reportStatusColor(context, 'processing');
                processedColorDark = reportStatusColor(context, 'processed');
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(processingColorDark, equals(AppSemanticColors.dark.info));
      expect(processedColorDark, equals(AppSemanticColors.dark.success));
      expect(processingColorDark != processedColorDark, isTrue);
    });
  });

  group('NewsCard Uniformity Tests', () {
    testWidgets('NewsCard with image has no content, without image fills with content, both are 338px',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final newsWithImage = NewsModel(
        id: 'news-1',
        title: 'Bản tin có hình ảnh',
        content: 'Nội dung chi tiết của bản tin có hình ảnh đính kèm không được hiện.',
        authorName: 'Admin',
        createdAt: DateTime.parse('2026-10-30T10:00:00Z'),
        imageUrls: const ['https://example.com/image.jpg'],
      );

      final newsWithoutImage = NewsModel(
        id: 'news-2',
        title: 'Bản tin không có hình ảnh',
        content: 'Nội dung của bài viết này được hiển thị để lấp đầy khoảng trống.',
        authorName: 'Admin',
        createdAt: DateTime.parse('2026-10-30T11:00:00Z'),
        imageUrls: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  NewsCard(news: newsWithImage, key: const Key('news_with_img'), margin: EdgeInsets.zero),
                  NewsCard(news: newsWithoutImage, key: const Key('news_without_img'), margin: EdgeInsets.zero),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizeWithImg = tester.getSize(find.byKey(const Key('news_with_img')));
      final sizeWithoutImg = tester.getSize(find.byKey(const Key('news_without_img')));

      // Both cards must have the exact same height: 338.0px
      expect(sizeWithImg.height, equals(sizeWithoutImg.height));
      expect(sizeWithImg.height, equals(338.0));

      // News with image MUST NOT show content text
      expect(
        find.text('Nội dung chi tiết của bản tin có hình ảnh đính kèm không được hiện.'),
        findsNothing,
      );

      // News without image MUST show content text to fill space
      expect(
        find.text('Nội dung của bài viết này được hiển thị để lấp đầy khoảng trống.'),
        findsOneWidget,
      );
    });
  });

  group('Recent Reports Card Uniformity Tests on AdminHomeScreen', () {
    testWidgets('All recent report cards on desktop and mobile have standard 120.0px height',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationProvider.overrideWith(
              (ref) => NotificationNotifier(
                const NotificationService(notificationRepo: _TestNotificationRepo()),
              ),
            ),
            adminOverviewProvider.overrideWith(() => _MockAdminOverviewNotifier()),
            pendingWithdrawalCountProvider.overrideWith((ref) => 0),
            recentReportProvider.overrideWith(() => _MockRecentReportNotifier()),
            recentActivityProvider.overrideWith(() => _MockRecentActivityNotifier()),
            latestNewsProvider.overrideWith((ref) => []),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify report titles are rendered
      expect(find.text('Tiêu đề ngắn có ảnh và có nhân viên'), findsOneWidget);
      expect(find.textContaining('Tiêu đề dài hai dòng rất chi tiết'), findsOneWidget);
      expect(find.text('Phản ánh đang được yêu cầu xử lý lại'), findsOneWidget);

      // Verify placeholder icon for report without image
      expect(find.byIcon(Icons.assignment_outlined), findsWidgets);

      // Verify unassigned staff placeholder text in Vietnamese
      expect(find.text('Chưa phân công'), findsWidgets);
    });
  });
}
