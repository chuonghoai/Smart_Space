// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_staff/features/reports/providers/report_detail_provider.dart';
import 'package:smartspace_staff/features/reports/services/handle_report_background_service.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/home/home_controller.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/ui/mobile/reports/presentation/widgets/slide_to_confirm_button.dart';

class HandleReportScreen extends ConsumerStatefulWidget {
  final String reportId;

  const HandleReportScreen({super.key, required this.reportId});

  @override
  ConsumerState<HandleReportScreen> createState() => _HandleReportScreenState();
}

class _HandleReportScreenState extends ConsumerState<HandleReportScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final GlobalKey _sliderKey = GlobalKey();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      debugPrint('[HandleReport] Error picking image from camera: $e');
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 80);
      if (photos.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(photos);
        });
      }
    } catch (e) {
      debugPrint('[HandleReport] Error picking images from gallery: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final note = _noteController.text.trim();

    if (_selectedImages.isEmpty) {
      Toast.show(ToastType.warning, l10n.provideEvidencePhotoWarning);
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Read image bytes quickly in memory
      List<Uint8List> imageBytesList = [];
      List<String> fileNames = [];
      for (final img in _selectedImages) {
        final Uint8List bytes = await img.readAsBytes();
        imageBytesList.add(bytes);
        fileNames.add(
          img.name.isNotEmpty
              ? img.name
              : 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final container = ProviderScope.containerOf(context);

      // 2. Start background upload and report completion
      handleReportBackgroundService.startHandlingReport(
        reportId: widget.reportId,
        note: note,
        images: imageBytesList,
        fileNames: fileNames,
        onSuccess: () {
          container.invalidate(reportDetailProvider(widget.reportId));
          container.read(homeControllerProvider.notifier).manualRefresh();
        },
      );

      if (!mounted) return;

      // 3. Immediately return to report detail screen
      context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Toast.show(ToastType.error, l10n.errorOccurred(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.handleReport),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Commission Notice Banner
                    () {
                      final report = ref.watch(reportDetailProvider(widget.reportId)).value;
                      if (report == null) return const SizedBox.shrink();

                      final formatter = NumberFormat('#,###', 'vi_VN');
                      final isDark = theme.brightness == Brightness.dark;

                      if (report.commissionAwarded == true) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.rehandlingNoExtraCommission,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (report.expectedCommission != null && report.expectedCommission! > 0) {
                        final formattedAmount = formatter.format(report.expectedCommission!);
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2E7D32).withOpacity(0.2)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF66BB6A).withOpacity(0.4)
                                  : const Color(0xFFA5D6A7),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on_outlined,
                                color: isDark
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFF2E7D32),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.commissionExpectedNotice(formattedAmount),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? const Color(0xFFC8E6C9)
                                        : const Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }(),

                    // Section 1: Evidence Photos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.evidencePhotosRequired,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '(${_selectedImages.length})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Actions to add images
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(l10n.takePhoto),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickImagesFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l10n.chooseFromGallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selected images preview grid/list
                    if (_selectedImages.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final imageFile = _selectedImages[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(
                                        imageFile.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(imageFile.path),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.evidencePhotos,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Section 2: Resolution Note
                    Text(
                      l10n.resolutionNote,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      maxLines: 5,
                      minLines: 3,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText: l10n.resolutionNoteHint,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Section 3: Bottom Slide To Confirm Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SlideToConfirmButton(
                key: _sliderKey,
                text: _isSubmitting
                    ? l10n.submittingReport
                    : l10n.slideToComplete,
                isLoading: _isSubmitting,
                enabled: !_isSubmitting && _selectedImages.isNotEmpty,
                onConfirmed: _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
