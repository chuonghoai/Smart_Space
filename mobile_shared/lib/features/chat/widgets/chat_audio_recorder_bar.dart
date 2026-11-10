import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

typedef AudioRecordCallback = void Function({
  required Uint8List bytes,
  required String fileName,
  required int durationSeconds,
  required String localPath,
});

enum AudioBarMode { idle, recording, preview }

/// Dedicated Audio Recording Bar replacing the text bar with tactile micro interactions,
/// large center microphone button, press-and-hold recording, and full playback preview/scrubbing.
class ChatAudioRecorderBar extends StatefulWidget {
  final AudioRecordCallback onRecordingComplete;
  final VoidCallback onClose;

  const ChatAudioRecorderBar({
    super.key,
    required this.onRecordingComplete,
    required this.onClose,
  });

  @override
  State<ChatAudioRecorderBar> createState() => _ChatAudioRecorderBarState();
}

class _ChatAudioRecorderBarState extends State<ChatAudioRecorderBar>
    with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  late final AnimationController _pulseController;

  AudioBarMode _mode = AudioBarMode.idle;
  bool _isCancelled = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _currentRecordingPath;
  Uint8List? _recordedBytes;

  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackTotalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _playbackPosition = pos;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) {
        setState(() {
          _playbackTotalDuration = d;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    if (_currentRecordingPath != null && _mode != AudioBarMode.preview) {
      final f = File(_currentRecordingPath!);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          final l10n = SharedLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.micPermissionRequired ?? 'Vui lòng cấp quyền truy cập microphone để ghi âm'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      HapticFeedback.mediumImpact();

      setState(() {
        _mode = AudioBarMode.recording;
        _isCancelled = false;
        _recordDuration = 0;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDuration++);
        }
      });
    } catch (e) {
      debugPrint('[ChatAudioRecorderBar] Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final wasCancelled = _isCancelled;
    final duration = _recordDuration;

    try {
      final path = await _audioRecorder.stop();
      final filePath = path ?? _currentRecordingPath;

      if (filePath == null || wasCancelled || duration < 1) {
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        if (mounted) {
          setState(() {
            _mode = AudioBarMode.idle;
            _isCancelled = false;
            _recordDuration = 0;
            _currentRecordingPath = null;
          });
        }
        return;
      }

      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _recordedBytes = bytes;
            _currentRecordingPath = filePath;
            _playbackPosition = Duration.zero;
            _playbackTotalDuration = Duration(seconds: duration);
            _mode = AudioBarMode.preview;
          });
        }
      }
    } catch (e) {
      debugPrint('[ChatAudioRecorderBar] Stop recording error: $e');
      if (mounted) {
        setState(() => _mode = AudioBarMode.idle);
      }
    }
  }

  Future<void> _togglePlayPreview() async {
    if (_currentRecordingPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_currentRecordingPath!));
    }
  }

  void _discardRecording() {
    _audioPlayer.stop();
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    setState(() {
      _mode = AudioBarMode.idle;
      _recordedBytes = null;
      _currentRecordingPath = null;
      _recordDuration = 0;
      _playbackPosition = Duration.zero;
    });
  }

  void _sendRecordedAudio() {
    if (_recordedBytes == null || _currentRecordingPath == null) return;
    _audioPlayer.stop();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    widget.onRecordingComplete(
      bytes: _recordedBytes!,
      fileName: fileName,
      durationSeconds: _recordDuration > 0 ? _recordDuration : 1,
      localPath: _currentRecordingPath!,
    );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharedL10n = SharedLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildContent(context, theme, sharedL10n),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, SharedLocalizations? sharedL10n) {
    switch (_mode) {
      case AudioBarMode.idle:
        return Row(
          key: const ValueKey('idle'),
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: sharedL10n?.discardAudio ?? 'Đóng',
              onPressed: widget.onClose,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(sharedL10n?.holdToRecordPrompt ?? 'Nhấn giữ để bắt đầu thu âm'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressMoveUpdate: (details) {
                        final offset = details.offsetFromOrigin.dx;
                        setState(() {
                          _isCancelled = offset < -60;
                        });
                      },
                      onLongPressEnd: (_) => _stopRecording(),
                      onLongPressCancel: () {
                        _isCancelled = true;
                        _stopRecording();
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sharedL10n?.holdToRecordPrompt ?? 'Nhấn giữ để bắt đầu thu âm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );

      case AudioBarMode.recording:
        return Row(
          key: const ValueKey('recording'),
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _isCancelled = true;
                _stopRecording();
              },
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onLongPressMoveUpdate: (details) {
                        final offset = details.offsetFromOrigin.dx;
                        setState(() {
                          _isCancelled = offset < -60;
                        });
                      },
                      onLongPressEnd: (_) => _stopRecording(),
                      onLongPressCancel: () {
                        _isCancelled = true;
                        _stopRecording();
                      },
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _isCancelled ? theme.colorScheme.error : theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isCancelled ? theme.colorScheme.error : theme.colorScheme.primary).withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _pulseController,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isCancelled ? theme.colorScheme.error : theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_recordDuration),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _isCancelled ? theme.colorScheme.error : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isCancelled
                              ? (sharedL10n?.releaseToCancel ?? 'Thả để hủy')
                              : '← ${sharedL10n?.slideLeftToCancel ?? 'Trượt để hủy'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _isCancelled ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );

      case AudioBarMode.preview:
        return Row(
          key: const ValueKey('preview'),
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              tooltip: sharedL10n?.discardAudio ?? 'Hủy',
              onPressed: _discardRecording,
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: _togglePlayPreview,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                      thumbColor: theme.colorScheme.primary,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      min: 0,
                      max: _playbackTotalDuration.inMilliseconds > 0
                          ? _playbackTotalDuration.inMilliseconds.toDouble()
                          : (_recordDuration * 1000).toDouble().clamp(1.0, double.infinity),
                      value: _playbackPosition.inMilliseconds.toDouble().clamp(
                            0.0,
                            _playbackTotalDuration.inMilliseconds > 0
                                ? _playbackTotalDuration.inMilliseconds.toDouble()
                                : (_recordDuration * 1000).toDouble().clamp(1.0, double.infinity),
                          ),
                      onChanged: (val) {
                        _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_playbackPosition.inSeconds),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          _formatDuration(_recordDuration),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              icon: const Icon(Icons.send_rounded),
              tooltip: sharedL10n?.sendAudio ?? 'Gửi',
              onPressed: _sendRecordedAudio,
            ),
          ],
        );
    }
  }
}

/// Legacy wrapper for backwards compatibility
class ChatAudioRecorderButton extends StatelessWidget {
  final AudioRecordCallback onRecordingComplete;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingCancel;
  final VoidCallback? onTap;

  const ChatAudioRecorderButton({
    super.key,
    required this.onRecordingComplete,
    this.onRecordingStart,
    this.onRecordingCancel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic_none_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
