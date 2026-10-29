import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/wallet_management/application/admin_withdrawal_controller.dart';
import 'package:smartspace_admin/features/wallet_management/models/withdrawal_request_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';
import 'widgets/withdrawal_detail_modal.dart';

class AdminWithdrawalRequestsScreen extends StatefulWidget {
  final String? openWithdrawalId;
  final String? initialFilter;
  const AdminWithdrawalRequestsScreen({
    super.key,
    this.openWithdrawalId,
    this.initialFilter,
  });

  @override
  State<AdminWithdrawalRequestsScreen> createState() => _AdminWithdrawalRequestsScreenState();
}

class _AdminWithdrawalRequestsScreenState extends State<AdminWithdrawalRequestsScreen> {
  late final AdminWithdrawalController _controller;
  bool _hasAutoOpened = false;

  @override
  void initState() {
    super.initState();
    _controller = AdminWithdrawalController();
    _controller.addListener(_checkAutoOpen);
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _controller.setFilter(widget.initialFilter!);
    } else {
      _controller.loadRequests();
    }
  }

  void _checkAutoOpen() {
    if (_hasAutoOpened || widget.openWithdrawalId == null) return;
    final match = _controller.requests.where((r) => r.id == widget.openWithdrawalId).firstOrNull;
    if (match != null) {
      _hasAutoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WithdrawalDetailModal.show(
          context,
          request: match,
          controller: _controller,
          onSuccess: () => _controller.loadRequests(),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkAutoOpen);
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppLayout(
      customAppBar: AppBar(
        title: Text(l10n.withdrawalRequests),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              // Filter Tabs Row
              _buildFilterTabs(context, theme, colorScheme, l10n),
              const Divider(height: 1),

              // Requests List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _controller.refresh(),
                  child: _controller.isLoading && _controller.requests.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _controller.requests.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 54,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.noWithdrawalRequestsFound,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              itemCount: _controller.requests.length,
                              itemBuilder: (context, index) {
                                final req = _controller.requests[index];
                                return _buildRequestCard(context, theme, colorScheme, isDark, req, l10n);
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

  Widget _buildFilterTabs(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final filters = [
      {'key': 'ALL', 'label': l10n.filterAll},
      {'key': 'PENDING', 'label': l10n.statusPending},
      {'key': 'APPROVED', 'label': l10n.statusApproved},
      {'key': 'REJECTED', 'label': l10n.statusRejected},
      {'key': 'CANCELLED', 'label': l10n.statusCancelled},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = _controller.currentFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => _controller.setFilter(f['key']!),
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    WithdrawalRequestModel req,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: req.isPending
              ? const Color(0xFFF57F17).withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          WithdrawalDetailModal.show(
            context,
            request: req,
            controller: _controller,
            onSuccess: () => _controller.loadRequests(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Staff Name + Badge "Yêu cầu rút tiền"
              Row(
                children: [
                  AppNetworkImage(
                    url: req.staffAvatar,
                    width: 44,
                    height: 44,
                    isCircle: true,
                    errorWidget: CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.staffName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Nhãn "Yêu cầu rút tiền"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.withdrawalRequestBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(req.status, l10n),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom Row: Bank & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            req.bankName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(req.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),

              if (req.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatDate(req.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'APPROVED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = l10n.statusApproved;
        break;
      case 'REJECTED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = l10n.statusRejected;
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = l10n.statusCancelled;
        break;
      case 'PENDING':
      default:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        label = l10n.statusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

