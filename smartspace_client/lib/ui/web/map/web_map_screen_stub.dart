import 'package:flutter/material.dart';

/// Đây là file stub (giả) cho WebMapScreen khi chạy trên Mobile/Desktop.
/// Nó giúp tránh lỗi không tìm thấy `dart:js_interop` trên các nền tảng không phải Web.
class WebMapScreen extends StatelessWidget {
  const WebMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Web Map is not supported on this platform.'),
      ),
    );
  }
}
