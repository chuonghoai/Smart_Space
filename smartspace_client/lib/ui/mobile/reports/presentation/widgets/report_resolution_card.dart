import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/widgets/fullscreen_image_viewer.dart';

/// Hiển thị kết quả xử lý của staff (ghi chú + ảnh minh chứng + thời gian hoàn thành).
///
/// - `compact = false`: dùng trong màn chi tiết phản ánh (ghi chú đầy đủ, ảnh lớn).
/// - `compact = true`: dùng trong popup đánh giá (ghi chú rút gọn, ảnh thumbnail nhỏ).
class ReportResolutionCard extends StatelessWidget {
  final String? note;
  final List<String> imageUrls;
  final DateTime? resolvedAt;
  final bool compact;

  const ReportResolutionCard({
    super.key,
    required this.note,
    required this.imageUrls,
    this.resolvedAt,
    this.compact = false,
  });

  /// Chỉ hiển thị khi staff thực sự để lại ghi chú hoặc ảnh, tránh thẻ rỗng.
  static bool hasContent(String? note, List<String> imageUrls) =>
      (note != null && note.trim().isNotEmpty) || imageUrls.isNotEmpty;

  void _openImage(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final success = AppSemanticColors.of(context).success;
    final trimmedNote = note?.trim();
    final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
    final thumbSize = compact ? 64.0 : 96.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt_rounded, size: 18, color: success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.resolutionInfo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: success,
                  ),
                ),
              ),
            ],
          ),
          if (resolvedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.resolvedAtLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(resolvedAt!.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (hasNote) ...[
            SizedBox(height: compact ? 8 : 12),
            if (!compact)
              Text(
                l10n.resolutionNote,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (!compact) const SizedBox(height: 4),
            Text(
              trimmedNote,
              maxLines: compact ? 4 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ],
          if (imageUrls.isNotEmpty) ...[
            SizedBox(height: compact ? 10 : 12),
            if (!compact) ...[
              Text(
                '${l10n.resolutionImages} (${imageUrls.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: thumbSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Semantics(
                    button: true,
                    label: '${l10n.resolutionImages} ${index + 1}/${imageUrls.length}',
                    child: GestureDetector(
                      onTap: () => _openImage(context, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
