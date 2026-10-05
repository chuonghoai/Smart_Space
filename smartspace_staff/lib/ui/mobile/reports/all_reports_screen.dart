import 'package:flutter/material.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_staff/ui/mobile/reports/all_reports_controller.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_feed_item.dart';
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
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;

          return Column(
            children: [
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip(state, 'all', l10n.filterAll),
                    const SizedBox(width: 8),
                    _buildFilterChip(state, 'pending', l10n.reportStatusPending),
                    const SizedBox(width: 8),
                    _buildFilterChip(state, 'processing', l10n.reportStatusProcessing),
                    const SizedBox(width: 8),
                    _buildFilterChip(state, 'resolved', l10n.reportStatusProcessed),
                  ],
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
                        : state.reports.isEmpty
                            ? Center(child: Text(l10n.noReportsYet))
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _getLocation();
                                  await _controller.fetchInitial();
                                },
                                child: ListView.builder(
                                  controller: _scrollController,
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

  Widget _buildFilterChip(AllReportsState state, String filterValue, String label) {
    final isSelected = state.filter == filterValue;
    String displayLabel = label;
    
    if (state.stats != null) {
      int count = 0;
      if (filterValue == 'all') {
        count = state.stats!.pending + state.stats!.processing;
      } else if (filterValue == 'pending') {
        count = state.stats!.pending;
      } else if (filterValue == 'processing') {
        count = state.stats!.processing;
      } else if (filterValue == 'resolved') {
        count = state.stats!.resolved;
      }
      displayLabel = '$label ($count)';
    }

    return ChoiceChip(
      label: Text(displayLabel),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _controller.setFilter(filterValue);
        }
      },
    );
  }
}
