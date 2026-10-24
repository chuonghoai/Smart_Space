// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String text;
  final bool isLoading;
  final bool enabled;
  final double height;
  final IconData icon;

  const SlideToConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.text,
    this.isLoading = false,
    this.enabled = true,
    this.height = 56.0,
    this.icon = Icons.double_arrow_rounded,
  });

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _resetController.addListener(() {
      setState(() {
        _dragPosition = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!widget.enabled || widget.isLoading || _isConfirmed) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (!widget.enabled || widget.isLoading || _isConfirmed) return;

    // Threshold is 88% of max slide distance
    if (_dragPosition >= maxDrag * 0.88) {
      HapticFeedback.heavyImpact();
      setState(() {
        _dragPosition = maxDrag;
        _isConfirmed = true;
      });
      widget.onConfirmed();
    } else {
      // Animate back to start
      _resetAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _resetController,
        curve: Curves.easeOutCubic,
      ));
      _resetController.forward(from: 0.0);
    }
  }

  /// Reset the slider if needed externally
  void reset() {
    if (mounted) {
      setState(() {
        _isConfirmed = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = widget.height - 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = totalWidth - buttonSize - 8.0;

        return Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Highlight track behind slider thumb
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _dragPosition + (buttonSize / 2) + 4.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),

                // Center Label
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.height),
                    child: widget.isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.text,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.text,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),

                // Slider Thumb
                Positioned(
                  left: 4.0 + _dragPosition,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) =>
                        _onDragUpdate(details, maxDrag),
                    onHorizontalDragEnd: (details) =>
                        _onDragEnd(details, maxDrag),
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                _isConfirmed
                                    ? Icons.check_rounded
                                    : widget.icon,
                                color: theme.colorScheme.onPrimary,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
