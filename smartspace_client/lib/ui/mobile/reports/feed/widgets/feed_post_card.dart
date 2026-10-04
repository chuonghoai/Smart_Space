import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_client/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:smartspace_client/ui/shared/image/app_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// Read-only, social-style post for one public report.
class FeedPostCard extends StatefulWidget {
  final ReportFeedItem item;
  final VoidCallback onTap;

  const FeedPostCard({super.key, required this.item, required this.onTap});

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = widget.item.report;
    final anonymous = r.isAnonymous || widget.item.reporterName == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: reporter avatar + name + relative time + severity badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.secondaryContainer,
                    child: anonymous || widget.item.reporterAvatarUrl == null
                        ? Icon(
                            anonymous ? Icons.visibility_off_outlined : Icons.person_outline,
                            size: 20,
                            color: cs.onSecondaryContainer,
                          )
                        : AppNetworkImage(
                            url: widget.item.reporterAvatarUrl,
                            width: 40,
                            height: 40,
                            isCircle: true,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anonymous ? l10n.feedAnonymous : widget.item.reporterName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontStyle: anonymous ? FontStyle.italic : null,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          _timeAgo(r.createdAt, l10n),
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _SeverityChip(
                    color: r.severity.getColor(context),
                    label: r.severity.getLocalizedText(l10n),
                  ),
                ],
              ),
            ),

            // 2. Content: Title + Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.3,
                    ),
                  ),
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, c) {
                        final style = theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        );
                        final tp = TextPainter(
                          text: TextSpan(text: r.description, style: style),
                          maxLines: 3,
                          textDirection: Directionality.of(context),
                        )..layout(maxWidth: c.maxWidth);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.description,
                              style: style,
                              maxLines: _expanded ? null : 3,
                              overflow: _expanded ? null : TextOverflow.ellipsis,
                            ),
                            if (!_expanded && tp.didExceedMaxLines)
                              GestureDetector(
                                onTap: () => setState(() => _expanded = true),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    l10n.feedSeeMore,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // 3. Idea 1: Gallery ảnh 16:9 + Huy hiệu kính mờ (Frosted glass)
            if (r.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Gallery16x9(urls: r.imageUrls),
              ),
            ],

            // 4. Location & Distance Chip
            if ((r.address ?? '').isNotEmpty || r.distanceInMeters != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((r.address ?? '').isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.place_outlined, size: 16, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.address!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (r.distanceInMeters != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_outlined, size: 12, color: cs.onSecondaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              '${(r.distanceInMeters! / 1000).toStringAsFixed(1)} ${l10n.unitKilometer}',
                              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSecondaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // 5. Idea 2: Thanh tiến trình Segment Bar gọn nhẹ
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _SegmentedProgressBar(status: r.status),
            ),

            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),

            // 6. Idea 3: Hàng nút tiện ích (Xem trên bản đồ & Chia sẻ)
            _CardUtilityBar(
              latitude: r.latitude,
              longitude: r.longitude,
              title: r.title,
              address: r.address,
              reportId: r.id,
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} ${l10n.dayAgo}';
    if (diff.inHours > 0) return '${diff.inHours}${l10n.hourAgo}';
    if (diff.inMinutes > 0) return '${diff.inMinutes}${l10n.minuteAgo}';
    return l10n.justNow;
  }
}

class _SeverityChip extends StatelessWidget {
  final Color color;
  final String label;

  const _SeverityChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Gallery ảnh chuẩn 16:9, hỗ trợ vuốt lướt ảnh và kèm huy hiệu kính mờ (Frosted Glass).
class _Gallery16x9 extends StatefulWidget {
  final List<String> urls;

  const _Gallery16x9({required this.urls});

  @override
  State<_Gallery16x9> createState() => _Gallery16x9State();
}

class _Gallery16x9State extends State<_Gallery16x9> {
  int _currentIndex = 0;

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          imageUrls: widget.urls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = widget.urls.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Swipeable Carousel
            PageView.builder(
              itemCount: total,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => _openViewer(i),
                  child: AppNetworkImage(url: widget.urls[i]),
                );
              },
            ),

            // Frosted Glass Pill Badge ở góc dưới bên phải
            if (total > 1)
              Positioned(
                bottom: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            '${_currentIndex + 1}/$total',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Badge nếu chỉ có 1 ảnh
            if (total == 1)
              Positioned(
                bottom: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: Colors.black.withValues(alpha: 0.35),
                      child: Text(
                        l10n.feedPhotosCount(1),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 10,
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

/// Thanh tiến trình Segment Bar gọn nhẹ (3 vạch ngang tinh tế + Trạng thái hiện tại).
class _SegmentedProgressBar extends StatelessWidget {
  final ReportStatus status;

  const _SegmentedProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final stepIndex = switch (status) {
      ReportStatus.processed => 3,
      ReportStatus.processing => 2,
      _ => 1,
    };

    final statusColor = status.getColor(context);
    final inactiveColor = cs.surfaceContainerHighest.withValues(alpha: 0.7);

    Widget buildSegment(int step) {
      final isDone = stepIndex >= step;
      return Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isDone ? statusColor : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            buildSegment(1),
            buildSegment(2),
            buildSegment(3),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status.getLocalizedText(l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$stepIndex/3',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hàng nút tiện ích: Xem trên bản đồ (Google Maps) và Chia sẻ (Copy thông tin).
class _CardUtilityBar extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;
  final String? address;
  final String reportId;

  const _CardUtilityBar({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.address,
    required this.reportId,
  });

  Future<void> _openMap(BuildContext context) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        Toast.show(ToastType.warning, AppLocalizations.of(context)!.cannotOpenGoogleMapsError);
      }
    }
  }

  void _shareReport(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shareContent = StringBuffer();
    shareContent.writeln('[$title]');
    if (address != null && address!.isNotEmpty) {
      shareContent.writeln(address);
    }
    shareContent.write('https://smartspace.vn/reports/$reportId');

    Clipboard.setData(ClipboardData(text: shareContent.toString()));
    Toast.show(ToastType.success, l10n.feedCopiedLink);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Nút xem bản đồ
          Expanded(
            child: TextButton.icon(
              onPressed: () => _openMap(context),
              icon: Icon(Icons.explore_outlined, size: 18, color: cs.primary),
              label: Text(
                l10n.feedViewOnMap,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Container(
            height: 16,
            width: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          // Nút chia sẻ
          Expanded(
            child: TextButton.icon(
              onPressed: () => _shareReport(context),
              icon: Icon(Icons.share_outlined, size: 18, color: cs.onSurfaceVariant),
              label: Text(
                l10n.feedShare,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
