import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final distanceUpdaterProvider = StreamProvider<DateTime>((ref) {
  // Emit current time immediately
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());

  // Then emit every 1 minute
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
