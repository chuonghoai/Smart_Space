import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/util/media_upload.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class ReportReviewDialog extends StatefulWidget {
  final String reportId;
  final VoidCallback onReviewSubmitted;

  const ReportReviewDialog({
    super.key,
    required this.reportId,
    required this.onReviewSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String reportId,
    required VoidCallback onReviewSubmitted,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReportReviewDialog(
        reportId: reportId,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<ReportReviewDialog> createState() => _ReportReviewDialogState();
}

class _ReportReviewDialogState extends State<ReportReviewDialog> {
  bool? _isResolved; // null: not selected yet, true: resolved, false: unresolved
  int _rating = 5; // default 5 stars if resolved
  final TextEditingController _reasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_isResolved == null) return false;
    if (_isResolved == true) {
      return _rating >= 1 && _rating <= 5;
    } else {
      return _reasonController.text.trim().isNotEmpty && _selectedImages.isNotEmpty;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(source: source, imageQuality: 80);
        if (photo != null && mounted) {
          setState(() => _selectedImages.add(photo));
        }
      } else {
        final photos = await _picker.pickMultiImage(imageQuality: 80);
        if (photos.isNotEmpty && mounted) {
          setState(() => _selectedImages.addAll(photos));
        }
      }
    } catch (e) {
      debugPrint('[ReportReview] Error picking image: $e');
    }
  }

  void _showImageSourceActionSheet() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                title: Text(l10n.cameraOption),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
                title: Text(l10n.galleryOption),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      List<String>? uploadedUrls;
      if (_isResolved == false && _selectedImages.isNotEmpty) {
        uploadedUrls = [];
        for (final img in _selectedImages) {
          final bytes = await img.readAsBytes();
          final url = await mediaUploadUtil.uploadMedia(bytes, img.name);
          uploadedUrls.add(url);
        }
      }

      final response = await reportService.submitReview(
        widget.reportId,
        isResolved: _isResolved!,
        rating: _isResolved == true ? _rating : null,
        reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
        imageUrls: uploadedUrls,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reviewSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onReviewSubmitted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reviewReport,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question
              Text(
                l10n.reviewQuestion,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Two Choice Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _isResolved == true
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        side: BorderSide(
                          color: _isResolved == true
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: _isResolved == true ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _isResolved = true),
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: _isResolved == true
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        l10n.reviewResolvedOption,
                        style: TextStyle(
                          color: _isResolved == true
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _isResolved == false
                            ? theme.colorScheme.errorContainer
                            : Colors.transparent,
                        side: BorderSide(
                          color: _isResolved == false
                              ? theme.colorScheme.error
                              : theme.colorScheme.outlineVariant,
                          width: _isResolved == false ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _isResolved = false),
                      icon: Icon(
                        Icons.highlight_off,
                        color: _isResolved == false
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        l10n.reviewUnresolvedOption,
                        style: TextStyle(
                          color: _isResolved == false
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Resolved Flow: Star rating
              if (_isResolved == true) ...[
                Text(
                  l10n.rateStaffSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      iconSize: 36,
                      onPressed: _isSubmitting ? null : () => setState(() => _rating = starValue),
                      icon: Icon(
                        starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
              ],

              // Unresolved Flow: Reason text + Photo attachments
              if (_isResolved == false) ...[
                Text(
                  l10n.unresolvedReasonLabel,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.unresolvedReasonHint,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Images section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.attachEvidencePhotos,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _selectedImages.isEmpty ? theme.colorScheme.error : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _showImageSourceActionSheet,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(l10n.cameraOption),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_selectedImages.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.error.withAlpha(128),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.errorContainer.withAlpha(40),
                    ),
                    child: Center(
                      child: Text(
                        l10n.attachEvidencePhotoHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = _selectedImages[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List>(
                                future: file.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Container(
                                    width: 84,
                                    height: 84,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: _isSubmitting ? null : () => setState(() => _selectedImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(160),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.submittingReview),
                        ],
                      )
                    : Text(
                        l10n.submitReview,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
