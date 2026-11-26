import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/shared/image/app_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

String emergencyRelationshipLabel(AppLocalizations l10n, EEmergencyRelationship value) {
  return switch (value) {
    EEmergencyRelationship.parent => l10n.emergencyRelationParent,
    EEmergencyRelationship.spouse => l10n.emergencyRelationSpouse,
    EEmergencyRelationship.child => l10n.emergencyRelationChild,
    EEmergencyRelationship.sibling => l10n.emergencyRelationSibling,
    EEmergencyRelationship.relative => l10n.emergencyRelationRelative,
    EEmergencyRelationship.friend => l10n.emergencyRelationFriend,
    EEmergencyRelationship.neighbor => l10n.emergencyRelationNeighbor,
    EEmergencyRelationship.other => l10n.emergencyRelationOther,
  };
}

/// Mở ứng dụng gọi điện; báo lỗi bằng Toast nếu thiết bị không hỗ trợ.
Future<void> callEmergencyPhone(BuildContext context, String? phone) async {
  final l10n = AppLocalizations.of(context)!;
  if (phone == null || phone.trim().isEmpty) {
    Toast.show(ToastType.error, l10n.noPhoneNumber);
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
  try {
    final launched = await launchUrl(uri);
    if (!launched) {
      Toast.show(ToastType.error, l10n.cannotMakePhoneCall);
    }
  } catch (_) {
    Toast.show(ToastType.error, l10n.cannotMakePhoneCall);
  }
}

/// Hỏi xác nhận cho thao tác huỷ bỏ (xoá liên hệ, rời danh sách).
Future<bool> confirmEmergencyAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class EmergencyAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const EmergencyAvatar({super.key, required this.name, this.avatarUrl});

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(name);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        initials,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (avatarUrl == null || avatarUrl!.isEmpty) return ExcludeSemantics(child: fallback);
    return ExcludeSemantics(
      child: AppNetworkImage(
        url: avatarUrl,
        width: size,
        height: size,
        isCircle: true,
        errorWidget: fallback,
        placeholderWidget: fallback,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final last = parts.last.characters.first;
    return parts.length == 1 ? last.toUpperCase() : '${parts.first.characters.first}$last'.toUpperCase();
  }
}

/// Trạng thái chỉ hiện khi liên hệ chưa nhận được SOS (đã đồng ý là mặc định, không cần nhãn).
class EmergencyStatusLabel extends StatelessWidget {
  final EmergencyContactModel contact;

  const EmergencyStatusLabel({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    final (Color dot, String label) = switch (contact.status) {
      EEmergencyContactStatus.accepted => (Colors.transparent, ''),
      EEmergencyContactStatus.pending => (semantic.warning, l10n.emergencyStatusAwaitingInvite),
      EEmergencyContactStatus.rejected => (theme.colorScheme.error, l10n.emergencyStatusRejected),
      EEmergencyContactStatus.revoked => (theme.colorScheme.outline, l10n.emergencyStatusRevoked),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Biểu tượng kênh nhận cảnh báo; nhãn đầy đủ nằm ở tooltip/semantics thay vì chữ trên dòng.
class EmergencyChannelIcon extends StatelessWidget {
  final EEmergencyContactConsent channel;

  const EmergencyChannelIcon({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isApp = channel == EEmergencyContactConsent.app;
    return Tooltip(
      message: isApp ? l10n.emergencyChannelApp : l10n.emergencyChannelSms,
      child: Icon(
        isApp ? Icons.smartphone_outlined : Icons.sms_outlined,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Sức chứa danh sách: [max] ô, ô đã dùng tô màu chính.
class EmergencyCapacityMeter extends StatelessWidget {
  final int count;
  final int max;

  const EmergencyCapacityMeter({super.key, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = l10n.emergencyCapacity(count, max);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < max; i++) ...[
            Container(
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                color: i < count
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (i < max - 1) const SizedBox(width: 4),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái trống: một tiêu đề và một câu giải thích, không minh hoạ.
class EmergencyEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;

  const EmergencyEmptyState({super.key, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Khối nền một bậc tông so với nền màn hình, thay cho viền/bóng.
class EmergencyTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const EmergencyTile({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: child,
        ),
      ),
    );
  }
}
