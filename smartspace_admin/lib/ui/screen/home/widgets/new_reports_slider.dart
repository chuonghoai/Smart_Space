import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class NewReportsSlider extends ConsumerStatefulWidget {
  const NewReportsSlider({super.key});

  @override
  ConsumerState<NewReportsSlider> createState() => _NewReportsSliderState();
}

class _NewReportsSliderState extends ConsumerState<NewReportsSlider> {
  late final PageController _pageController;
  Timer? _refreshTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Định kỳ 5 phút lọc lại danh sách để loại bỏ các report đã tạo quá 1 tiếng
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool _isWithin1Hour(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      return !diff.isNegative && diff.inMinutes <= 60;
    } catch (_) {
      return false;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingReportsAsync = ref.watch(recentReportProvider('pending'));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return pendingReportsAsync.maybeWhen(
      data: (allPending) {
        // Lọc các report được tạo trong vòng 1 tiếng
        final newReports = allPending.where((r) => _isWithin1Hour(r.createdAt)).toList();

        if (newReports.isEmpty) {
          return const SizedBox.shrink();
        }

        // Đảm bảo _currentPage không vượt quá index lớn nhất
        if (_currentPage >= newReports.length) {
          _currentPage = newReports.length - 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.newReportsSectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF5C1D1D) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFFFF8A80).withValues(alpha: 0.5) : const Color(0xFFD32F2F).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${newReports.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _pageController,
                itemCount: newReports.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final report = newReports[index];
                  return _buildSliderCard(report, theme, isDark, l10n);
                },
              ),
            ),
            const SizedBox(height: 8),
            // Pagination controls (e.g. 1/8)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${newReports.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onPressed: _currentPage < newReports.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildSliderCard(
    RecentReportModel report,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final addressText = (report.address != null && report.address!.trim().isNotEmpty)
        ? report.address!
        : l10n.noAddress;

    return InkWell(
      onTap: () => context.push('/reports/${report.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.15 : 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Thumbnail
          AppNetworkImage(
            url: report.imageUrl,
            width: 75,
            height: 110,
            borderRadius: BorderRadius.circular(12),
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 75,
              height: 110,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_not_supported, size: 28),
            ),
            placeholderWidget: Container(
              width: 75,
              height: 110,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.report_problem_outlined, color: theme.primaryColor, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          // Info Details (Title, CreatedAt, Address) - NO status pending
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  report.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(report.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        addressText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
