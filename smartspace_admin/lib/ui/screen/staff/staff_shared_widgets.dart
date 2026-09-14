import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_list_response.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Summary card — hiển thị 1 KPI (icon + value + label)
class StaffSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StaffSummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Card nhân viên — hiển thị avatar, tên, email, trạng thái
class StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onTap;

  const StaffCard({super.key, required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: staff.isBlocked ? 0.6 : 1.0,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                StaffAvatar(staff: staff, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.fullName,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(staff.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis),
                      if (staff.phoneNumber != null &&
                          staff.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(staff.phoneNumber!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            )),
                      ],
                      if (staff.processingCount > 0) ...[
                        const SizedBox(height: 4),
                        Text('${staff.processingCount} ${AppLocalizations.of(context)!.processingStatus.toLowerCase()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StaffStatusChip(isActive: staff.isActive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar nhân viên — hiển thị ảnh hoặc chữ cái đầu
class StaffAvatar extends StatelessWidget {
  final StaffModel staff;
  final double radius;
  const StaffAvatar({super.key, required this.staff, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      backgroundImage:
          staff.avatarUrl != null ? NetworkImage(staff.avatarUrl!) : null,
      child: staff.avatarUrl == null
          ? Text(
              staff.fullName.isNotEmpty
                  ? staff.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
    );
  }
}

/// Chip trạng thái — "Hoạt động" (xanh) hoặc "Đã khoá" (đỏ)
class StaffStatusChip extends StatelessWidget {
  final bool isActive;
  const StaffStatusChip({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final successColor = theme.brightness == Brightness.light ? const Color(0xFF2E7D32) : const Color(0xFF66BB6A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? successColor.withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? l10n.activeStatus : l10n.blockedStatus,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? successColor : theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Nút phân trang — Previous / 1 2 3 / Next
class StaffPaginationControls extends ConsumerWidget {
  final StaffListResponse data;
  const StaffPaginationControls({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (data.totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: data.currentPage > 1
              ? () => ref.read(staffListProvider.notifier).previousPage()
              : null,
        ),
        const SizedBox(width: 8),
        ...List.generate(data.totalPages, (i) {
          final page = i + 1;
          final isCurrent = page == data.currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color:
                  isCurrent ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: isCurrent
                    ? null
                    : () =>
                        ref.read(staffListProvider.notifier).goToPage(page),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Text(
                    '$page',
                    style: TextStyle(
                      color: isCurrent
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: data.currentPage < data.totalPages
              ? () => ref.read(staffListProvider.notifier).nextPage()
              : null,
        ),
      ],
    );
  }
}

/// Row chi tiết — icon + text (dùng trong detail panel)
class StaffDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const StaffDetailRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Dialog thêm nhân viên mới
void showAddStaffDialog(
    BuildContext context, AppLocalizations l10n, ThemeData theme) {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(l10n.addNewStaff),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.fullname} *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.fullnameRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.email} *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.emailRequired;
                  if (!v.contains('@')) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.password} *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.passwordRequired;
                  if (v.length < 6) return l10n.passwordReqLength;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              // TODO: Call create staff API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.addStaffSuccess)),
              );
            }
          },
          child: Text(l10n.create),
        ),
      ],
    ),
  );
}

/// Bottom Sheet chi tiết nhân viên
void showStaffDetailSheet(
    BuildContext context, AppLocalizations l10n, ThemeData theme,
    StaffModel staff) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            StaffAvatar(staff: staff, radius: 36),
            const SizedBox(height: 12),
            Text(staff.fullName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StaffStatusChip(isActive: staff.isActive),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            StaffDetailRow(icon: Icons.email_outlined, text: staff.email),
            const SizedBox(height: 12),
            StaffDetailRow(
                icon: Icons.phone_outlined,
                text: staff.phoneNumber ?? '—'),
            if (staff.processingCount > 0) ...[
              const SizedBox(height: 12),
              StaffDetailRow(
                  icon: Icons.assignment_outlined,
                  text: '${staff.processingCount} phản ánh đang xử lý'),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                    staff.isActive ? Icons.lock_outline : Icons.lock_open),
                label: Text(
                    staff.isActive ? 'Khoá tài khoản' : 'Mở khoá'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: staff.isActive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  side: BorderSide(
                    color: staff.isActive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
