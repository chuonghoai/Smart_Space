import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/category/application/category_providers.dart';
import 'package:smartspace_admin/features/category/models/category_model.dart';
import 'package:smartspace_admin/features/reports/data/report_repository.dart';
import 'package:smartspace_admin/features/reports/models/auto_assign_models.dart';
import 'package:smartspace_admin/features/reports/providers/auto_assign_center_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/staff/widgets/staff_location_picker_dialog.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AutoAssignCenterScreen extends ConsumerStatefulWidget {
  const AutoAssignCenterScreen({super.key});

  @override
  ConsumerState<AutoAssignCenterScreen> createState() =>
      _AutoAssignCenterScreenState();
}

class _AutoAssignCenterScreenState
    extends ConsumerState<AutoAssignCenterScreen> {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // Editable config state (synced from backend config)
  bool _configInitialized = false;
  bool _isSavingConfig = false;
  String _mode = 'ASSIST';
  int _wDistance = 35;
  int _wMonthly = 30;
  int _wActive = 20;
  int _wOnTime = 15;
  double _maxRadiusKm = 15.0;
  int _maxConcurrentTasks = 10;
  int _targetMonthlyTasks = 20;

  // Progressive disclosure state to keep UI compact and scannable
  bool _weightsExpanded = false;
  bool _simulatorExpanded = kIsWeb;
  bool _showAllStaffFairness = false;
  int _bottomTabIndex = 0; // 0 = Workload Fairness, 1 = Decision Logs

  // Dry-run simulator state
  String? _simCategoryId;
  final TextEditingController _simLatController =
      TextEditingController(text: '10.77689');
  final TextEditingController _simLngController =
      TextEditingController(text: '106.70098');
  Timer? _simDebounce;
  bool _isSimulating = false;
  AutoAssignRecommendationModel? _simResult;
  String? _simError;

  @override
  void dispose() {
    _simDebounce?.cancel();
    _simLatController.dispose();
    _simLngController.dispose();
    super.dispose();
  }

  void _syncFromConfigIfNeeded(AutoAssignConfigModel cfg) {
    if (_configInitialized) return;
    _configInitialized = true;
    _mode = cfg.mode;
    _wDistance = cfg.distancePercent;
    _wMonthly = cfg.monthlyWorkloadPercent;
    _wActive = cfg.activeLoadPercent;
    _wOnTime = cfg.onTimeRatePercent;
    final sum = _wDistance + _wMonthly + _wActive + _wOnTime;
    if (sum != 100) {
      _wOnTime = (100 - (_wDistance + _wMonthly + _wActive)).clamp(0, 100);
    }
    _maxRadiusKm = cfg.maxRadiusKm.clamp(1.0, 50.0);
    _maxConcurrentTasks = cfg.maxConcurrentTasks.clamp(1, 50);
    _targetMonthlyTasks = cfg.targetMonthlyTasks.clamp(1, 200);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleSimulation(immediate: true);
    });
  }

  /// Auto-balances the remaining 3 weights so all 4 integer weights always sum to 100%.
  void _updateLockedWeight(int changedIndex, int rawValue) {
    final target = rawValue.clamp(0, 100);
    final weights = [_wDistance, _wMonthly, _wActive, _wOnTime];
    if (weights[changedIndex] == target) return;

    weights[changedIndex] = target;
    final remaining = 100 - target;
    final otherIndices = <int>[0, 1, 2, 3]..remove(changedIndex);
    final otherSum = otherIndices.fold<int>(0, (sum, i) => sum + weights[i]);

    if (otherSum <= 0) {
      final base = remaining ~/ 3;
      final rem = remaining % 3;
      for (int k = 0; k < otherIndices.length; k++) {
        weights[otherIndices[k]] = base + (k < rem ? 1 : 0);
      }
    } else {
      final scaled = <int, int>{};
      final remainders = <({int idx, double frac})>[];
      int allocated = 0;
      for (final idx in otherIndices) {
        final exact = (weights[idx] * remaining) / otherSum;
        final fl = exact.floor();
        scaled[idx] = fl;
        allocated += fl;
        remainders.add((idx: idx, frac: exact - fl));
      }
      remainders.sort((a, b) => b.frac.compareTo(a.frac));
      int diff = remaining - allocated;
      for (int k = 0; k < remainders.length && diff > 0; k++, diff--) {
        final idx = remainders[k].idx;
        scaled[idx] = (scaled[idx] ?? 0) + 1;
      }
      for (final idx in otherIndices) {
        weights[idx] = scaled[idx] ?? 0;
      }
    }

    setState(() {
      _wDistance = weights[0];
      _wMonthly = weights[1];
      _wActive = weights[2];
      _wOnTime = weights[3];
    });
    _scheduleSimulation();
  }

  void _resetDefaultWeights() {
    setState(() {
      _wDistance = 35;
      _wMonthly = 30;
      _wActive = 20;
      _wOnTime = 15;
    });
    _scheduleSimulation(immediate: true);
  }

  void _scheduleSimulation({bool immediate = false}) {
    _simDebounce?.cancel();
    if (immediate) {
      _runSimulation();
    } else {
      _simDebounce = Timer(const Duration(milliseconds: 260), _runSimulation);
    }
  }

  Future<void> _runSimulation() async {
    if (!mounted) return;
    final lat = double.tryParse(_simLatController.text.trim());
    final lng = double.tryParse(_simLngController.text.trim());
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return;
    }

    setState(() {
      _isSimulating = true;
      _simError = null;
    });

    try {
      final res = await reportRepository.simulateAutoAssign(
        AutoAssignSimulateRequestModel(
          categoryId: _simCategoryId,
          latitude: lat,
          longitude: lng,
          distanceWeight: _wDistance.toDouble(),
          monthlyWorkloadWeight: _wMonthly.toDouble(),
          activeLoadWeight: _wActive.toDouble(),
          onTimeRateWeight: _wOnTime.toDouble(),
          maxRadiusKm: _maxRadiusKm,
          maxConcurrentTasks: _maxConcurrentTasks,
          targetMonthlyTasks: _targetMonthlyTasks,
          limit: 10,
        ),
      );
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _simResult = res.data;
          _isSimulating = false;
        });
      } else {
        setState(() {
          _simError = res.message;
          _isSimulating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _simError = e.toString();
        _isSimulating = false;
      });
    }
  }

  Future<void> _saveConfig(AppLocalizations l10n) async {
    if (_isSavingConfig) return;
    setState(() => _isSavingConfig = true);
    try {
      final updatedModel = AutoAssignConfigModel(
        mode: _mode,
        distanceWeight: _wDistance / 100.0,
        monthlyWorkloadWeight: _wMonthly / 100.0,
        activeLoadWeight: _wActive / 100.0,
        onTimeRateWeight: _wOnTime / 100.0,
        maxRadiusKm: _maxRadiusKm,
        maxConcurrentTasks: _maxConcurrentTasks,
        targetMonthlyTasks: _targetMonthlyTasks,
      );
      final res = await reportRepository.updateAutoAssignConfig(updatedModel);
      if (!mounted) return;
      if (res.success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.autoAssignConfigSavedSuccess)),
          );
        ref.invalidate(autoAssignConfigProvider);
        ref.invalidate(autoAssignAnalyticsProvider);
        _scheduleSimulation(immediate: true);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                res.message.isNotEmpty
                    ? res.message
                    : l10n.autoAssignConfigSaveFailed,
              ),
            ),
          );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.autoAssignConfigSaveFailed)),
        );
    } finally {
      if (mounted) {
        setState(() => _isSavingConfig = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    setState(() => _configInitialized = false);
    ref.invalidate(autoAssignConfigProvider);
    ref.invalidate(autoAssignAnalyticsProvider);
    ref.invalidate(autoAssignLogsProvider);
    await _runSimulation();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);

    final configAsync = ref.watch(autoAssignConfigProvider);
    final analyticsAsync = ref.watch(autoAssignAnalyticsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final logsAsync = ref.watch(autoAssignLogsProvider);

    configAsync.whenData(_syncFromConfigIfNeeded);

    final categories = categoriesAsync.valueOrNull
            ?.where((c) => c.active)
            .toList() ??
        const <CategoryModel>[];
    if (_simCategoryId == null && categories.isNotEmpty) {
      _simCategoryId = categories.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _simResult == null && !_isSimulating) {
          _scheduleSimulation(immediate: true);
        }
      });
    }

    return AppLayout(
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: EdgeInsets.all(kIsWeb ? 24 : 14),
          children: [
            _buildPageHeader(theme, cs, l10n),
            const SizedBox(height: 16),
            _buildDividedKpiStrip(theme, cs, semantic, l10n, analyticsAsync),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1020;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: _buildConfigCard(theme, cs, semantic, l10n),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 12,
                        child: _buildSimulatorCard(
                          theme,
                          cs,
                          semantic,
                          l10n,
                          categories,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildConfigCard(theme, cs, semantic, l10n),
                    const SizedBox(height: 14),
                    _buildSimulatorCard(
                      theme,
                      cs,
                      semantic,
                      l10n,
                      categories,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildBottomAnalyticsSection(
              theme,
              cs,
              semantic,
              l10n,
              analyticsAsync,
              logsAsync,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.autoAssignCenterTitle,
                style: (kIsWeb
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.autoAssignCenterSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: _refreshAll,
          tooltip: l10n.autoAssignRefreshAction,
          icon: const Icon(Icons.refresh, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  /// Divided KPI strip: 4-col on desktop (>=860px), compact 2x2 grid on mobile/tablet (<860px).
  Widget _buildDividedKpiStrip(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    AsyncValue<AutoAssignAnalyticsModel> analyticsAsync,
  ) {
    final data = analyticsAsync.valueOrNull ?? const AutoAssignAnalyticsModel();
    final borderColor = cs.outlineVariant.withValues(alpha: 0.65);

    final cells = <({String label, String value, String sub, Color? accent})>[
      (
        label: l10n.autoAssignKpiTotalDecisions,
        value: '${data.totalDecisions}',
        sub: l10n.autoAssignKpiBreakdown(
          data.autoAssignedCount,
          data.recommendAssignedCount,
          data.fallbackCount,
        ),
        accent: null,
      ),
      (
        label: l10n.autoAssignKpiSuccessRate,
        value: '${data.autoAssignSuccessRate.toStringAsFixed(1)}%',
        sub: l10n.autoAssignKpiSuccessSub,
        accent: data.autoAssignSuccessRate >= 75
            ? semantic.success
            : semantic.warning,
      ),
      (
        label: l10n.autoAssignKpiAcceptanceRate,
        value: '${data.adminAcceptanceRate.toStringAsFixed(1)}%',
        sub: l10n.autoAssignKpiOverriddenSub(data.overriddenCount),
        accent: data.adminAcceptanceRate >= 80
            ? semantic.success
            : semantic.warning,
      ),
      (
        label: l10n.autoAssignKpiFairnessIndex,
        value: '${data.monthlyFairnessIndex.toStringAsFixed(1)}%',
        sub: l10n.autoAssignKpiFairnessSub(
          data.averageMonthlyWorkload.toStringAsFixed(1),
          data.workloadStandardDeviation.toStringAsFixed(1),
        ),
        accent: cs.primary,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 860) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < cells.length; i++) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: borderColor,
                      ),
                    Expanded(
                      child: _buildKpiCell(
                        theme,
                        cs,
                        cells[i],
                        compact: false,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          // Compact 2x2 grid on mobile/tablet so it takes half the height
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildKpiCell(theme, cs, cells[0], compact: true),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: borderColor),
                    Expanded(
                      child: _buildKpiCell(theme, cs, cells[1], compact: true),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildKpiCell(theme, cs, cells[2], compact: true),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: borderColor),
                    Expanded(
                      child: _buildKpiCell(theme, cs, cells[3], compact: true),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCell(
    ThemeData theme,
    ColorScheme cs,
    ({String label, String value, String sub, Color? accent}) item, {
    required bool compact,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 12 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: (compact
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: item.accent ?? cs.onSurface,
              fontFeatures: _tabular,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.sub,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 11 : 12,
              color: cs.onSurfaceVariant,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }

  /// Mode & Weights Card:
  /// - Fixed equal-height 3-column mode selector with single-line text (never wraps unevenly on mobile).
  /// - Visual proportion bar + compact summary chips always visible.
  /// - Collapsible dropdown drawer for the 7 sliders (Weights & Thresholds) to avoid visual clutter.
  Widget _buildConfigCard(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
  ) {
    final modeDesc = switch (_mode) {
      'AUTO' => l10n.autoAssignModeDescAuto,
      'MANUAL' => l10n.autoAssignModeDescManual,
      _ => l10n.autoAssignModeDescAssist,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.autoAssignConfigCardTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Custom 3-column single-line Mode Selector (no vertical text wrapping on mobile)
          _buildResponsiveModeSelector(theme, cs, l10n),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              modeDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Visual 4-weight proportion bar + compact summary pills
          _buildWeightsSummaryBar(theme, cs, semantic, l10n),
          const SizedBox(height: 10),

          // Dropdown / Expand-Collapse toggle button for Weight & Threshold Sliders
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _weightsExpanded = !_weightsExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _weightsExpanded
                    ? cs.primaryContainer.withValues(alpha: 0.25)
                    : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _weightsExpanded
                      ? cs.primary.withValues(alpha: 0.5)
                      : cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 17,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weightsExpanded
                          ? l10n.autoAssignToggleWeightsCollapse
                          : l10n.autoAssignToggleWeightsExpand,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _weightsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Sliders Drawer
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _weightsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.autoAssignWeightsHeader,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _resetDefaultWeights,
                        icon: const Icon(Icons.restart_alt, size: 15),
                        label: Text(l10n.autoAssignResetWeightsButton),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildWeightSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignDistanceLabel,
                    percent: _wDistance,
                    onChanged: (v) => _updateLockedWeight(0, v),
                  ),
                  _buildWeightSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignMonthlyLoadLabel,
                    percent: _wMonthly,
                    onChanged: (v) => _updateLockedWeight(1, v),
                  ),
                  _buildWeightSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignActiveLoadLabel,
                    percent: _wActive,
                    onChanged: (v) => _updateLockedWeight(2, v),
                  ),
                  _buildWeightSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignOnTimeLabel,
                    percent: _wOnTime,
                    onChanged: (v) => _updateLockedWeight(3, v),
                  ),
                  const Divider(height: 20),
                  Text(
                    l10n.autoAssignThresholdsHeader,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildThresholdSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignMaxRadiusLabel,
                    valueText: '${_maxRadiusKm.toStringAsFixed(1)} km',
                    value: _maxRadiusKm,
                    min: 1.0,
                    max: 30.0,
                    divisions: 58,
                    onChanged: (v) {
                      setState(() => _maxRadiusKm = (v * 2).round() / 2.0);
                      _scheduleSimulation();
                    },
                  ),
                  _buildThresholdSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignMaxConcurrentLabel,
                    valueText: l10n.autoAssignTasksCount(_maxConcurrentTasks),
                    value: _maxConcurrentTasks.toDouble(),
                    min: 1,
                    max: 25,
                    divisions: 24,
                    onChanged: (v) {
                      setState(() => _maxConcurrentTasks = v.round());
                      _scheduleSimulation();
                    },
                  ),
                  _buildThresholdSliderRow(
                    theme: theme,
                    cs: cs,
                    label: l10n.autoAssignTargetMonthlyLabel,
                    valueText: l10n.autoAssignTasksCount(_targetMonthlyTasks),
                    value: _targetMonthlyTasks.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 55,
                    onChanged: (v) {
                      setState(() => _targetMonthlyTasks = v.round());
                      _scheduleSimulation();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSavingConfig ? null : () => _saveConfig(l10n),
              icon: _isSavingConfig
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(l10n.autoAssignSaveConfigButton),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Equal-width 3-segment mode selector that never wraps text vertically on narrow mobile viewports.
  Widget _buildResponsiveModeSelector(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final options = <({String code, String label, IconData icon})>[
      (
        code: 'AUTO',
        label: l10n.autoAssignModeShortAuto,
        icon: Icons.bolt_outlined,
      ),
      (
        code: 'ASSIST',
        label: l10n.autoAssignModeShortAssist,
        icon: Icons.auto_awesome_outlined,
      ),
      (
        code: 'MANUAL',
        label: l10n.autoAssignModeShortManual,
        icon: Icons.pan_tool_alt_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _buildModeSegmentTile(theme, cs, options[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeSegmentTile(
    ThemeData theme,
    ColorScheme cs,
    ({String code, String label, IconData icon}) item,
  ) {
    final selected = _mode == item.code;
    return Material(
      color: selected ? cs.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => setState(() => _mode = item.code),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.code,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact 4-color proportion bar + single-line metric pills so Admin sees current weights at a glance even when collapsed.
  Widget _buildWeightsSummaryBar(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
  ) {
    final cDist = cs.primary;
    final cMonth = semantic.info;
    final cActive = semantic.warning;
    final cOnTime = semantic.success;

    final items = <({String label, String val, Color color})>[
      (
        label: l10n.autoAssignDistanceLabel,
        val: '$_wDistance%',
        color: cDist,
      ),
      (
        label: l10n.autoAssignMonthlyLoadLabel,
        val: '$_wMonthly%',
        color: cMonth,
      ),
      (
        label: l10n.autoAssignActiveLoadLabel,
        val: '$_wActive%',
        color: cActive,
      ),
      (
        label: l10n.autoAssignOnTimeLabel,
        val: '$_wOnTime%',
        color: cOnTime,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                if (_wDistance > 0)
                  Expanded(
                    flex: _wDistance,
                    child: ColoredBox(color: cDist),
                  ),
                if (_wMonthly > 0)
                  Expanded(
                    flex: _wMonthly,
                    child: ColoredBox(color: cMonth),
                  ),
                if (_wActive > 0)
                  Expanded(
                    flex: _wActive,
                    child: ColoredBox(color: cActive),
                  ),
                if (_wOnTime > 0)
                  Expanded(
                    flex: _wOnTime,
                    child: ColoredBox(color: cOnTime),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final item in items)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${item.label}: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.val,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
              ),
            _buildMetricPill(
              theme,
              cs,
              '≤ ${_maxRadiusKm.toStringAsFixed(1)} km · Max $_maxConcurrentTasks',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightSliderRow({
    required ThemeData theme,
    required ColorScheme cs,
    required String label,
    required int percent,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  fontFeatures: _tabular,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: percent.toDouble().clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSliderRow({
    required ThemeData theme,
    required ColorScheme cs,
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueText,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  fontFeatures: _tabular,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Dry-Run Simulator Card with collapsible header so mobile users can expand/collapse on demand.
  Widget _buildSimulatorCard(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    List<CategoryModel> categories,
  ) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final candidates = _simResult?.candidates ?? const [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                setState(() => _simulatorExpanded = !_simulatorExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.autoAssignSimulatorTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.autoAssignEligibleCount(
                          _simResult?.totalEligibleCandidates ?? 0,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSimulating)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Icon(
                  _simulatorExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _simulatorExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_simCategoryId),
                    initialValue:
                        categories.any((c) => c.id == _simCategoryId)
                            ? _simCategoryId
                            : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.autoAssignSimCategoryLabel,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              isVi ? c.nameVi : c.nameEn,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _simCategoryId = val);
                      _scheduleSimulation(immediate: true);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _simLatController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: _tabular,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.staffBaseLatitudeLabel,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (_) => _scheduleSimulation(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _simLngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: _tabular,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.staffBaseLongitudeLabel,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (_) => _scheduleSimulation(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final initLat = double.tryParse(
                                _simLatController.text.trim(),
                              ) ??
                              10.77689;
                          final initLng = double.tryParse(
                                _simLngController.text.trim(),
                              ) ??
                              106.70098;
                          final picked =
                              await showStaffLocationPickerDialog(
                            context,
                            initialLat: initLat,
                            initialLng: initLng,
                          );
                          if (picked != null && mounted) {
                            _simLatController.text =
                                picked.lat.toStringAsFixed(5);
                            _simLngController.text =
                                picked.lng.toStringAsFixed(5);
                            _scheduleSimulation(immediate: true);
                          }
                        },
                        icon: const Icon(Icons.pin_drop_outlined, size: 15),
                        label: Text(l10n.autoAssignSimPickOnMap),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      ActionChip(
                        label: Text(l10n.autoAssignSimPresetDistrict1),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _simLatController.text = '10.77689';
                          _simLngController.text = '106.70098';
                          _scheduleSimulation(immediate: true);
                        },
                      ),
                      ActionChip(
                        label: Text(l10n.autoAssignSimPresetBinhThanh),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _simLatController.text = '10.80147';
                          _simLngController.text = '106.71135';
                          _scheduleSimulation(immediate: true);
                        },
                      ),
                      ActionChip(
                        label: Text(l10n.autoAssignSimPresetThuDuc),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _simLatController.text = '10.84941';
                          _simLngController.text = '106.77171';
                          _scheduleSimulation(immediate: true);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (_simError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _simError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onErrorContainer,
                        ),
                      ),
                    )
                  else if (candidates.isEmpty && !_isSimulating)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        _simResult?.fallbackMessage ??
                            l10n.autoAssignNoCandidatesDefault,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (int i = 0; i < candidates.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _buildSimulatedCandidateTile(
                            theme,
                            cs,
                            semantic,
                            l10n,
                            candidates[i],
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedCandidateTile(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    StaffCandidateScoreModel c,
  ) {
    final isTop = c.rank == 1;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isTop
            ? cs.primaryContainer.withValues(alpha: 0.22)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop
              ? cs.primary.withValues(alpha: 0.65)
              : cs.outlineVariant.withValues(alpha: 0.55),
          width: isTop ? 1.3 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTop ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${c.rank}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isTop ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              AppNetworkImage(
                url: c.avatarUrl,
                width: 30,
                height: 30,
                isCircle: true,
                errorWidget: CircleAvatar(
                  radius: 15,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_outline,
                    size: 15,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.fullName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (c.positionName != null && c.positionName!.isNotEmpty)
                      Text(
                        c.positionName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isTop ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.autoAssignScoreValue(c.finalScore.toStringAsFixed(1)),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isTop ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 5,
            children: [
              _buildMetricPill(
                theme,
                cs,
                '${l10n.autoAssignDistanceLabel}: ${l10n.autoAssignDistanceKm(c.distanceKm.toStringAsFixed(2))} (${l10n.autoAssignScoreValue(c.distanceScore.toStringAsFixed(0))})',
              ),
              _buildMetricPill(
                theme,
                cs,
                '${l10n.autoAssignMonthlyLoadLabel}: ${l10n.autoAssignTasksCount(c.monthlyWorkload)} (${l10n.autoAssignScoreValue(c.monthlyWorkloadScore.toStringAsFixed(0))})',
              ),
              _buildMetricPill(
                theme,
                cs,
                '${l10n.autoAssignActiveLoadLabel}: ${l10n.autoAssignTasksCount(c.activeProcessingCount)} (${l10n.autoAssignScoreValue(c.activeLoadScore.toStringAsFixed(0))})',
              ),
              _buildMetricPill(
                theme,
                cs,
                '${l10n.autoAssignOnTimeLabel}: ${c.onTimeRate30d.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(ThemeData theme, ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: cs.onSurfaceVariant,
          fontFeatures: _tabular,
        ),
      ),
    );
  }

  /// Unified Bottom Section with 2 switchable tabs (Workload Fairness | Decision Logs)
  /// so Admin isn't overwhelmed by two long vertical tables stacked on top of each other.
  Widget _buildBottomAnalyticsSection(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    AsyncValue<AutoAssignAnalyticsModel> analyticsAsync,
    AsyncValue<AssignmentDecisionLogPageModel> logsAsync,
  ) {
    final staffCount =
        analyticsAsync.valueOrNull?.staffWorkloads.length ?? 0;
    final logCount = logsAsync.valueOrNull?.totalElements ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2-Tab Pill Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBottomTabButton(
                    theme: theme,
                    cs: cs,
                    index: 0,
                    icon: Icons.bar_chart_rounded,
                    label: '${l10n.autoAssignTabFairness} ($staffCount)',
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildBottomTabButton(
                    theme: theme,
                    cs: cs,
                    index: 1,
                    icon: Icons.history_rounded,
                    label: '${l10n.autoAssignTabLogs} ($logCount)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_bottomTabIndex == 0)
            _buildWorkloadFairnessContent(
              theme,
              cs,
              semantic,
              l10n,
              analyticsAsync,
            )
          else
            _buildDecisionLogsContent(
              theme,
              cs,
              semantic,
              l10n,
              logsAsync,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomTabButton({
    required ThemeData theme,
    required ColorScheme cs,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _bottomTabIndex == index;
    return Material(
      color: selected ? cs.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => setState(() => _bottomTabIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkloadFairnessContent(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    AsyncValue<AutoAssignAnalyticsModel> analyticsAsync,
  ) {
    final analytics =
        analyticsAsync.valueOrNull ?? const AutoAssignAnalyticsModel();
    final staffs = analytics.staffWorkloads;
    final maxMonthly = staffs.fold<int>(
      _targetMonthlyTasks,
      (m, s) => s.monthlyWorkload > m ? s.monthlyWorkload : m,
    );
    const int initialLimit = 5;
    final hasMore = staffs.length > initialLimit;
    final visibleStaffs = (_showAllStaffFairness || !hasMore)
        ? staffs
        : staffs.take(initialLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact single-line summary + mini legend (no long paragraph on mobile)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                l10n.autoAssignFairnessRangeLabel(
                  analytics.minMonthlyWorkload,
                  analytics.maxMonthlyWorkload,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildLegendDot(
                  theme,
                  cs.primary,
                  l10n.autoAssignMonthlyLoadLabel,
                ),
                _buildLegendDot(
                  theme,
                  cs.onSurfaceVariant,
                  l10n.autoAssignActiveLoadLabel,
                ),
                _buildLegendDot(
                  theme,
                  semantic.success,
                  l10n.autoAssignOnTimeLabel,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (analyticsAsync.isLoading && staffs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (analyticsAsync.hasError && staffs.isEmpty)
          _buildLoadErrorBanner(
            theme,
            cs,
            l10n,
            onRetry: () => ref.invalidate(autoAssignAnalyticsProvider),
          )
        else if (staffs.isEmpty)
          Text(
            l10n.autoAssignNoCandidatesDefault,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        else ...[
          Column(
            children: [
              for (int i = 0; i < visibleStaffs.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 14,
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                _buildStaffWorkloadBarRow(
                  theme,
                  cs,
                  semantic,
                  visibleStaffs[i],
                  maxMonthly <= 0 ? 1 : maxMonthly,
                ),
              ],
            ],
          ),
          if (hasMore) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _showAllStaffFairness = !_showAllStaffFairness,
                ),
                icon: Icon(
                  _showAllStaffFairness
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(
                  _showAllStaffFairness
                      ? l10n.autoAssignSectionCollapse
                      : '${l10n.autoAssignSectionExpand} (${staffs.length})',
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLegendDot(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffWorkloadBarRow(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    StaffWorkloadFairnessModel item,
    int barMax,
  ) {
    final progress = (item.monthlyWorkload / barMax).clamp(0.0, 1.0);
    final isHighLoad = item.monthlyWorkload >= item.targetMonthlyTasks;
    final barColor = isHighLoad ? semantic.warning : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppNetworkImage(
              url: item.avatarUrl,
              width: 26,
              height: 26,
              isCircle: true,
              errorWidget: CircleAvatar(
                radius: 13,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline,
                  size: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  if (item.positionName != null &&
                      item.positionName!.isNotEmpty)
                    Text(
                      item.positionName!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Compact numeric metrics without repeating verbose words on every row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${item.monthlyWorkload}/${item.targetMonthlyTasks}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: barColor,
                      fontFeatures: _tabular,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.activeProcessingCount}/${item.maxConcurrentTasks}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.onTimeRate30d.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: semantic.success,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionLogsContent(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    AsyncValue<AssignmentDecisionLogPageModel> logsAsync,
  ) {
    final filter = ref.watch(autoAssignLogsFilterProvider);
    final pageData =
        logsAsync.valueOrNull ?? const AssignmentDecisionLogPageModel();
    final logs = pageData.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildOutcomeFilterChip(
              l10n.autoAssignLogsFilterAll,
              'all',
              filter.outcome,
            ),
            _buildOutcomeFilterChip(
              l10n.autoAssignLogsFilterAssigned,
              'ASSIGNED',
              filter.outcome,
            ),
            _buildOutcomeFilterChip(
              l10n.autoAssignLogsFilterRecommended,
              'RECOMMENDED',
              filter.outcome,
            ),
            _buildOutcomeFilterChip(
              l10n.autoAssignLogsFilterOverridden,
              'OVERRIDDEN',
              filter.outcome,
            ),
            _buildOutcomeFilterChip(
              l10n.autoAssignLogsFilterFallback,
              'FALLBACK_PENDING',
              filter.outcome,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (logsAsync.isLoading && logs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (logsAsync.hasError && logs.isEmpty)
          _buildLoadErrorBanner(
            theme,
            cs,
            l10n,
            onRetry: () => ref.invalidate(autoAssignLogsProvider),
          )
        else if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.autoAssignLogsEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                _buildDecisionLogRow(theme, cs, semantic, l10n, logs[i]),
              ],
            ],
          ),
        if (pageData.totalPages > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.autoAssignLogPageInfo(
                    pageData.currentPage,
                    pageData.totalPages,
                    pageData.totalElements,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: filter.page > 1
                        ? () {
                            ref
                                .read(autoAssignLogsFilterProvider.notifier)
                                .state = filter.copyWith(
                              page: filter.page - 1,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: filter.page < pageData.totalPages
                        ? () {
                            ref
                                .read(autoAssignLogsFilterProvider.notifier)
                                .state = filter.copyWith(
                              page: filter.page + 1,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOutcomeFilterChip(
    String label,
    String value,
    String currentOutcome,
  ) {
    final selected = currentOutcome == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      visualDensity: VisualDensity.compact,
      onSelected: (_) {
        final current = ref.read(autoAssignLogsFilterProvider);
        ref.read(autoAssignLogsFilterProvider.notifier).state = current
            .copyWith(outcome: value, page: 1);
      },
    );
  }

  Widget _buildLoadErrorBanner(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n, {
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 18, color: cs.error),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.autoAssignLoadFailed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.retry),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionLogRow(
    ThemeData theme,
    ColorScheme cs,
    AppSemanticColors semantic,
    AppLocalizations l10n,
    AssignmentDecisionLogItemModel log,
  ) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final catName = isVi
        ? (log.categoryNameVi ?? log.categoryCode ?? '')
        : (log.categoryNameEn ?? log.categoryCode ?? '');
    final timeStr = log.createdAt != null
        ? DateFormat('dd/MM HH:mm').format(log.createdAt!.toLocal())
        : '';

    final (String badgeText, Color badgeColor) = switch (log.outcome) {
      'OVERRIDDEN' => (l10n.autoAssignSourceOverridden, semantic.warning),
      'RECOMMENDED' => (l10n.autoAssignSourceRecommended, cs.primary),
      'FALLBACK_PENDING' => (l10n.autoAssignSourceFallback, cs.error),
      _ => (
          log.source == 'RECOMMEND_CLICK'
              ? l10n.autoAssignSourceRecommendClick
              : l10n.autoAssignSourceAuto,
          semantic.success,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (catName.isNotEmpty)
                  Text(
                    catName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (timeStr.isNotEmpty)
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFeatures: _tabular,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          log.reportTitle ?? log.reportId ?? log.id,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: log.selectedStaffName != null &&
                      log.selectedStaffName!.isNotEmpty
                  ? Text(
                      log.outcome == 'OVERRIDDEN' &&
                              log.overriddenToStaffName != null
                          ? '${log.selectedStaffName} → ${log.overriddenToStaffName}'
                          : '${log.selectedStaffName}${log.selectedStaffPositionName != null ? ' (${log.selectedStaffPositionName})' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    )
                  : Text(
                      log.fallbackMessage ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                      ),
                    ),
            ),
            if (log.finalScore != null) ...[
              const SizedBox(width: 6),
              _buildMetricPill(
                theme,
                cs,
                l10n.autoAssignScoreValue(log.finalScore!.toStringAsFixed(1)),
              ),
            ],
            if (log.reportId != null && log.reportId!.isNotEmpty) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => context.push(
                  RouterPath.reportDetailWithId(log.reportId!),
                ),
                tooltip: l10n.autoAssignLogViewReport,
                icon: const Icon(Icons.open_in_new, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
