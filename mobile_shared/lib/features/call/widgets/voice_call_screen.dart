import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';
import 'package:mobile_shared/features/call/providers/call_controller.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  final String callId;
  final VoidCallback? onClose;

  const VoiceCallScreen({
    super.key,
    required this.callId,
    this.onClose,
  });

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _popScheduled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(callControllerProvider);
      if (state.callId == widget.callId &&
          !state.isOutgoing &&
          state.status == CallStatus.incoming) {
        ref.read(callControllerProvider.notifier).confirmIncomingUiReady(widget.callId);
      }
      if (!MediaQuery.disableAnimationsOf(context)) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _closeIfNeeded() {
    if (_popScheduled || !mounted) return;
    _popScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  String _statusText(CallState state, SharedLocalizations l10n) {
    switch (state.status) {
      case CallStatus.connecting:
        return l10n.callStatusConnecting;
      case CallStatus.ringing:
        return l10n.callStatusRinging;
      case CallStatus.incoming:
        return l10n.callStatusIncoming;
      case CallStatus.accepted:
        return l10n.callStatusAccepted;
      case CallStatus.ongoing:
        return _formatDuration(state.elapsedSeconds);
      case CallStatus.ended:
        return l10n.callStatusEnded;
      case CallStatus.rejected:
        return l10n.callStatusRejected;
      case CallStatus.cancelled:
        return l10n.callStatusCancelled;
      case CallStatus.missed:
        return l10n.callStatusMissed;
      case CallStatus.failed:
        return l10n.callStatusFailed;
      case CallStatus.idle:
        return l10n.callStatusEnded;
    }
  }

  IconData _audioRouteIcon(AudioOutputRoute route) {
    switch (route) {
      case AudioOutputRoute.speaker:
        return Icons.volume_up_rounded;
      case AudioOutputRoute.bluetooth:
        return Icons.bluetooth_audio_rounded;
      case AudioOutputRoute.wiredHeadset:
        return Icons.headset_rounded;
      case AudioOutputRoute.earpiece:
      case AudioOutputRoute.browserDefault:
        return Icons.hearing_rounded;
    }
  }

  String _audioRouteLabel(AudioOutputRoute route, SharedLocalizations l10n) {
    switch (route) {
      case AudioOutputRoute.speaker:
        return l10n.callSpeaker;
      case AudioOutputRoute.bluetooth:
        return l10n.callBluetooth;
      case AudioOutputRoute.wiredHeadset:
        return l10n.callWiredHeadset;
      case AudioOutputRoute.earpiece:
        return l10n.callEarpiece;
      case AudioOutputRoute.browserDefault:
        return l10n.callAudioOutput;
    }
  }

  Future<void> _onAudioOutputTap(
    BuildContext context,
    CallState state,
    SharedLocalizations l10n,
  ) async {
    final routes = state.availableAudioRoutes;
    if (routes.length <= 1) return;

    if (routes.length == 2) {
      final next = routes.firstWhere(
        (r) => r != state.activeAudioRoute,
        orElse: () => routes.first,
      );
      await ref.read(callControllerProvider.notifier).selectAudioOutput(next);
      return;
    }

    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.callAudioOutput,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ...routes.map(
                (route) => ListTile(
                  leading: Icon(
                    _audioRouteIcon(route),
                    color: route == state.activeAudioRoute
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(_audioRouteLabel(route, l10n)),
                  trailing: route == state.activeAudioRoute
                      ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(callControllerProvider.notifier)
                        .selectAudioOutput(route);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callControllerProvider);
    final l10n = SharedLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final cs = theme.colorScheme;

    final isPendingPlaceholder = widget.callId.startsWith('pending_');
    if (state.status == CallStatus.idle ||
        (!isPendingPlaceholder &&
            state.callId != null &&
            state.callId != widget.callId)) {
      _closeIfNeeded();
    }

    final peer = state.peer;
    final isAnonymous = peer?.isAnonymous ?? false;
    final displayName = isAnonymous
        ? l10n.callAnonymousUser
        : ((peer?.fullName.isNotEmpty ?? false)
            ? peer!.fullName
            : l10n.callAnonymousUser);
    final avatarUrl = isAnonymous ? null : peer?.avatarUrl;
    final statusLabel = _statusText(state, l10n);
    final isRingingVisual =
        state.status == CallStatus.ringing || state.status == CallStatus.incoming;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final remoteRenderer = ref.read(callControllerProvider.notifier).remoteRenderer;

    return PopScope(
      canPop: !state.hasActiveCall,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  children: [
                    if (kIsWeb && remoteRenderer != null)
                      SizedBox(
                        width: 1,
                        height: 1,
                        child: RTCVideoView(remoteRenderer),
                      ),
                    // Top status pill (restrained tonal container)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.callFreeTitle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Peer Avatar with restrained ringing ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final ringPadding = (isRingingVisual && !reduceMotion)
                            ? 8.0 + (_pulseController.value * 10.0)
                            : 8.0;
                        return Container(
                          padding: EdgeInsets.all(ringPadding),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRingingVisual
                                ? cs.primary.withValues(alpha: 0.10)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                          child: child,
                        );
                      },
                      child: _PeerAvatar(
                        avatarUrl: avatarUrl,
                        displayName: displayName,
                        isAnonymous: isAnonymous,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Call Status or Tabular Duration
                    Text(
                      statusLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: state.status == CallStatus.ongoing
                            ? semantic.success
                            : (state.status.isTerminal
                                ? cs.error
                                : cs.onSurfaceVariant),
                        fontWeight: FontWeight.w600,
                        fontFeatures: state.status == CallStatus.ongoing
                            ? const [FontFeature.tabularFigures()]
                            : null,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Controls
                    if (state.status == CallStatus.incoming && !state.isOutgoing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallRoundAction(
                            icon: Icons.call_end_rounded,
                            label: l10n.callReject,
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            size: 64,
                            onTap: () => ref
                                .read(callControllerProvider.notifier)
                                .rejectIncomingCall(),
                          ),
                          _CallRoundAction(
                            icon: Icons.call_rounded,
                            label: l10n.callAccept,
                            backgroundColor: semantic.success,
                            foregroundColor: cs.onPrimary,
                            size: 64,
                            onTap: () => ref
                                .read(callControllerProvider.notifier)
                                .acceptIncomingCall(),
                          ),
                        ],
                      )
                    else if (state.status.isTerminal || state.status == CallStatus.idle)
                      FilledButton.tonal(
                        onPressed: () {
                          ref.read(callControllerProvider.notifier).dismissCallUi();
                          _closeIfNeeded();
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(160, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.callClose),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CallRoundAction(
                              icon: state.isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              label: state.isMuted
                                  ? l10n.callUnmute
                                  : l10n.callMute,
                              backgroundColor: state.isMuted
                                  ? cs.primary
                                  : cs.surfaceContainerHighest,
                              foregroundColor: state.isMuted
                                  ? cs.onPrimary
                                  : cs.onSurface,
                              size: 56,
                              onTap: () => ref
                                  .read(callControllerProvider.notifier)
                                  .toggleMute(),
                            ),
                            _CallRoundAction(
                              icon: _audioRouteIcon(state.activeAudioRoute),
                              label: _audioRouteLabel(
                                  state.activeAudioRoute, l10n),
                              backgroundColor:
                                  state.activeAudioRoute == AudioOutputRoute.speaker
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                              foregroundColor:
                                  state.activeAudioRoute == AudioOutputRoute.speaker
                                      ? cs.onPrimary
                                      : cs.onSurface,
                              size: 56,
                              onTap: () =>
                                  _onAudioOutputTap(context, state, l10n),
                            ),
                            _CallRoundAction(
                              icon: Icons.call_end_rounded,
                              label: l10n.callEnd,
                              backgroundColor: cs.error,
                              foregroundColor: cs.onError,
                              size: 56,
                              onTap: () => ref
                                  .read(callControllerProvider.notifier)
                                  .endActiveCall(),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final bool isAnonymous;

  const _PeerAvatar({
    required this.avatarUrl,
    required this.displayName,
    required this.isAnonymous,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallbackLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: ClipOval(
        child: isAnonymous || avatarUrl == null || avatarUrl!.isEmpty
            ? Center(
                child: isAnonymous
                    ? Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: cs.onPrimaryContainer,
                      )
                    : Text(
                        fallbackLetter,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
              )
            : Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                headers: const {'User-Agent': 'SmartSpace-App'},
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    fallbackLetter,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CallRoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final VoidCallback onTap;

  const _CallRoundAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: foregroundColor, size: size * 0.44),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
