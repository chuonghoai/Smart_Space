import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';
import 'package:mobile_shared/mobile_shared.dart';

/// Bottom sheet for quick staff assignment directly from the map.
/// Reuses existing reportAssignProvider + mapStaffListProvider.
class MapQuickAssignSheet extends ConsumerStatefulWidget {
  final MapReportModel report;
  final VoidCallback onAssigned;

  const MapQuickAssignSheet({
    super.key,
    required this.report,
    required this.onAssigned,
  });

  @override
  ConsumerState<MapQuickAssignSheet> createState() =>
      _MapQuickAssignSheetState();
}

class _MapQuickAssignSheetState extends ConsumerState<MapQuickAssignSheet> {
  StaffModel? _selectedStaff;
  String _selectedSeverity = 'medium';

  static const _severities = ['low', 'medium', 'high', 'critical'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final staffsAsync = ref.watch(mapStaffListProvider);
    final assignState = ref.watch(reportAssignProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.assignment_ind_outlined,
                    color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.mapQuickAssignTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Report title subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.report.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const Divider(height: 20),

          // Staff list
          Flexible(
            child: staffsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$e',
                    style: TextStyle(color: cs.error, fontSize: 12)),
              ),
              data: (staffs) {
                if (staffs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.noStaffAvailable,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: staffs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final staff = staffs[i];
                    final selected = _selectedStaff?.id == staff.id;
                    return ListTile(
                      leading: AppNetworkImage(
                        url: staff.avatarUrl,
                        width: 40,
                        height: 40,
                        isCircle: true,
                        errorWidget: CircleAvatar(
                          radius: 20,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            staff.fullName.isNotEmpty
                                ? staff.fullName[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        staff.fullName,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        staff.email,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : null,
                      onTap: () => setState(() => _selectedStaff = staff),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Severity selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.mapSelectSeverity,
                  style: theme.textTheme.labelMedium),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: _severities.map((s) {
                final selected = _selectedSeverity == s;
                return ChoiceChip(
                  label: Text(s.toUpperCase()),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedSeverity = s),
                  selectedColor: _severityColor(s, cs).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? _severityColor(s, cs) : null,
                  ),
                );
              }).toList(),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedStaff == null || assignState.isLoading
                    ? null
                    : _submit,
                icon: assignState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_outlined, size: 18),
                label: Text(l10n.mapAssignStaff),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final success =
        await ref.read(reportAssignProvider.notifier).assignReport(
              reportId: widget.report.id,
              staffId: _selectedStaff!.id,
              severity: _selectedSeverity,
            );

    if (!mounted) return;
    if (success) {
      Toast.show(ToastType.success, l10n.assignSuccessMessage);
      Navigator.of(context).pop();
      widget.onAssigned();
    } else {
      Toast.show(ToastType.error, l10n.assignFailedMessage);
    }
  }

  Color _severityColor(String severity, ColorScheme cs) {
    return switch (severity) {
      'low' => cs.outline,
      'medium' => cs.primary,
      'high' || 'critical' => cs.error,
      _ => cs.outline,
    };
  }
}
