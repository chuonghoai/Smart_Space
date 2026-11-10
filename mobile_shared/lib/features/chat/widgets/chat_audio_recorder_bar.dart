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

/// Dedicated Audio Recording Bar with instant touch-and-hold recording (0 delay),
/// local preview with seekable audio player, large send button, and immediate
/// local file deletion on cancellation or screen dismissal.
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
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _currentRecordingPath;
  Uint8List? _recordedBytes;
  DateTime? _recordStartTime;
  bool _wasSent = false;
  bool _isStartingRecording = false;
  bool _stopRequested = false;

  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackTotalDuration = Duration.zero;

  String? _cachedTempDir;
  bool _hasMicPermission = false;

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

    _preloadTempDirAndPermission();
  }

  Future<void> _preloadTempDirAndPermission() async {
    try {
      final dir = await getTemporaryDirectory();
      _cachedTempDir = dir.path;
      _hasMicPermission = await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('[ChatAudioRecorderBar] preload error: $e');
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();

    // If recording was not sent, immediately delete temporary file from local storage
    if (!_wasSent && _currentRecordingPath != null) {
      final f = File(_currentRecordingPath!);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (e) {
          debugPrint('[ChatAudioRecorderBar] Temp file cleanup error: $e');
        }
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
    if (_mode != AudioBarMode.idle || _isStartingRecording) return;
    _isStartingRecording = true;
    _stopRequested = false;

    try {
      if (!_hasMicPermission) {
        final granted = await _audioRecorder.hasPermission();
        _hasMicPermission = granted;
        if (!granted) {
          _isStartingRecording = false;
          if (mounted) {
            final l10n = SharedLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.micPermissionRequired ??
                      'Vui lòng cấp quyền truy cập microphone để ghi âm',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final tempDir = _cachedTempDir ?? (await getTemporaryDirectory()).path;
      final path =
          '$tempDir/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path;
      _recordDuration = 0;
      _recordedBytes = null;
      _wasSent = false;
      _recordStartTime = DateTime.now();

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        setState(() {
          _mode = AudioBarMode.recording;
        });
      }

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDuration++);
        }
      });

      _isStartingRecording = false;

      // Handle pointer lifted while start() was awaiting
      if (_stopRequested) {
        await _finishRecording();
      }
    } catch (e) {
      _isStartingRecording = false;
      debugPrint('[ChatAudioRecorderBar] Start recording error: $e');
    }
  }

  Future<void> _handlePointerUp() async {
    if (_isStartingRecording) {
      _stopRequested = true;
      return;
    }
    if (_mode == AudioBarMode.recording) {
      await _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    _recordTimer?.cancel();
    final startTime = _recordStartTime;
    final duration = _recordDuration;
    final elapsedMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : 0;

    try {
      final path = await _audioRecorder.stop();
      final filePath = path ?? _currentRecordingPath;

      // Check if recording was too brief (< 500ms or 0 duration)
      if (filePath == null || elapsedMs < 500) {
        if (filePath != null) {
          final f = File(filePath);
          if (await f.exists()) {
            await f.delete();
          }
        }
        if (mounted) {
          setState(() {
            _mode = AudioBarMode.idle;
            _recordDuration = 0;
            _currentRecordingPath = null;
          });
          final l10n = SharedLocalizations.of(context);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.holdToRecordPrompt ?? 'Nhấn giữ để bắt đầu thu âm',
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final file = File(filePath);
      if (await file.exists() && await file.length() > 100) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          HapticFeedback.lightImpact();
          setState(() {
            _recordedBytes = bytes;
            _currentRecordingPath = filePath;
            _playbackPosition = Duration.zero;
            _playbackTotalDuration =
                Duration(seconds: duration > 0 ? duration : 1);
            _mode = AudioBarMode.preview;
          });
        }
      } else {
        if (filePath.isNotEmpty) {
          final f = File(filePath);
          if (await f.exists()) {
            await f.delete();
          }
        }
        if (mounted) {
          setState(() {
            _mode = AudioBarMode.idle;
            _currentRecordingPath = null;
            _recordDuration = 0;
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
      _wasSent = false;
    });
  }

  void _handleClose() {
    _discardRecording();
    widget.onClose();
  }

  void _sendRecordedAudio() {
    if (_recordedBytes == null || _currentRecordingPath == null) return;
    _audioPlayer.stop();
    _wasSent = true;
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

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    SharedLocalizations? sharedL10n,
  ) {
    if (_mode == AudioBarMode.preview) {
      return _buildPreviewMode(context, theme, sharedL10n);
    }
    return _buildRecordOrIdleMode(context, theme, sharedL10n);
  }

  Widget _buildRecordOrIdleMode(
    BuildContext context,
    ThemeData theme,
    SharedLocalizations? sharedL10n,
  ) {
    final isRecording = _mode == AudioBarMode.recording;

    return Row(
      key: ValueKey(isRecording ? 'recording' : 'idle'),
      children: [
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: sharedL10n?.discardAudio ?? 'Đóng',
          onPressed: _handleClose,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Listener(
                  onPointerDown: (_) => _startRecording(),
                  onPointerUp: (_) => _handlePointerUp(),
                  onPointerCancel: (_) => _handlePointerUp(),
                  child: isRecording
                      ? ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
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
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.2),
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
                if (isRecording)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _pulseController,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_recordDuration),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sharedL10n?.recordingAudio ?? 'Đang thu âm...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    sharedL10n?.holdToRecordPrompt ??
                        'Nhấn giữ để bắt đầu thu âm',
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
  }

  Widget _buildPreviewMode(
    BuildContext context,
    ThemeData theme,
    SharedLocalizations? sharedL10n,
  ) {
    return Column(
      key: const ValueKey('preview'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio Player Scrubber Bar
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              tooltip: sharedL10n?.discardAudio ?? 'Hủy',
              onPressed: _discardRecording,
            ),
            IconButton.filledTonal(
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              onPressed: _togglePlayPreview,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor:
                          theme.colorScheme.surfaceContainerHighest,
                      thumbColor: theme.colorScheme.primary,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      min: 0,
                      max: _playbackTotalDuration.inMilliseconds > 0
                          ? _playbackTotalDuration.inMilliseconds.toDouble()
                          : (_recordDuration * 1000)
                              .toDouble()
                              .clamp(1.0, double.infinity),
                      value: _playbackPosition.inMilliseconds
                          .toDouble()
                          .clamp(
                            0.0,
                            _playbackTotalDuration.inMilliseconds > 0
                                ? _playbackTotalDuration.inMilliseconds
                                    .toDouble()
                                : (_recordDuration * 1000)
                                    .toDouble()
                                    .clamp(1.0, double.infinity),
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
                          _formatDuration(
                            _recordDuration > 0
                                ? _recordDuration
                                : _playbackTotalDuration.inSeconds,
                          ),
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
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 8),
        // Large Center Send Button replacing the microphone button
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sendRecordedAudio,
                  borderRadius: BorderRadius.circular(32),
                  child: Ink(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 30,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sharedL10n?.sendAudio ?? 'Gửi',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
