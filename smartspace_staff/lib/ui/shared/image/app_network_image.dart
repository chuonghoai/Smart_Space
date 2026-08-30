import 'package:flutter/material.dart';

/// Component render image by url
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isCircle;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? placeholderWidget;
  final Map<String, String>? headers;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isCircle = false,
    this.borderRadius,
    this.errorWidget,
    this.placeholderWidget,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveHeaders = {'User-Agent': 'Mozilla/5.0', ...?headers};

    Widget buildImage() {
      if (url == null || url!.isEmpty) {
        return errorWidget ?? _buildDefaultPlaceholder(theme);
      }

      String finalUrl = url!;
      if (finalUrl.contains('ui-avatars.com') &&
          !finalUrl.contains('format=')) {
        finalUrl += '${finalUrl.contains('?') ? '&' : '?'}format=png';
      }

      return Image.network(
        finalUrl,
        width: width,
        height: height,
        fit: fit,
        headers: effectiveHeaders,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholderWidget ??
              Container(
                width: width,
                height: height,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultPlaceholder(theme);
        },
      );
    }

    if (isCircle) {
      return ClipOval(child: buildImage());
    } else if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: buildImage());
    }

    return buildImage();
  }

  Widget _buildDefaultPlaceholder(ThemeData theme) {
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
