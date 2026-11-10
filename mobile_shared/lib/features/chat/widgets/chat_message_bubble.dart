import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/features/chat/models/linked_report_model.dart';
import 'package:mobile_shared/features/chat/widgets/chat_media_gallery_viewer.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;
  final String? retryTooltip;
  final List<ChatMessageModel>? conversationMessages;
  final String? conversationId;
  final ValueChanged<LinkedReportModel>? onTapReport;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
    this.retryTooltip,
    this.conversationMessages,
    this.conversationId,
    this.onTapReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharedL10n = SharedLocalizations.of(context);
    final retryText = retryTooltip ?? sharedL10n?.sendMessageFailed ?? 'Gửi tin nhắn thất bại, bấm để thử lại';

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.content,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    final bubbleBg = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final timeColor = isMe
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe && message.isFailed)
            IconButton(
              icon: Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
              tooltip: retryText,
              onPressed: onRetry,
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: borderRadius,
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(context, theme, textColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Spacer(),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: timeColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            if (message.isSending)
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: timeColor,
                                ),
                              )
                            else if (!message.isFailed) ...[
                              if (message.isRead)
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 13,
                                  color: isMe ? Colors.lightBlueAccent : theme.colorScheme.primary,
                                )
                              else
                                Icon(
                                  Icons.done_rounded,
                                  size: 13,
                                  color: timeColor,
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, Color textColor) {
    if (message.isImage || message.isVideo) {
      return _buildMediaBubble(context, theme);
    } else if (message.isAudio) {
      return _buildAudioBubble(context, theme, textColor);
    } else if (message.isReport) {
      return _buildReportBubble(context, theme, textColor);
    }

    // Standard text message
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildMediaBubble(BuildContext context, ThemeData theme) {
    final mediaUrl = message.messageMedia.isNotEmpty
        ? message.messageMedia.first.thumbnailUrl
        : '';
    final localPath = message.localMediaPath;
    final isVideo = message.isVideo;

    Widget imageWidget;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      imageWidget = Image.file(
        File(localPath),
        width: 240,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (mediaUrl.isNotEmpty) {
      imageWidget = Image.network(
        mediaUrl,
        width: 240,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 240,
            height: 200,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 240,
          height: 200,
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.white70),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        width: 240,
        height: 200,
        color: Colors.black26,
        child: const Center(
          child: Icon(Icons.photo_outlined, size: 40, color: Colors.white70),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (!message.isSending && (mediaUrl.isNotEmpty || (localPath != null && localPath.isNotEmpty))) {
          ChatMediaGalleryViewer.show(
            context: context,
            conversationId: conversationId ?? message.conversationId,
            initialMessages: conversationMessages ?? [message],
            initialUrl: mediaUrl.isNotEmpty ? mediaUrl : localPath!,
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          imageWidget,
          if (isVideo && !message.isSending)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          if (message.isSending)
            Container(
              width: 240,
              height: 200,
              color: Colors.black45,
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioBubble(BuildContext context, ThemeData theme, Color textColor) {
    final audioUrl = message.messageMedia.isNotEmpty
        ? message.messageMedia.first.thumbnailUrl
        : '';
    final localPath = message.localMediaPath;
    final durationSeconds = int.tryParse(message.content) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: _AudioMessagePlayer(
        audioUrl: audioUrl,
        localPath: localPath,
        durationSeconds: durationSeconds,
        isMe: isMe,
        textColor: textColor,
        isSending: message.isSending,
      ),
    );
  }

  Widget _buildReportBubble(BuildContext context, ThemeData theme, Color textColor) {
    final report = message.report;
    final reportTitle = report?.title ?? message.content;
    final reportStatus = report?.status ?? 'PROCESSING';
    final reportSeverity = report?.severity;

    return InkWell(
      onTap: () {
        if (report != null && onTapReport != null) {
          onTapReport!(report);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Phản ánh đính kèm',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (report?.imageUrl != null && report!.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              reportTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.25)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reportStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (reportSeverity != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.2)
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reportSeverity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final String? localPath;
  final int durationSeconds;
  final bool isMe;
  final Color textColor;
  final bool isSending;

  const _AudioMessagePlayer({
    required this.audioUrl,
    this.localPath,
    required this.durationSeconds,
    required this.isMe,
    required this.textColor,
    required this.isSending,
  });

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _totalDuration = Duration(seconds: widget.durationSeconds);

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _player.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) {
        setState(() {
          _totalDuration = d;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.isSending) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      Source source;
      if (widget.localPath != null &&
          widget.localPath!.isNotEmpty &&
          File(widget.localPath!).existsSync()) {
        source = DeviceFileSource(widget.localPath!);
      } else if (widget.audioUrl.isNotEmpty) {
        source = UrlSource(widget.audioUrl);
      } else {
        return;
      }
      await _player.play(source);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? (_position.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 24,
            color: widget.isMe ? Colors.white : null,
          ),
          style: IconButton.styleFrom(
            backgroundColor: widget.isMe
                ? Colors.white.withValues(alpha: 0.25)
                : null,
          ),
          onPressed: _togglePlay,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: widget.isMe
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isMe ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_totalDuration)}',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
