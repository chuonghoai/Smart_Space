import 'package:flutter/material.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:video_player/video_player.dart';

class MediaGalleryItem {
  final String url;
  final bool isVideo;
  final String? fileName;
  final DateTime? createdAt;
  final String? messageId;

  const MediaGalleryItem({
    required this.url,
    required this.isVideo,
    this.fileName,
    this.createdAt,
    this.messageId,
  });
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_items.isEmpty)
            const Center(
              child: Text(
                'Không tìm thấy media',
                style: TextStyle(color: Colors.white70),
              ),
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
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      }).catchError((err) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white54, size: 56),
            SizedBox(height: 12),
            Text('Không thể phát video', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 0.8,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
