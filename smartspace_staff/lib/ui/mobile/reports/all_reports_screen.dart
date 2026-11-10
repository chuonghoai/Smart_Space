import 'package:flutter/material.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/staff_report_sort.dart';
import 'package:smartspace_staff/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_staff/ui/mobile/reports/all_reports_controller.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_feed_item.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_filters/assigned_report_filter_options.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_filters/report_date_range_filter_chip.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_filters/report_filter_bar.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_filters/report_filter_chip.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_filters/report_filter_sheet.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:geolocator/geolocator.dart';

class AllReportsScreen extends StatefulWidget {
  final String initialFilter;

  const AllReportsScreen({super.key, required this.initialFilter});

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen> {
  late final AllReportsController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _controller = AllReportsController(initialFilter: widget.initialFilter);
    _scrollController.addListener(_onScroll);
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      final position = await locationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Could not get location: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myWorkDashboard),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _getLocation();
              await _controller.fetchInitial();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: ReportFilterBar(
                  searchController: _searchController,
                  searchHint: l10n.searchAssignedReportsPlaceholder,
                  onSearchChanged: _controller.setSearch,
                  isFiltering: state.isFiltering,
                  onClearFilters: _controller.clearFilters,
                  chips: _buildFilterChips(context, state, l10n),
                ),
              ),
              const Divider(height: 1),
              
              // List
              Expanded(
                child: state.isLoading && state.reports.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && state.reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _controller.fetchInitial,
                                  child: Text(l10n.retryButton),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _getLocation();
                              await _controller.fetchInitial();
                            },
                            child: state.reports.isEmpty
                                ? LayoutBuilder(
                                    builder: (context, constraints) => SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                state.isFiltering ? l10n.noMatchingAssignedReports : l10n.noReportsYet,
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                              if (state.isFiltering) ...[
                                                const SizedBox(height: 8),
                                                TextButton(
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    _controller.clearFilters();
                                                  },
                                                  child: Text(l10n.clearFilter),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.reports.length + (state.hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == state.reports.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final report = state.reports[index];
                                      return ReportFeedItem(
                                        report: report,
                                        userPosition: _currentPosition,
                                        onTap: () {
                                          context.push(
                                            RouterPath.reportDetail.replaceFirst(':id', report.id),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context, AllReportsState state, AppLocalizations l10n) {
    final statusActive = state.filter != AllReportsState.allStatus;
    final severity = state.severity;
    final sortActive = state.sort != StaffReportSort.latest;

    return [
      ReportFilterChip(
        label: l10n.statusLabel,
        valueLabel: statusActive ? AssignedReportFilterOptions.statusLabel(state.filter, l10n) : null,
        active: statusActive,
        onTap: () => showReportFilterSheet<String>(
          context: context,
          title: l10n.statusLabel,
          options: AssignedReportFilterOptions.statuses(l10n, state.stats),
          selected: state.filter,
          onSelected: _controller.setFilter,
        ),
      ),
      ReportFilterChip(
        label: l10n.severityLabel,
        valueLabel: severity?.getLocalizedText(l10n),
        active: severity != null,
        onTap: () => showReportFilterSheet<ReportSeverity?>(
          context: context,
          title: l10n.severityLabel,
          options: AssignedReportFilterOptions.severities(l10n),
          selected: severity,
          onSelected: _controller.setSeverity,
        ),
      ),
      ReportDateRangeFilterChip(
        value: state.dateRange,
        onChanged: _controller.setDateRange,
      ),
      ReportFilterChip(
        label: l10n.sortLabel,
        valueLabel: sortActive ? AssignedReportFilterOptions.sortLabel(state.sort, l10n) : null,
        active: sortActive,
        icon: AssignedReportFilterOptions.sortIcon(state.sort),
        onTap: () => showReportFilterSheet<StaffReportSort>(
          context: context,
          title: l10n.sortLabel,
          options: AssignedReportFilterOptions.sorts(l10n),
          selected: state.sort,
          onSelected: _controller.setSort,
        ),
      ),
    ];
  }
}
