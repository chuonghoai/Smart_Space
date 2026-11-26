import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_client/features/sos/providers/sos_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/sos/widgets/sos_widgets.dart';

/// SOS của chính người dùng: trạng thái tiếp nhận, chia sẻ vị trí, số khẩn cấp, nút "Tôi đã an toàn".
class MobileSosActiveScreen extends ConsumerStatefulWidget {
  const MobileSosActiveScreen({super.key});

  @override
  ConsumerState<MobileSosActiveScreen> createState() => _MobileSosActiveScreenState();
}

class _MobileSosActiveScreenState extends ConsumerState<MobileSosActiveScreen> {
  bool _trackingRequested = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(sosProvider.notifier);
      if (ref.read(sosProvider).sos == null) await notifier.loadActive();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTracking();
  }

  void _startTracking() {
    if (_trackingRequested) return;
    final l10n = AppLocalizations.of(context)!;
    _trackingRequested = true;
    // Chạy sau frame đầu để provider đã có SOS (vừa tạo hoặc vừa khôi phục)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sosProvider.notifier).ensureTracking(
            notificationTitle: l10n.sosTrackingNotifTitle,
            notificationText: l10n.sosTrackingNotifText,
          );
    });
  }

  Future<void> _markSafe() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sosSafeConfirmTitle),
        content: Text(l10n.sosSafeConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.sosImSafe)),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await ref.read(sosProvider.notifier).markSafe();
    if (!res.success) {
      Toast.show(ToastType.error, res.message.isNotEmpty ? res.message : l10n.genericError);
    }
  }

  void _backHome() {
    ref.read(sosProvider.notifier).clearClosed();
    context.go(RouterPath.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sosProvider);
    final sos = state.sos;

    // Có SOS mới (vd. khôi phục sau khi mở lại app) thì bật theo dõi
    ref.listen(sosProvider, (previous, next) {
      if (next.hasOpen && !(previous?.hasOpen ?? false)) {
        ref.read(sosProvider.notifier).ensureTracking(
              notificationTitle: l10n.sosTrackingNotifTitle,
              notificationText: l10n.sosTrackingNotifText,
            );
      }
    });

    if (sos == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sosActiveTitle)),
        body: state.isLoaded
            ? Center(child: TextButton(onPressed: _backHome, child: Text(l10n.sosBackHome)))
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final open = sos.isOpen;
    return Scaffold(
      appBar: AppBar(title: Text(open ? l10n.sosActiveTitle : l10n.sosEndedTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          open ? _OpenPanel(sos: sos, lastSentAt: state.lastSentAt) : _ClosedPanel(sos: sos),
          if (open) ...[
            const SizedBox(height: 28),
            Text(
              l10n.sosCallEmergency,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const SosEmergencyNumbers(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: open
            ? FilledButton.icon(
                onPressed: state.isEnding ? null : _markSafe,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                icon: state.isEnding
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.verified_user_outlined),
                label: Text(l10n.sosImSafe),
              )
            : FilledButton(
                onPressed: _backHome,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: Text(l10n.sosBackHome),
              ),
      ),
    );
  }
}

class _OpenPanel extends StatelessWidget {
  final SosAlertModel sos;
  final DateTime? lastSentAt;

  const _OpenPanel({required this.sos, required this.lastSentAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ack = sos.acknowledgedBy;
    return Semantics(
      liveRegion: true,
      child: SosStatusPanel(
        open: true,
        title: ack != null ? l10n.sosAcknowledgedBy(ack.fullName) : l10n.sosWaitingAck(sos.notifiedContacts),
        details: [
          SosStatusLine(l10n.sosSharingLocation, icon: Icons.my_location),
          SosStatusLine(
            l10n.sosLocationUpdatedAt(formatSosTime(context, sos.lastLocationAt ?? lastSentAt)),
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }
}

class _ClosedPanel extends StatelessWidget {
  final SosAlertModel sos;

  const _ClosedPanel({required this.sos});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bySelf = sos.resolution == ESosResolution.safeByUser;
    return SosStatusPanel(
      open: false,
      title: l10n.sosEndedTitle,
      details: [SosStatusLine(bySelf ? l10n.sosEndedSafe : l10n.sosEndedByAdmin)],
    );
  }
}
