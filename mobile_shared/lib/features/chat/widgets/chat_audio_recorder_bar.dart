import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

typedef AudioRecordCallback = void Function({
  required Uint8List bytes,
  required String fileName,
  required int durationSeconds,
  required String localPath,
});

class ChatAudioRecorderButton extends StatefulWidget {
  final AudioRecordCallback onRecordingComplete;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingCancel;

  const ChatAudioRecorderButton({
    super.key,
    required this.onRecordingComplete,
    this.onRecordingStart,
    this.onRecordingCancel,
  });

  @override
  State<ChatAudioRecorderButton> createState() => _ChatAudioRecorderButtonState();
}

class _ChatAudioRecorderButtonState extends State<ChatAudioRecorderButton>
    with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isCancelled = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _currentRecordingPath;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
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
      widget.onRecordingStart?.call();

      setState(() {
        _isRecording = true;
        _isCancelled = false;
        _recordDuration = 0;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDuration++);
        }
      });
    } catch (e) {
      debugPrint('[ChatAudioRecorder] Start error: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final wasCancelled = _isCancelled;
    final duration = _recordDuration;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isCancelled = false;
      });

      final filePath = path ?? _currentRecordingPath;
      if (filePath == null) return;

      final file = File(filePath);
      if (wasCancelled || duration < 1) {
        if (await file.exists()) {
          await file.delete();
        }
        widget.onRecordingCancel?.call();
        return;
      }

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        widget.onRecordingComplete(
          bytes: bytes,
          fileName: fileName,
          durationSeconds: duration,
          localPath: filePath,
        );
      }
    } catch (e) {
      debugPrint('[ChatAudioRecorder] Stop error: $e');
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isRecording) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live Recording Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isCancelled
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.6)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isCancelled
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordDuration),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isCancelled
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isCancelled ? 'Thả để hủy' : '← Trượt để hủy',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isCancelled
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Active Mic Touch Target
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
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isCancelled
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
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
