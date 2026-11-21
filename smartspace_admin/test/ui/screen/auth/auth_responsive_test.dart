import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/auth/forgot_password/forgot_password_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/login/login_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/widgets/auth_branding_panel.dart';

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: child,
  );
}

void main() {
  group('AdminLoginScreen Responsive Tests', () {
    // Test Case ID: SMP-112
    // Description: Kiểm tra màn hình đăng nhập Admin hiển thị bố cục chia đôi kèm AuthBrandingPanel khi chiều rộng >= 850px.
    testWidgets('renders desktop split layout with AuthBrandingPanel when width >= 850',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminLoginScreen()));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
      expect(find.byType(FilledButton), findsOneWidget); // Login button
    });

    // Test Case ID: SMP-113
    // Description: Kiểm tra màn hình đăng nhập Admin ẩn AuthBrandingPanel trên bố cục mobile khi chiều rộng < 850px.
    testWidgets('renders mobile layout without AuthBrandingPanel when width < 850',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminLoginScreen()));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    // Test Case ID: SMP-114
    // Description: Kiểm tra màn hình đăng nhập Admin hỗ trợ tiếng Việt và Dark Theme trên kích thước desktop 1200x800.
    testWidgets('supports Vietnamese locale and Dark Theme seamlessly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(
        child: const AdminLoginScreen(),
        locale: const Locale('vi'),
        theme: AppTheme.darkTheme,
      ));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Ghi nhớ đăng nhập'), findsOneWidget);
    });
  });

  group('AdminForgotPasswordScreen Responsive Tests', () {
    // Test Case ID: SMP-115
    // Description: Kiểm tra màn hình quên mật khẩu Admin hiển thị AuthBrandingPanel và 4 ô nhập liệu khi chiều rộng >= 850px.
    testWidgets('renders desktop split layout with AuthBrandingPanel when width >= 850',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminForgotPasswordScreen()));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4)); // Email, OTP, New Password, Confirm Password
    });

    // Test Case ID: SMP-116
    // Description: Kiểm tra màn hình quên mật khẩu Admin ẩn AuthBrandingPanel trên mobile khi chiều rộng < 850px.
    testWidgets('renders mobile layout without AuthBrandingPanel when width < 850',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminForgotPasswordScreen()));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsNothing);
      expect(find.byType(TextField), findsNWidgets(4));
    });

    // Test Case ID: SMP-117
    // Description: Kiểm tra màn hình quên mật khẩu Admin hỗ trợ tiếng Việt và Dark Theme trên kích thước 1200x800.
    testWidgets('supports Vietnamese locale and Dark Theme seamlessly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(
        child: const AdminForgotPasswordScreen(),
        locale: const Locale('vi'),
        theme: AppTheme.darkTheme,
      ));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsOneWidget);
      expect(find.text('Quay lại đăng nhập'), findsOneWidget);
      expect(find.text('Quên mật khẩu'), findsOneWidget);
    });
  });
}

