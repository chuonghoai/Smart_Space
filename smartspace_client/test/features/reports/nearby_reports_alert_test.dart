import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/nearby_reports_alert_model.dart';
import 'package:smartspace_client/features/reports/presentation/widgets/nearby_reports_alert_modal.dart';
import 'package:smartspace_client/features/reports/providers/nearby_reports_alert_provider.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';
import 'package:smartspace_client/features/notifications/services/notification_router.dart';

class _FakeReportRepo implements ReportRepo {
  NearbyReportsAlertResponse responseToReturn;
  double? lastRequestedLat;
  double? lastRequestedLng;
  double? lastRequestedRadius;

  _FakeReportRepo({required this.responseToReturn});

  @override
  Future<ApiResponse<NearbyReportsAlertResponse>> getNearbyAlerts({
    required double lat,
    required double lng,
    double radius = 200.0,
    bool notify = true,
  }) async {
    lastRequestedLat = lat;
    lastRequestedLng = lng;
    lastRequestedRadius = radius;
    return ApiResponse(
      success: true,
      message: 'OK',
      data: responseToReturn,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleReports = [
    NearbyReportItemModel(
      id: 'rep-1',
      title: 'Hố ga mất nắp nguy hiểm',
      description: 'Hố ga sâu gần ngã tư đường D1',
      imageUrls: ['https://example.com/img1.jpg'],
      latitude: 10.8501,
      longitude: 106.7721,
      status: 'pending',
      severity: 'high',
      distanceInMeters: 45.2,
      createdAt: DateTime.now(),
    ),
    NearbyReportItemModel(
      id: 'rep-2',
      title: 'Đèn đường chiếu sáng bị chập',
      description: 'Cột đèn số 12 chớp nháy liên tục',
      imageUrls: ['https://example.com/img2.jpg'],
      latitude: 10.8508,
      longitude: 106.7725,
      status: 'processing',
      severity: 'medium',
      distanceInMeters: 120.0,
      createdAt: DateTime.now(),
    ),
  ];

  final alertData = NearbyReportsAlertResponse(
    count: 2,
    nearestDistance: 45.2,
    reports: sampleReports,
  );

  group('Nearby Reports Alert - Scheduled & Logic Tests', () {
    test('checkNearbyReportsAlert triggers API with radius 200m and updates state', () async {
      final fakeRepo = _FakeReportRepo(responseToReturn: alertData);
      final service = ReportService(reportRepo: fakeRepo);

      final notifier = NearbyReportsAlertNotifier(service);

      final customPos = Position(
        latitude: 10.8500,
        longitude: 106.7720,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final result = await notifier.checkNearbyReportsAlert(
        customPosition: customPos,
        forceShow: true,
      );

      expect(result, isNotNull);
      expect(result!.count, 2);
      expect(result.reports.length, 2);
      expect(fakeRepo.lastRequestedLat, 10.8500);
      expect(fakeRepo.lastRequestedLng, 106.7720);
      expect(fakeRepo.lastRequestedRadius, 200.0);

      expect(notifier.state.lastAlert, isNotNull);
      expect(notifier.state.lastAlertedReportIds, containsAll(['rep-1', 'rep-2']));
    });

    test('checkNearbyReportsAlert with forceShow=true succeeds and returns alert even when report IDs are identical', () async {
      final fakeRepo = _FakeReportRepo(responseToReturn: alertData);
      final service = ReportService(reportRepo: fakeRepo);
      final notifier = NearbyReportsAlertNotifier(service);

      final customPos = Position(
        latitude: 10.8500,
        longitude: 106.7720,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      // First run: sets lastAlertedReportIds
      await notifier.checkNearbyReportsAlert(customPosition: customPos, forceShow: true);
      expect(notifier.state.lastAlertedReportIds, containsAll(['rep-1', 'rep-2']));

      // Second run (simulating periodic schedule interval): forceShow=true must still alert successfully
      final secondResult = await notifier.checkNearbyReportsAlert(
        customPosition: customPos,
        forceShow: true,
      );

      expect(secondResult, isNotNull);
      expect(secondResult!.count, 2);
    });
  });

  group('NearbyReportsAlertModal Widget Tests', () {
    testWidgets('Renders modal header, report cards, distance, and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi')],
          home: Scaffold(
            body: Builder(
              builder: (context) => NearbyReportsAlertModal(alertData: alertData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header title contains count
      expect(find.textContaining('2 phản ánh'), findsOneWidget);

      // Check close button "X" is present
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Check first report title and distance
      expect(find.text('Hố ga mất nắp nguy hiểm'), findsOneWidget);
      expect(find.textContaining('45m'), findsOneWidget);

      // Check counter indicator 1/2 is present
      expect(find.text('1/2'), findsOneWidget);

      // Check slider navigation buttons are present
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);

      // Tap Next button to slide to next report
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Check counter updated to 2/2 and second report title is visible
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('Đèn đường chiếu sáng bị chập'), findsOneWidget);

      // Check "Xem chi tiết" button is present
      expect(find.text('Xem chi tiết'), findsOneWidget);

      // Check "Đã hiểu" bottom button is present
      expect(find.text('Đã hiểu'), findsOneWidget);
    });

    testWidgets('Tapping "Đã hiểu" dismisses modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi')],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => NearbyReportsAlertModal.show(context, alertData),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Đã hiểu'), findsOneWidget);

      // Tap "Đã hiểu"
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();

      // Modal dismissed
      expect(find.text('Đã hiểu'), findsNothing);
    });

    testWidgets('Tapping "X" button dismisses modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi')],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => NearbyReportsAlertModal.show(context, alertData),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap "X"
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Modal dismissed
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('Preemption: calling NearbyReportsAlertModal.show replaces old modal with new alertData', (tester) async {
      final secondAlertData = NearbyReportsAlertResponse(
        count: 1,
        nearestDistance: 20.0,
        reports: [
          NearbyReportItemModel(
            id: 'rep-new',
            title: 'Sự cố mới khẩn cấp',
            description: 'Mô tả khẩn cấp',
            latitude: 10.8505,
            longitude: 106.7723,
            status: 'pending',
            severity: 'high',
            distanceInMeters: 20.0,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi')],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => NearbyReportsAlertModal.show(context, alertData),
                      child: const Text('Open First Modal'),
                    ),
                    ElevatedButton(
                      onPressed: () => NearbyReportsAlertModal.show(context, secondAlertData),
                      child: const Text('Open Second Modal'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Open first modal
      await tester.tap(find.text('Open First Modal'));
      await tester.pumpAndSettle();
      expect(find.text('Hố ga mất nắp nguy hiểm'), findsOneWidget);

      // Trigger second modal directly (simulating timer or push notification arrival)
      final BuildContext scaffoldContext = tester.element(find.byType(Scaffold));
      NearbyReportsAlertModal.show(scaffoldContext, secondAlertData);
      await tester.pumpAndSettle();

      // Second modal is now displayed with updated alert data
      expect(find.text('Sự cố mới khẩn cấp'), findsOneWidget);
    });
  });

  group('NotificationRouter NEARBY_REPORTS_ALERT navigation', () {
    testWidgets('Tapping NEARBY_REPORTS_ALERT action navigates to nearest report detail', (tester) async {
      String? navigatedLocation;
      final router = GoRouter(
        navigatorKey: sharedNavigatorKey,
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
          GoRoute(
            path: '/reports/:id',
            builder: (context, state) {
              navigatedLocation = state.uri.toString();
              return Scaffold(body: Text('Report Detail ${state.pathParameters['id']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final action = NotificationAction(
        type: 'NEARBY_REPORTS_ALERT',
        payload: {
          'count': 2,
          'nearestDistance': 15.5,
          'nearestReportId': 'rep-test-999',
        },
      );

      NotificationRouter.handleAction(action);
      await tester.pumpAndSettle();

      expect(navigatedLocation, '/reports/rep-test-999');
      expect(find.text('Report Detail rep-test-999'), findsOneWidget);
    });
  });
}
