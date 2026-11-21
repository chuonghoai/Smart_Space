import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspace_staff/main.dart';

import 'helpers/firebase_test_mock.dart';

void main() {
  setUpAll(() async {
    await setupFirebaseTestMocks();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage.init(AppScope.staff);
    dotenv.loadFromString(
      envString: 'PORT=8989\nGOOGLE_CLIENT_ID=\nMAPBOX_ACCESS_TOKEN=\n',
      isOptional: true,
    );
  });

  tearDownAll(() {
    tearDownFirebaseTestMocks();
  });

  // Test Case ID: SMP-163
  // Description: Smoke test khởi chạy SmartSpaceStaffApp() với test-only Firebase mock, kiểm tra render MaterialApp không phát sinh FirebaseException.
  testWidgets('SmartSpaceStaffApp khởi chạy với Firebase test mock không phát sinh lỗi', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SmartSpaceStaffApp()),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
