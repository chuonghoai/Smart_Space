import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';
import 'package:mobile_shared/util/media_download_service.dart';
import 'package:video_player/video_player.dart';

class ChatMediaGalleryViewer extends StatefulWidget {
  final String conversationId;
  final List<ChatMessageModel> initialMessages;
  final String initialUrl;
  final int initialPage;

  const ChatMediaGalleryViewer({
    super.key,
    required this.conversationId,
    required this.initialMessages,
    required this.initialUrl,
    this.initialPage = 1,
  });

  static void show({
    required BuildContext context,
    required String conversationId,
    required List<ChatMessageModel> initialMessages,
    required String initialUrl,
    int initialPage = 1,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatMediaGalleryViewer(
          conversationId: conversationId,
          initialMessages: initialMessages,
          initialUrl: initialUrl,
          initialPage: initialPage,
        ),
      ),
    );
  }

  @override
  State<ChatMediaGalleryViewer> createState() => _ChatMediaGalleryViewerState();
}

class _ChatMediaGalleryViewerState extends State<ChatMediaGalleryViewer> {
  late final List<MediaGalleryItem> _items;
  late final PageController _pageController;
  int _currentIndex = 0;
  int _galleryPage = 1;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;

  @override
  void initState() {
    super.initState();
    _galleryPage = widget.initialPage;
    _items = _extractMedia(widget.initialMessages);

    final initialIdx = _items.indexWhere((item) => item.url == widget.initialUrl);
    _currentIndex = initialIdx >= 0 ? initialIdx : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<MediaGalleryItem> _extractMedia(List<ChatMessageModel> messages) {
    final List<MediaGalleryItem> list = [];
    for (final m in messages) {
      if (m.isImage || m.isVideo) {
        if (m.messageMedia.isNotEmpty) {
          for (final media in m.messageMedia) {
            list.add(MediaGalleryItem(
              url: media.thumbnailUrl,
              isVideo: m.isVideo || media.fileType.contains('video'),
              fileName: media.fileName,
              createdAt: m.createdAt,
              messageId: m.id,
            ));
          }
        } else if (m.localMediaPath != null && m.localMediaPath!.isNotEmpty) {
          list.add(MediaGalleryItem(
            url: m.localMediaPath!,
            isVideo: m.isVideo,
            createdAt: m.createdAt,
            messageId: m.tempId,
          ));
        }
      }
    }
    return list;
  }

  Future<void> _fetchOlderMedia() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    setState(() => _isLoadingOlder = true);

    try {
      final nextPage = _galleryPage + 1;
      final res = await chatRepository.getMessages(
        widget.conversationId,
        page: nextPage,
        size: 20,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          final olderMsgs = res.data!;
          final olderMedia = _extractMedia(olderMsgs);

          final existingUrls = _items.map((i) => i.url).toSet();
          final newUniqueMedia =
              olderMedia.where((i) => !existingUrls.contains(i.url)).toList();

          setState(() {
            _items.addAll(newUniqueMedia);
            _galleryPage = nextPage;
            _hasMoreOlder = olderMsgs.length >= 20;
            _isLoadingOlder = false;
          });
        } else {
          setState(() {
            _isLoadingOlder = false;
            _hasMoreOlder = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOlder = false);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Background paging trigger when approaching the end of loaded media
    if (index >= _items.length - 2 && _hasMoreOlder && !_isLoadingOlder) {
      _fetchOlderMedia();
    }
  }

  void _showOptionsBottomSheet() {
    if (_items.isEmpty || _currentIndex >= _items.length) return;
    final item = _items[_currentIndex];
    final sharedL10n = SharedLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    sharedL10n?.downloadMedia ?? 'Tải xuống',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _downloadMedia(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _downloadMedia(MediaGalleryItem item) {
    final sharedL10n = SharedLocalizations.of(context);
    mediaDownloadService.downloadMedia(
      item,
      downloadingText: sharedL10n?.downloadingMedia ?? 'Đang tải xuống...',
      successText: sharedL10n?.downloadSuccess ?? 'Đã lưu vào thiết bị thành công',
      failedText: sharedL10n?.downloadFailed ?? 'Tải xuống thất bại',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_items.isEmpty)
            const Center(
              child: SizedBox.shrink(),
            )
          else
            PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = _items[index];
                if (item.isVideo) {
                  return _VideoViewerItem(videoUrl: item.url);
                } else {
                  return _ImageViewerItem(imageUrl: item.url);
                }
              },
            ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    if (_items.isNotEmpty)
                      Text(
                        '${_currentIndex + 1} / ${_items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    const Spacer(),
                    if (_isLoadingOlder)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      onPressed: _showOptionsBottomSheet,
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
}

class _ImageViewerItem extends StatelessWidget {
  final String imageUrl;

  const _ImageViewerItem({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}

class _VideoViewerItem extends StatefulWidget {
  final String videoUrl;

  const _VideoViewerItem({required this.videoUrl});

  @override
  State<_VideoViewerItem> createState() => _VideoViewerItemState();
}

class _VideoViewerItemState extends State<_VideoViewerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    final file = File(widget.videoUrl);
    if (file.existsSync()) {
      _controller = VideoPlayerController.file(file);
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
        _controller.play();
        _startHideTimer();
      }
    }).catchError((err) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (!mounted || !_controller.value.isInitialized) return;
    final newPos = _controller.value.position;
    final newDur = _controller.value.duration;
    if (newPos != _position || newDur != _duration) {
      setState(() {
        _position = newPos;
        _duration = newDur;
      });
    }
    // If video reached the end, ensure controls stay visible
    if (_controller.value.isInitialized && newPos >= newDur && !_controller.value.isPlaying) {
      _hideTimer?.cancel();
      if (!_showControls) {
        setState(() => _showControls = true);
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _controller.value.isPlaying) {
      _startHideTimer();
    }
  }

  void _seekRelative(int seconds) {
    if (!_controller.value.isInitialized) return;
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    _controller.seekTo(clamped);
    if (_controller.value.isPlaying) {
      _startHideTimer();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedL10n = SharedLocalizations.of(context);

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 56),
            const SizedBox(height: 12),
            Text(
              sharedL10n?.cannotPlayVideo ?? 'Không thể phát video',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),

              // Animated Controls Overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    color: Colors.black38,
                    child: Stack(
                      children: [
                        // Center Action Buttons (-10s, Play/Pause, +10s)
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                                tooltip: sharedL10n?.seekBack10s ?? 'Lùi 10 giây',
                                onPressed: () => _seekRelative(-10),
                              ),
                              const SizedBox(width: 24),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  iconSize: 52,
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_controller.value.isPlaying) {
                                        _controller.pause();
                                        _hideTimer?.cancel();
                                      } else {
                                        _controller.play();
                                        _startHideTimer();
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                                tooltip: sharedL10n?.seekForward10s ?? 'Tua tới 10 giây',
                                onPressed: () => _seekRelative(10),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Seeker & Time Bar
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  trackHeight: 3,
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: _duration.inMilliseconds.toDouble() > 0
                                      ? _duration.inMilliseconds.toDouble()
                                      : 1.0,
                                  value: _position.inMilliseconds.toDouble().clamp(
                                        0.0,
                                        _duration.inMilliseconds.toDouble() > 0
                                            ? _duration.inMilliseconds.toDouble()
                                            : 1.0,
                                      ),
                                  onChanged: (val) {
                                    _controller.seekTo(Duration(milliseconds: val.toInt()));
                                    if (_controller.value.isPlaying) {
                                      _startHideTimer();
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }
}
