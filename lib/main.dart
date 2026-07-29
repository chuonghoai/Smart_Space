import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const SmartSpaceAdminApp());
}

class SmartSpaceAdminApp extends StatelessWidget {
  const SmartSpaceAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartSpace Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
