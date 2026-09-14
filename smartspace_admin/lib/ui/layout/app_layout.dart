import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/components/sidebar.dart';
import 'package:smartspace_admin/ui/components/top_bar.dart';

/// AppLayout — Responsive layout
/// - Web (kIsWeb): Fixed sidebar trái + content phải, sidebar collapse được
/// - Mobile: Drawer sidebar truyền thống
class AppLayout extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? customAppBar;
  final bool showDrawer;

  const AppLayout({
    super.key,
    required this.child,
    this.customAppBar,
    this.showDrawer = true,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {
  bool _sidebarExpanded = true;

  static const double _expandedWidth = 280;
  static const double _collapsedWidth = 72;

  @override
  Widget build(BuildContext context) {
    // Mobile → Drawer layout giữ nguyên
    if (!kIsWeb) {
      return Scaffold(
        appBar: widget.customAppBar ?? const TopBar(),
        drawer: widget.showDrawer ? const Sidebar() : null,
        body: widget.child,
      );
    }

    // Web → Fixed sidebar + content
    final theme = Theme.of(context);
    final sidebarWidth =
        _sidebarExpanded ? _expandedWidth : _collapsedWidth;

    return Scaffold(
      body: Row(
        children: [
          // Fixed Sidebar
          if (widget.showDrawer)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: sidebarWidth,
              child: Material(
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    // Toggle button
                    Container(
                      height: kToolbarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: _sidebarExpanded
                          ? Alignment.centerRight
                          : Alignment.center,
                      child: IconButton(
                        icon: Icon(
                          _sidebarExpanded
                              ? Icons.menu_open
                              : Icons.menu,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _sidebarExpanded = !_sidebarExpanded;
                          });
                        },
                        tooltip: _sidebarExpanded ? 'Thu gọn' : 'Mở rộng',
                      ),
                    ),
                    const Divider(height: 1),
                    // Sidebar content
                    Expanded(
                      child: WebSidebar(
                        isExpanded: _sidebarExpanded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Vertical divider
          if (widget.showDrawer)
            VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top bar
                widget.customAppBar ?? const TopBar(showMenuButton: false),
                // Content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
