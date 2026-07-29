import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const SmartSpaceStaffApp());
}

class SmartSpaceStaffApp extends StatelessWidget {
  const SmartSpaceStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartSpace Staff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
