import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/shared/components/connection_indicator.dart';

class WebTopBar extends StatefulWidget implements PreferredSizeWidget {
  const WebTopBar({super.key});

  @override
  State<WebTopBar> createState() => _WebTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _WebTopBarState extends State<WebTopBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: widget.preferredSize.height,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Empty space or breadcrumbs can go here
          const Spacer(),

          // Modern Search Box
          Builder(
            builder: (context) {
              final radius = BorderRadius.circular(50);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isFocused ? 400 : 300,
                decoration: BoxDecoration(
                  color: _isFocused
                      ? theme.colorScheme.surface
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: radius,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: _isFocused
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: TextField(
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaceholder,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 22,
                      color: _isFocused
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    // TODO: implement search logic
                  },
                ),
              );
            },
          ),

          const Spacer(),

          // Actions
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: ConnectionIndicator(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
