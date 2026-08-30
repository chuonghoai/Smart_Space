import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smartspace_staff/core/notification/firebase_service.dart';
import 'l10n/app_localizations.dart';
import 'routes/app_router.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:smartspace_staff/core/toast/toast_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/core/connection/connection_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await dotenv.load(fileName: ".env");
  await FirebaseService.initialize();
  runApp(const ProviderScope(child: SmartSpaceStaffApp()));
}

class SmartSpaceStaffApp extends StatefulWidget {
  const SmartSpaceStaffApp({super.key});

  @override
  State<SmartSpaceStaffApp> createState() => _SmartSpaceAppState();
}

class _SmartSpaceAppState extends State<SmartSpaceStaffApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.hidden) {
      connectionManager.pauseConnections();
    } else if (state == AppLifecycleState.resumed) {
      connectionManager.resumeConnections();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localeProvider, themeProvider]),
      builder: (context, child) {
        return MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'SmartSpace Staff',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
