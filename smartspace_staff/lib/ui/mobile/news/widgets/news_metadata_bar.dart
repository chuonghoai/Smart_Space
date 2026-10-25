import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsMetadataBar extends StatelessWidget {
  final String authorName;
  final DateTime? createdAt;
  final bool compact;

  const NewsMetadataBar({
    super.key,
    required this.authorName,
    required this.createdAt,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt!)
        : '--/--/----';
    final timeStr = createdAt != null
        ? DateFormat('HH:mm').format(createdAt!)
        : '--:--';

    final effectiveAuthor = authorName.trim().isNotEmpty
        ? authorName.trim()
        : 'Admin';

    final double fontSize = compact ? 12.0 : 13.0;
    final double iconSize = compact ? 14.0 : 15.0;
    final Color iconColor = colorScheme.primary;
    final Color authorColor = colorScheme.onSurface;
    final Color secondaryColor = colorScheme.onSurfaceVariant;

    return Wrap(
      spacing: compact ? 12 : 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. Tác giả: In đậm
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Text(
              effectiveAuthor,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
                color: authorColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // 2. Ngày tạo: In nghiêng
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                color: secondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // 3. Giờ tạo: In nghiêng
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                color: secondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
