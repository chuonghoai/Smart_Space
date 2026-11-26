import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Thanh trượt kích hoạt SOS: phải kéo hết ~90% mới gửi, thả sớm thì trượt về.
/// Trình đọc màn hình dùng thao tác chạm đúp kèm hộp thoại xác nhận thay cho kéo.
class SosSlideButton extends StatefulWidget {
  final VoidCallback onActivated;

  const SosSlideButton({super.key, required this.onActivated});

  @override
  State<SosSlideButton> createState() => _SosSlideButtonState();
}

class _SosSlideButtonState extends State<SosSlideButton> {
  static const double _height = 60;
  static const double _padding = 4;
  static const double _thumb = _height - _padding * 2;
  static const double _threshold = 0.9;
  static const double _thumbHitSlop = 32;

  double _offset = 0;
  bool _dragging = false;
  bool _canDrag = false;
  bool _passedHalf = false;
  bool _passedThreshold = false;
  bool _activated = false;

  void _onStart(DragStartDetails details) {
    if (_activated) return;
    final touchX = details.localPosition.dx;
    final thumbLeft = _padding + _offset;
    final thumbRight = thumbLeft + _thumb;
    _canDrag = touchX >= thumbLeft - _thumbHitSlop && touchX <= thumbRight + _thumbHitSlop;
    if (_canDrag) {
      setState(() => _dragging = true);
    }
  }

  void _onUpdate(DragUpdateDetails details, double maxOffset) {
    if (!_canDrag || _activated || maxOffset <= 0) return;
    final nextOffset = (_offset + details.delta.dx).clamp(0.0, maxOffset);
    setState(() {
      _dragging = true;
      _offset = nextOffset;
    });
    final half = nextOffset >= maxOffset * 0.5;
    if (half != _passedHalf) {
      _passedHalf = half;
      HapticFeedback.selectionClick();
    }
    final reached = nextOffset >= maxOffset * _threshold;
    if (reached && !_passedThreshold) {
      _passedThreshold = true;
      HapticFeedback.mediumImpact();
    } else if (!reached && _passedThreshold) {
      _passedThreshold = false;
    }
  }

  void _onEnd(double maxOffset) {
    if (!_canDrag && !_dragging) return;
    final activated = !_activated && maxOffset > 0 && _offset >= maxOffset * _threshold;
    setState(() {
      _dragging = false;
      _canDrag = false;
      _offset = activated ? maxOffset : 0;
      _passedHalf = false;
      _passedThreshold = false;
      if (activated) _activated = true;
    });
    if (!activated) return;
    HapticFeedback.heavyImpact();
    widget.onActivated();
    // Trả thanh về chỗ cũ khi người dùng quay lại màn hình
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _offset = 0;
          _activated = false;
        });
      }
    });
  }

  Future<void> _accessibleActivate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sosConfirmTitle),
        content: Text(l10n.sosConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(l10n.sosConfirmSend),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(_height / 2);

    return Semantics(
      button: true,
      label: l10n.sosSlideSemantics,
      hint: l10n.sosSlideLabel,
      onTap: _accessibleActivate,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final maxOffset = math.max(0.0, trackWidth - _thumb - _padding * 2);
          final clampedOffset = _offset.clamp(0.0, maxOffset);
          final progress = maxOffset > 0 ? (clampedOffset / maxOffset).clamp(0.0, 1.0) : 0.0;
          final labelOpacity = (1 - progress * 1.6).clamp(0.0, 1.0);
          final fillWidth = (_padding + _thumb + clampedOffset + _padding).clamp(0.0, trackWidth);

          return GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onStart,
            onHorizontalDragUpdate: (d) => _onUpdate(d, maxOffset),
            onHorizontalDragEnd: (_) => _onEnd(maxOffset),
            onHorizontalDragCancel: () => _onEnd(maxOffset),
            child: Container(
              width: trackWidth,
              height: _height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: radius,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Dải tô tiến trình theo tay kéo
                  AnimatedPositioned(
                    duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: progress > 0.01 ? fillWidth : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.16 + progress * 0.24),
                        borderRadius: radius,
                      ),
                    ),
                  ),
                  // Nhãn căn giữa cân đối với trục khung hình
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _thumb + _padding * 2),
                      child: Center(
                        child: Opacity(
                          opacity: labelOpacity,
                          child: Text(
                            l10n.sosSlideLabel,
                            textAlign: TextAlign.center,
                            style: textTheme.titleSmall?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Mũi tên chỉ hướng trượt ở mép phải (cân đối thị giác với nút tròn bên trái)
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: labelOpacity * 0.7,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: scheme.onErrorContainer.withValues(alpha: 0.55),
                            ),
                            Transform.translate(
                              offset: const Offset(-8, 0),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Nút tròn kéo SOS
                  AnimatedPositioned(
                    duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    left: _padding + clampedOffset,
                    top: _padding,
                    bottom: _padding,
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sos, color: scheme.onError, size: 26),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
