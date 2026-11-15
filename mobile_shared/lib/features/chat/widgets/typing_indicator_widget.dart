import 'package:flutter/material.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final String? partnerName;
  final String typingText;

  const TypingIndicatorWidget({
    super.key,
    this.partnerName,
    this.typingText = 'đang nhập...',
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      margin: const EdgeInsets.only(left: 16, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.partnerName != null && widget.partnerName!.isNotEmpty
                ? '${widget.partnerName} ${widget.typingText}'
                : widget.typingText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay).remainder(1.0);
                  final scale = value > 0 && value < 0.5 ? 1.0 + (value * 1.2) : 1.0;
                  final opacity = value > 0 && value < 0.5 ? 0.9 : 0.4;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

