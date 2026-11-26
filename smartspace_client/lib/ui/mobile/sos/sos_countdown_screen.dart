import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/sos/sos_countdown_controller.dart';
import 'package:smartspace_client/ui/mobile/sos/widgets/sos_widgets.dart';

/// Đếm ngược 5 giây có nút Huỷ lớn; gửi xong thì chuyển sang màn SOS đang hoạt động.
class MobileSosCountdownScreen extends ConsumerWidget {
  const MobileSosCountdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(sosCountdownControllerProvider);
    final controller = ref.read(sosCountdownControllerProvider.notifier);

    ref.listen(sosCountdownControllerProvider, (previous, next) {
      if (next.phase == SosCountdownPhase.sent) {
        context.pushReplacement(RouterPath.sosActive);
      }
    });

    final failed = state.phase == SosCountdownPhase.failed;
    final busy = state.phase == SosCountdownPhase.locating || state.phase == SosCountdownPhase.sending;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: failed ? scheme.surface : scheme.errorContainer,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: failed ? scheme.onSurface : scheme.onErrorContainer,
          automaticallyImplyLeading: !busy,
          centerTitle: true,
          title: Text(l10n.sosCountdownTitle),
        ),
        body: SafeArea(
          child: failed
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: _Failure(state: state, controller: controller),
                )
              : SizedBox.expand(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _Progress(state: state, busy: busy),
                      ),
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: busy
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: failed ? scheme.onSurface : scheme.onErrorContainer,
                    side: BorderSide(color: failed ? scheme.outline : scheme.onErrorContainer, width: 1.5),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final SosCountdownState state;
  final bool busy;

  const _Progress({required this.state, required this.busy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = switch (state.phase) {
      SosCountdownPhase.locating => l10n.sosLocating,
      SosCountdownPhase.sending || SosCountdownPhase.sent => l10n.sosSending,
      _ => l10n.sosCountdownMessage(state.secondsLeft),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 176,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: busy ? null : state.secondsLeft / SosCountdownController.seconds,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: scheme.onErrorContainer,
                  backgroundColor: scheme.onErrorContainer.withValues(alpha: 0.16),
                ),
              ),
              if (!busy)
                Text(
                  '${state.secondsLeft}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              else
                Icon(Icons.sos, size: 52, color: scheme.onErrorContainer),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Semantics(
          liveRegion: true,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  final SosCountdownState state;
  final SosCountdownController controller;

  const _Failure({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message = switch (state.failure) {
      SosCountdownFailure.permissionDenied => l10n.sosLocationPermissionDenied,
      SosCountdownFailure.locationUnavailable => l10n.sosLocationUnavailable,
      _ => (state.serverMessage?.isNotEmpty ?? false) ? state.serverMessage! : l10n.sosSendFailed,
    };

    return ListView(
      children: [
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.onErrorContainer, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: controller.retry,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(l10n.retry),
              ),
            ),
            if (state.failure == SosCountdownFailure.permissionDenied) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.openSettings,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(l10n.sosOpenSettings),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        Text(l10n.sosCallEmergency, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const SosEmergencyNumbers(),
      ],
    );
  }
}
