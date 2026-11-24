import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/features/reports/models/auto_assign_models.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';
import 'package:smartspace_admin/ui/shared/position/position_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/widgets/staff_workload_badge.dart';
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
  String? _positionFilter;
  String _selectedSeverity = 'medium';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _severities = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    final initialSeverity = widget.report.severity?.toLowerCase();
    if (initialSeverity != null && _severities.contains(initialSeverity)) {
      _selectedSeverity = initialSeverity;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final staffsAsync = ref.watch(mapStaffListProvider);
    final assignState = ref.watch(reportAssignProvider);
    final recsAsync = ref.watch(reportRecommendationsProvider(widget.report.id));

    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final topPadding = mq.padding.top;

    final maxHeight = isKeyboardOpen
        ? (mq.size.height - bottomInset - topPadding - 16)
        : (mq.size.height * 0.75);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          bottom: !isKeyboardOpen,
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
                FilledButton.tonalIcon(
                  onPressed: assignState.isLoading ||
                          recsAsync.isLoading ||
                          (recsAsync.valueOrNull?.candidates.isEmpty ?? false)
                      ? null
                      : _submitAutoAssign,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: Text(l10n.autoAssignTriggerButton),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top-3 Smart Recommendations strip
          _buildRecommendationsStrip(
            context: context,
            theme: theme,
            cs: cs,
            semantic: semantic,
            l10n: l10n,
            recsAsync: recsAsync,
            isSubmitting: assignState.isLoading,
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

          PositionFilterChips(
            selectedId: _positionFilter,
            onChanged: (id) => setState(() => _positionFilter = id),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.searchStaffHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          Divider(height: isKeyboardOpen ? 10 : 20),

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
              data: (allStaffs) {
                var staffs = _positionFilter == null
                    ? allStaffs
                    : allStaffs
                        .where((s) => s.positionId == _positionFilter)
                        .toList();
                if (_searchQuery.trim().isNotEmpty) {
                  staffs = staffs
                      .where((s) => _ViSearchHelper.matches(s, _searchQuery))
                      .toList();
                }
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
                  separatorBuilder: (_, _) => const Divider(height: 1),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.email,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              PositionChip(
                                name: staff.positionName ?? l10n.noPosition,
                              ),
                              StaffWorkloadBadge(
                                weightedLoad: staff.weightedLoad,
                                processingCount: staff.processingCount,
                                isOverloaded: staff.isOverloaded,
                                assignmentHint: staff.assignmentHint,
                                severityBreakdown: staff.severityBreakdown,
                                showAssignmentHint: true,
                                compact: true,
                              ),
                            ],
                          ),
                        ],
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
            padding: EdgeInsets.fromLTRB(16, isKeyboardOpen ? 6 : 12, 16, 4),
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
                  label: Text(_getSeverityLabel(s, l10n)),
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
            padding: EdgeInsets.fromLTRB(
              16,
              isKeyboardOpen ? 8 : 16,
              16,
              isKeyboardOpen ? 8 : 16,
            ),
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
        ),
      ),
    );
  }

  Widget _buildRecommendationsStrip({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme cs,
    required AppSemanticColors semantic,
    required AppLocalizations l10n,
    required AsyncValue<AutoAssignRecommendationModel> recsAsync,
    required bool isSubmitting,
  }) {
    return recsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (recs) {
        if (recs.candidates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: semantic.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: semantic.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: semantic.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recs.fallbackMessage ??
                          l10n.autoAssignNoCandidatesDefault,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.autoAssignTopCandidates(recs.candidates.length),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.autoAssignEligibleCount(
                        recs.totalEligibleCandidates,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantic.info,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recs.candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final candidate = recs.candidates[index];
                    final isSelected = _selectedStaff?.id == candidate.staffId;
                    final scoreColor = candidate.finalScore >= 75
                        ? semantic.success
                        : candidate.finalScore >= 50
                            ? cs.primary
                            : semantic.warning;

                    return Material(
                      color: isSelected
                          ? cs.primaryContainer.withValues(alpha: 0.35)
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          setState(
                              () => _selectedStaff = candidate.toStaffModel());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 224,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary
                                  : cs.outlineVariant.withValues(alpha: 0.6),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: candidate.rank == 1
                                          ? cs.primary
                                          : cs.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${candidate.rank}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: candidate.rank == 1
                                            ? cs.onPrimary
                                            : cs.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      candidate.fullName,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scoreColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.autoAssignScoreValue(
                                        candidate.finalScore.toStringAsFixed(0),
                                      ),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.near_me_outlined,
                                      size: 13, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${l10n.autoAssignDistanceKm(candidate.distanceKm.toStringAsFixed(1))} · ${l10n.autoAssignTasksCount(candidate.monthlyWorkload)}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 28,
                                  child: FilledButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () => _submitRecommendClick(candidate),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      textStyle: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: Text(l10n.autoAssignAssignNow),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final success =
        await ref.read(reportAssignProvider.notifier).assignReport(
              reportId: widget.report.id,
              staffId: _selectedStaff!.id,
              severity: _selectedSeverity,
              source: 'MANUAL',
            );

    if (!mounted) return;
    if (success) {
      ref.invalidate(mapStaffListProvider);
      Toast.show(ToastType.success, l10n.assignSuccessMessage);
      Navigator.of(context).pop();
      widget.onAssigned();
    } else {
      Toast.show(ToastType.error, l10n.assignFailedMessage);
    }
  }

  Future<void> _submitRecommendClick(StaffCandidateScoreModel candidate) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _selectedStaff = candidate.toStaffModel());

    final success =
        await ref.read(reportAssignProvider.notifier).assignReport(
              reportId: widget.report.id,
              staffId: candidate.staffId,
              severity: _selectedSeverity,
              source: 'RECOMMEND_CLICK',
            );

    if (!mounted) return;
    if (success) {
      ref.invalidate(mapStaffListProvider);
      Toast.show(ToastType.success, l10n.assignSuccessMessage);
      Navigator.of(context).pop();
      widget.onAssigned();
    } else {
      final err = ref.read(reportAssignProvider).error;
      Toast.show(
        ToastType.error,
        (err != null && err.isNotEmpty) ? err : l10n.assignFailedMessage,
      );
    }
  }

  Future<void> _submitAutoAssign() async {
    final l10n = AppLocalizations.of(context)!;
    final success =
        await ref.read(reportAssignProvider.notifier).autoAssignReport(
              reportId: widget.report.id,
            );

    if (!mounted) return;
    if (success) {
      ref.invalidate(mapStaffListProvider);
      Toast.show(ToastType.success, l10n.autoAssignSuccessMessage);
      Navigator.of(context).pop();
      widget.onAssigned();
    } else {
      final err = ref.read(reportAssignProvider).error;
      Toast.show(
        ToastType.error,
        (err != null && err.isNotEmpty) ? err : l10n.autoAssignFailedFallback,
      );
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

  String _getSeverityLabel(String s, AppLocalizations l10n) =>
      switch (s.toLowerCase()) {
        'low' => l10n.severityLow,
        'medium' => l10n.severityMedium,
        'high' => l10n.severityHigh,
        'critical' => l10n.severityCritical,
        _ => s,
      };
}

class _ViSearchHelper {
  static const _d =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸ';
  static const _nd =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydDAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYY';

  static String strip(String s) {
    var r = s;
    for (int i = 0; i < _d.length; i++) {
      r = r.replaceAll(_d[i], _nd[i]);
    }
    return r;
  }

  static bool matches(StaffModel staff, String q) {
    if (q.trim().isEmpty) return true;
    final qLow = q.trim().toLowerCase();
    final qStrip = strip(qLow);
    final name = staff.fullName.toLowerCase();
    final nameStrip = strip(name);
    final email = staff.email.toLowerCase();
    final phone = (staff.phoneNumber ?? '').toLowerCase();
    return name.contains(qLow) ||
        nameStrip.contains(qStrip) ||
        email.contains(qLow) ||
        phone.contains(qLow);
  }
}
