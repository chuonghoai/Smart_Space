import 'package:flutter/material.dart';

class AnalyticsGuideSection {
  final String title;
  final String whatItIs;
  final String purpose;
  final String whatItTells;
  final Color? accent;

  const AnalyticsGuideSection({
    required this.title,
    required this.whatItIs,
    required this.purpose,
    required this.whatItTells,
    this.accent,
  });
}

void showAnalyticsGuideModal(
  BuildContext context, {
  required String title,
  required String whatLabel,
  required String purposeLabel,
  required String tellsLabel,
  required List<AnalyticsGuideSection> sections,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 720;
  if (isWide) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 620),
          child: _GuideContent(
            title: title,
            whatLabel: whatLabel,
            purposeLabel: purposeLabel,
            tellsLabel: tellsLabel,
            sections: sections,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
      ),
      child: _GuideContent(
        title: title,
        whatLabel: whatLabel,
        purposeLabel: purposeLabel,
        tellsLabel: tellsLabel,
        sections: sections,
        onClose: () => Navigator.of(ctx).pop(),
        showHandle: true,
      ),
    ),
  );
}

class _GuideContent extends StatelessWidget {
  final String title;
  final String whatLabel;
  final String purposeLabel;
  final String tellsLabel;
  final List<AnalyticsGuideSection> sections;
  final VoidCallback onClose;
  final bool showHandle;

  const _GuideContent({
    required this.title,
    required this.whatLabel,
    required this.purposeLabel,
    required this.tellsLabel,
    required this.sections,
    required this.onClose,
    this.showHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = sections[index];
              final accent = s.accent ?? cs.primary;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _BulletRow(
                      label: whatLabel,
                      text: s.whatItIs,
                      accent: accent,
                    ),
                    const SizedBox(height: 4),
                    _BulletRow(
                      label: purposeLabel,
                      text: s.purpose,
                      accent: accent,
                    ),
                    const SizedBox(height: 4),
                    _BulletRow(
                      label: tellsLabel,
                      text: s.whatItTells,
                      accent: accent,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String label;
  final String text;
  final Color accent;

  const _BulletRow({
    required this.label,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}
