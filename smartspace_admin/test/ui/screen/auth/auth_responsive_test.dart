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
    testWidgets('renders desktop split layout with AuthBrandingPanel when width >= 850',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminForgotPasswordScreen()));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4)); // Email, OTP, New Password, Confirm Password
    });

    testWidgets('renders mobile layout without AuthBrandingPanel when width < 850',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminForgotPasswordScreen()));
      await tester.pump();

      expect(find.byType(AuthBrandingPanel), findsNothing);
      expect(find.byType(TextField), findsNWidgets(4));
    });

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

