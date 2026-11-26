import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_client/features/sos/providers/sos_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/emergency/widgets/emergency_contact_widgets.dart';
import 'package:smartspace_client/ui/mobile/sos/widgets/sos_mapbox_view.dart';
import 'package:smartspace_client/ui/mobile/sos/widgets/sos_widgets.dart';

/// Người bảo hộ theo dõi SOS: trạng thái, vị trí mới nhất, mở bản đồ và gọi cho người gặp nạn.
/// Nếu phát hiện đây là SOS của chính người đang đăng nhập (vd. mở từ FCM lúc cold start),
/// tự động chuyển sang màn [RouterPath.sosActive].
class MobileSosWatchScreen extends ConsumerStatefulWidget {
  final String sosId;

  const MobileSosWatchScreen({super.key, required this.sosId});

  @override
  ConsumerState<MobileSosWatchScreen> createState() => _MobileSosWatchScreenState();
}

class _MobileSosWatchScreenState extends ConsumerState<MobileSosWatchScreen> {
  String? _currentUserId;
  bool _userChecked = false;
  bool _redirectedToOwn = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await userStorageService.getUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = user?.id;
      _userChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(watchedSosProvider(widget.sosId));
    final sos = state.sos;

    if (sos == null || !_userChecked) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: (state.isLoading || !_userChecked)
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.sosLoadFailed, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.read(watchedSosProvider(widget.sosId).notifier).load(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    if (_currentUserId != null && sos.user.id == _currentUserId) {
      if (!_redirectedToOwn) {
        _redirectedToOwn = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(sosProvider.notifier).syncOwn(sos);
          context.pushReplacement(RouterPath.sosActive);
        });
      }
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sosActiveTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = sos.user.fullName;
    final phone = sos.user.phone;
    final open = sos.isOpen;
    final accuracy = sos.accuracy;

    final String title;
    final List<Widget> details;
    if (open) {
      title = l10n.sosWatchActive(name);
      details = [
        SosStatusLine(
          sos.acknowledgedBy != null ? l10n.sosWatchAcknowledged : l10n.sosSentAt(formatSosTime(context, sos.createdAt)),
          icon: sos.acknowledgedBy != null ? Icons.support_agent : Icons.schedule,
        ),
      ];
    } else {
      title = sos.resolution == ESosResolution.safeByUser ? l10n.sosWatchSafe(name) : l10n.sosWatchClosed;
      details = const [];
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sosWatchTitle(name))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(watchedSosProvider(widget.sosId).notifier).load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Semantics(liveRegion: true, child: SosStatusPanel(open: open, title: title, details: details)),
            const SizedBox(height: 20),
            Text(
              l10n.sosLocationUpdatedAt(formatSosTime(context, sos.lastLocationAt)),
              style: theme.textTheme.bodyMedium,
            ),
            if (accuracy != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l10n.sosAccuracy(accuracy.round()),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 12),
            SosMapboxView(
              sos: sos,
              height: 240,
              onExpand: () => showSosMapboxFullscreen(
                context,
                title: l10n.sosWatchTitle(name),
                initialSos: sos,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showSosMapboxFullscreen(
                context,
                title: l10n.sosWatchTitle(name),
                initialSos: sos,
              ),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.sosOpenMap),
            ),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => callEmergencyPhone(context, phone),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.call_outlined),
                label: Text(l10n.sosCallPerson(name), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
            if (open) ...[
              const SizedBox(height: 28),
              Text(l10n.sosCallEmergency, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const SosEmergencyNumbers(),
            ],
          ],
        ),
      ),
    );
  }
}
