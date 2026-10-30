import 'package:flutter/material.dart';

/// AppBar trong suốt nổi trên bản đồ (dùng với `extendBodyBehindAppBar: true`), chỉ có nút back.
///
/// [AppBar.forceMaterialTransparency] là bắt buộc: Material mặc định của AppBar (kể cả khi nền
/// trong suốt) nuốt mọi lần chạm trong vùng toolbar, làm hàng chip lọc và nút điều khiển
/// nằm bên dưới không bấm được.
class MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;

  const MapAppBar({super.key, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      forceMaterialTransparency: true,
      iconTheme: IconThemeData(color: cs.onSurface),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack ?? () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
