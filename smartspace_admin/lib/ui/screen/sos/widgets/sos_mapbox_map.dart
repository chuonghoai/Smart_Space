import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_admin/features/sos/application/sos_admin_providers.dart';

import 'sos_mapbox_map_mobile.dart'
    if (dart.library.html) 'sos_mapbox_map_web.dart'
    as platform_map;

/// Khung bản đồ Mapbox (Mobile & Web) hiển thị vị trí và đường di chuyển của tín hiệu SOS.
class SosMapboxCard extends StatelessWidget {
  final SosAlertModel sos;
  final double height;

  const SosMapboxCard({
    super.key,
    required this.sos,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: platform_map.buildSosMapboxMap(context: context, sos: sos),
      ),
    );
  }
}

/// Mở bản đồ Mapbox cỡ lớn trong hộp thoại, tự cập nhật vị trí và đường đi realtime.
Future<void> showSosMapboxDialog(BuildContext context, SosAlertModel initialSos) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SosMapboxDialog(initialSos: initialSos),
  );
}

class _SosMapboxDialog extends ConsumerWidget {
  final SosAlertModel initialSos;

  const _SosMapboxDialog({required this.initialSos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveSos = ref.watch(sosDetailProvider(initialSos.id)).valueOrNull ?? initialSos;
    final size = MediaQuery.sizeOf(context);
    final width = size.width < 920 ? size.width - 32 : 880.0;
    final height = size.height < 680 ? size.height - 120 : 560.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      liveSos.user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SosMapboxCard(sos: liveSos, height: height),
            ],
          ),
        ),
      ),
    );
  }
}
