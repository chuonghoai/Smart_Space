import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/news/application/news_providers.dart';
import 'package:smartspace_admin/features/news/data/news_repository.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/news/utils/markdown_helpers.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/markdown_toolbar.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AdminCreateEditNewsScreen extends ConsumerStatefulWidget {
  final String? newsId;

  const AdminCreateEditNewsScreen({super.key, this.newsId});

  @override
  ConsumerState<AdminCreateEditNewsScreen> createState() =>
      _AdminCreateEditNewsScreenState();
}

class _AdminCreateEditNewsScreenState
    extends ConsumerState<AdminCreateEditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = MarkdownAutoListEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isInitializing = false;

  // Notification Targeting State
  bool _sendNotification = false;
  bool _targetAdmin = true;
  bool _targetStaff = true;
  bool _targetClient = true;

  bool get _targetAll => _targetAdmin && _targetStaff && _targetClient;

  void _onToggleTargetAll(bool? val) {
    final newVal = val ?? false;
    setState(() {
      _targetAdmin = newVal;
      _targetStaff = newVal;
      _targetClient = newVal;
    });
  }

  final List<String> _existingImageUrls = [];
  final List<Uint8List> _newImageBytes = [];
  final List<String> _newImageNames = [];

  bool get isEdit => widget.newsId != null && widget.newsId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    if (isEdit) {
      _loadExistingNews();
    }
  }

  void _onContentChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadExistingNews() async {
    setState(() => _isInitializing = true);
    try {
      final res = await newsRepository.getNewsDetail(widget.newsId!);
      if (res.success && res.data != null) {
        final news = res.data!;
        _titleController.text = news.title;
        _contentController.text = news.content;
        _existingImageUrls.addAll(news.imageUrls);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          _newImageBytes.add(bytes);
          _newImageNames.add(file.name);
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      // 1. Upload new images to Cloudinary via mobile_shared mediaUploadUtil
      List<String> uploadedUrls = List.from(_existingImageUrls);
      for (int i = 0; i < _newImageBytes.length; i++) {
        final url = await mediaUploadUtil.uploadMedia(
          _newImageBytes[i],
          _newImageNames[i],
        );
        if (url.isNotEmpty) {
          uploadedUrls.add(url);
        }
      }

      // 2. Call API Create or Update
      if (isEdit) {
        final res = await newsRepository.updateNews(
          id: widget.newsId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrls: uploadedUrls,
        );
        if (!res.success) throw Exception(res.message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.updateNewsSuccess)),
          );
        }
      } else {
        List<String> targetRoles = [];
        if (_sendNotification) {
          if (_targetAdmin) targetRoles.add('admin');
          if (_targetStaff) targetRoles.add('staff');
          if (_targetClient) targetRoles.add('client');
        }

        final res = await newsRepository.createNews(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrls: uploadedUrls,
          sendNotification: _sendNotification,
          targetRoles: targetRoles,
        );
        if (!res.success) throw Exception(res.message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.createNewsSuccess)),
          );
        }
      }

      // 3. Refresh providers and return
      ref.invalidate(newsListProvider);
      if (isEdit) {
        ref.invalidate(newsDetailProvider(widget.newsId!));
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isInitializing) {
      return const AppLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEdit ? l10n.editNews : l10n.createNewNews,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _saveNews,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(l10n.submit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tiêu đề
                  Text(
                    l10n.newsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.newsTitleHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.newsTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Hình ảnh (Tương tự Facebook post creator)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.newsImages,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(l10n.addImages),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildImagePreviewList(theme, colorScheme),
                  const SizedBox(height: 20),

                  // Tùy chọn Gửi Thông Báo (Chỉ hiển thị khi tạo mới)
                  if (!isEdit) ...[
                    _buildNotificationTargetCard(l10n, theme, colorScheme, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Nội dung (Content) + Live Preview song song / nối tiếp
                  Text(
                    l10n.newsContent,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;

                      final editorWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarkdownToolbar(controller: _contentController),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _contentController,
                            maxLines: null,
                            minLines: 12,
                            decoration: InputDecoration(
                              hintText: l10n.newsContentHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.newsContentRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      );

                      final previewWidget = Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 280),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceVariant.withOpacity(0.3)
                              : colorScheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.livePreview,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _contentController.text.trim().isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 36.0),
                                    child: Center(
                                      child: Text(
                                        l10n.newsContentHint,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : MarkdownBody(
                                    data: formatMarkdownPreservingNewlines(
                                        _contentController.text),
                                    selectable: true,
                                  ),
                          ],
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: editorWidget),
                            const SizedBox(width: 16),
                            Expanded(child: previewWidget),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            editorWidget,
                            const SizedBox(height: 16),
                            previewWidget,
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTargetCard(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceVariant.withOpacity(0.2)
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            value: _sendNotification,
            onChanged: (val) => setState(() => _sendNotification = val),
            secondary: Icon(
              Icons.notifications_active_outlined,
              color: _sendNotification ? colorScheme.primary : colorScheme.outline,
            ),
            title: Text(
              l10n.sendNotification,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              l10n.sendNotificationSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
          if (_sendNotification) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notificationTarget,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Checkbox "Tất cả"
                  InkWell(
                    onTap: () => _onToggleTargetAll(!_targetAll),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _targetAll,
                            onChanged: _onToggleTargetAll,
                          ),
                          Text(
                            l10n.targetAll,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  // Checkboxes: Admin, Nhân viên, Khách hàng
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      InkWell(
                        onTap: () =>
                            setState(() => _targetAdmin = !_targetAdmin),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _targetAdmin,
                                onChanged: (val) {
                                  setState(() => _targetAdmin = val ?? false);
                                },
                              ),
                              Text(l10n.targetAdmin),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _targetStaff = !_targetStaff),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _targetStaff,
                                onChanged: (val) {
                                  setState(() => _targetStaff = val ?? false);
                                },
                              ),
                              Text(l10n.targetStaff),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _targetClient = !_targetClient),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _targetClient,
                                onChanged: (val) {
                                  setState(() => _targetClient = val ?? false);
                                },
                              ),
                              Text(l10n.targetClient),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreviewList(ThemeData theme, ColorScheme colorScheme) {
    final totalImages = _existingImageUrls.length + _newImageBytes.length;

    if (totalImages == 0) {
      return InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.6),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.addImages,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing URLs
          ...List.generate(_existingImageUrls.length, (index) {
            final url = _existingImageUrls[index];
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12, top: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppNetworkImage(
                    url: url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _existingImageUrls.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          // Newly picked bytes
          ...List.generate(_newImageBytes.length, (index) {
            final bytes = _newImageBytes[index];
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12, top: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    bytes,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _newImageBytes.removeAt(index);
                        _newImageNames.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          // Add more button
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.6),
                ),
              ),
              child: Icon(
                Icons.add,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
