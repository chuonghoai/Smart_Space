import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_admin/features/sos/application/sos_admin_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/sos/sos_widgets.dart';
import 'package:smartspace_admin/ui/screen/sos/widgets/sos_mapbox_map.dart';

/// Chi tiết một SOS: người gửi, vị trí mới nhất, đường đi gần đây, tiếp nhận và kết thúc.
class SosDetailScreen extends ConsumerStatefulWidget {
  final String sosId;

  const SosDetailScreen({super.key, required this.sosId});

  @override
  ConsumerState<SosDetailScreen> createState() => _SosDetailScreenState();
}

class _SosDetailScreenState extends ConsumerState<SosDetailScreen> {
  bool _busy = false;

  Future<void> _acknowledge() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final error = await ref.read(sosAdminActionsProvider).acknowledge(widget.sosId);
    if (!mounted) return;
    setState(() => _busy = false);
    Toast.show(error == null ? ToastType.success : ToastType.error,
        error ?? l10n.sosAcknowledgedToast);
  }

  Future<void> _resolve(SosAlertModel sos) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_ResolveResult>(
      context: context,
      builder: (_) => _ResolveDialog(senderName: sos.user.fullName),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    final error = await ref
        .read(sosAdminActionsProvider)
        .resolve(widget.sosId, falseAlarm: result.falseAlarm, note: result.note);
    if (!mounted) return;
    setState(() => _busy = false);
    Toast.show(error == null ? ToastType.success : ToastType.error, error ?? l10n.sosResolvedToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(sosDetailProvider(widget.sosId));

    return AppLayout(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.sosLoadFailed, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(sosDetailProvider(widget.sosId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (sos) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(sos: sos),
                if (sos.isOpen) ...[
                  const SizedBox(height: 16),
                  _Actions(
                    sos: sos,
                    busy: _busy,
                    onAcknowledge: _acknowledge,
                    onResolve: () => _resolve(sos),
                  ),
                ],
                const SizedBox(height: 24),
                _LocationSection(sos: sos),
                if (sos.track.length > 1) ...[
                  const SizedBox(height: 24),
                  _TrackSection(sos: sos),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final SosAlertModel sos;

  const _Header({required this.sos});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urgent = sos.status == ESosStatus.active;
    final foreground = urgent ? scheme.onErrorContainer : scheme.onSurface;
    final muted = urgent ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    final phone = sos.user.phone;

    final lines = <String>[
      l10n.sosSentAt(formatSosDateTime(context, sos.createdAt)),
      l10n.sosNotifiedContacts(sos.notifiedContacts),
      if (sos.acknowledgedBy != null && sos.isOpen) l10n.sosHandledBy(sos.acknowledgedBy!.fullName),
      if (!sos.isOpen) l10n.sosEndedAt(formatSosDateTime(context, sos.resolvedAt)),
      if (sos.resolutionNote != null && sos.resolutionNote!.isNotEmpty) sos.resolutionNote!,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: urgent ? scheme.errorContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: urgent ? Border.all(color: scheme.error.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SosIconBadge(open: sos.isOpen, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sos.user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w700),
                ),
              ),
              SosStatusLabel(sos: sos, onUrgentSurface: urgent),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => callSosPhone(context, phone),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: muted),
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.call_outlined, size: 20),
              label: Text(l10n.sosCallSender(sos.user.fullName), overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final SosAlertModel sos;
  final bool busy;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  const _Actions({
    required this.sos,
    required this.busy,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needsAck = sos.status == ESosStatus.active;
    return Row(
      children: [
        if (needsAck) ...[
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : onAcknowledge,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.sosAcknowledge),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: needsAck
              ? OutlinedButton(
                  onPressed: busy ? null : onResolve,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(l10n.sosResolve),
                )
              : FilledButton(
                  onPressed: busy ? null : onResolve,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(l10n.sosResolve),
                ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  final SosAlertModel sos;

  const _LocationSection({required this.sos});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accuracy = sos.accuracy;
    final lost = sosSignalLost(sos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lost
              ? l10n.sosSignalLost(formatSosDateTime(context, sos.lastLocationAt))
              : l10n.sosLocationUpdatedAt(formatSosDateTime(context, sos.lastLocationAt)),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: lost ? theme.colorScheme.error : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${sos.latitude.toStringAsFixed(6)}, ${sos.longitude.toStringAsFixed(6)}'
          '${accuracy != null ? ' · ${l10n.sosAccuracy(accuracy.round())}' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        SosMapboxCard(sos: sos, height: 300),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => showSosMapboxDialog(context, sos),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          icon: const Icon(Icons.open_in_full_rounded, size: 18),
          label: Text(l10n.sosOpenMap),
        ),
      ],
    );
  }
}

class _TrackSection extends StatelessWidget {
  static const int _shown = 10;

  final SosAlertModel sos;

  const _TrackSection({required this.sos});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final points = sos.track.take(_shown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sosTrackTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    formatSosDateTime(context, p.recordedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResolveResult {
  final bool falseAlarm;
  final String? note;

  const _ResolveResult({required this.falseAlarm, this.note});
}

class _ResolveDialog extends StatefulWidget {
  final String senderName;

  const _ResolveDialog({required this.senderName});

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _noteCtrl = TextEditingController();
  bool _falseAlarm = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.sosResolveTitle(widget.senderName)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.sosResolveHandled)),
                ButtonSegment(value: true, label: Text(l10n.sosResolveFalseAlarm)),
              ],
              selected: {_falseAlarm},
              onSelectionChanged: (s) => setState(() => _falseAlarm = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLength: kSosMaxNoteLength,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.sosResolveNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _ResolveResult(falseAlarm: _falseAlarm, note: _noteCtrl.text),
          ),
          child: Text(l10n.sosResolve),
        ),
      ],
    );
  }
}
