import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_staff/ui/mobile/map/map_app_bar.dart';

/// Dựng giống màn bản đồ Staff: AppBar nổi trên body, chip lọc nằm trong vùng toolbar.
Widget _mapLikeScreen({required VoidCallback onChip, required VoidCallback onBack}) {
  return MaterialApp(
    home: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MapAppBar(onBack: onBack),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.green)),
          Positioned(
            top: 4,
            left: 56,
            right: 68,
            child: Center(
              child: ChoiceChip(
                key: const Key('chip'),
                label: const Text('chip'),
                selected: false,
                onSelected: (_) => onChip(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('MapAppBar không chặn chạm vào chip lọc nằm dưới vùng toolbar', (tester) async {
    var chipTaps = 0;
    var backTaps = 0;
    await tester.pumpWidget(_mapLikeScreen(onChip: () => chipTaps++, onBack: () => backTaps++));

    await tester.tap(find.byKey(const Key('chip')));
    expect(chipTaps, 1);

    // Nút back của AppBar vẫn hoạt động
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backTaps, 1);
  });
}
