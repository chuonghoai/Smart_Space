import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/shared/image/person_avatar.dart';

class RankedBarItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final int value;

  /// Dòng phụ dưới thanh, vd: "12 đã xử lý / 30 ngày".
  final String? subtitle;

  const RankedBarItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.value,
    this.subtitle,
  });
}

/// Danh sách xếp hạng dạng thanh ngang: hạng, avatar, tên, thanh tỉ lệ, giá trị.
/// Thanh tỉ lệ theo giá trị lớn nhất trong danh sách.
class RankedBarList extends StatelessWidget {
  final List<RankedBarItem> items;
  final ValueChanged<RankedBarItem>? onTap;

  const RankedBarList({super.key, required this.items, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = items.map((e) => e.value).fold<int>(0, math.max);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          InkWell(
            onTap: onTap == null ? null : () => onTap!(items[i]),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PersonAvatar(
                    avatarUrl: items[i].avatarUrl,
                    name: items[i].name,
                    radius: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxValue == 0
                                ? 0
                                : items[i].value / maxValue,
                            minHeight: 6,
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        if (items[i].subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            items[i].subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${items[i].value}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
