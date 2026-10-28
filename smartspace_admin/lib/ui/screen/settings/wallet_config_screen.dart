import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/wallet_config/application/wallet_config_controller.dart';
import 'package:smartspace_admin/features/wallet_config/models/wallet_config_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

class WalletConfigScreen extends StatefulWidget {
  const WalletConfigScreen({super.key});

  @override
  State<WalletConfigScreen> createState() => _WalletConfigScreenState();
}

class _WalletConfigScreenState extends State<WalletConfigScreen> {
  late final WalletConfigController _controller;

  final _formKey = GlobalKey<FormState>();
  final _commissionLowCtrl = TextEditingController();
  final _commissionMediumCtrl = TextEditingController();
  final _commissionHighCtrl = TextEditingController();
  final _commissionCriticalCtrl = TextEditingController();
  final _penaltyRate1Ctrl = TextEditingController();
  final _penaltyRate2Ctrl = TextEditingController();
  final _penaltyRate3Ctrl = TextEditingController();

  bool _initializedFromModel = false;

  @override
  void initState() {
    super.initState();
    _controller = WalletConfigController();
    _controller.loadConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    _commissionLowCtrl.dispose();
    _commissionMediumCtrl.dispose();
    _commissionHighCtrl.dispose();
    _commissionCriticalCtrl.dispose();
    _penaltyRate1Ctrl.dispose();
    _penaltyRate2Ctrl.dispose();
    _penaltyRate3Ctrl.dispose();
    super.dispose();
  }

  void _populateFields(WalletConfigModel config) {
    _commissionLowCtrl.text = config.commissionLow.round().toString();
    _commissionMediumCtrl.text = config.commissionMedium.round().toString();
    _commissionHighCtrl.text = config.commissionHigh.round().toString();
    _commissionCriticalCtrl.text = config.commissionCritical.round().toString();
    _penaltyRate1Ctrl.text = (config.penaltyRate1 * 100).round().toString();
    _penaltyRate2Ctrl.text = (config.penaltyRate2 * 100).round().toString();
    _penaltyRate3Ctrl.text = (config.penaltyRate3 * 100).round().toString();
    _initializedFromModel = true;
  }

  Future<void> _handleSave(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final low = double.tryParse(_commissionLowCtrl.text.trim()) ?? 0;
    final medium = double.tryParse(_commissionMediumCtrl.text.trim()) ?? 0;
    final high = double.tryParse(_commissionHighCtrl.text.trim()) ?? 0;
    final critical = double.tryParse(_commissionCriticalCtrl.text.trim()) ?? 0;

    final p1 = (double.tryParse(_penaltyRate1Ctrl.text.trim()) ?? 0) / 100.0;
    final p2 = (double.tryParse(_penaltyRate2Ctrl.text.trim()) ?? 0) / 100.0;
    final p3 = (double.tryParse(_penaltyRate3Ctrl.text.trim()) ?? 0) / 100.0;

    final updatedModel = WalletConfigModel(
      commissionLow: low,
      commissionMedium: medium,
      commissionHigh: high,
      commissionCritical: critical,
      penaltyRate1: p1,
      penaltyRate2: p2,
      penaltyRate3: p3,
    );

    final success = await _controller.updateConfig(updatedModel);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveWalletConfigSuccess),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2E7D32)
              : const Color(0xFF43A047),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.error ?? l10n.saveWalletConfigFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppLayout(
      customAppBar: AppBar(
        title: Text(l10n.walletConfigTitle),
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RouterPath.settings),
              ),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.config != null && !_initializedFromModel) {
            _populateFields(_controller.config!);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Info description header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                        : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.walletConfigDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: Commission by Severity
                _buildSectionTitle(theme, l10n.commissionBySeverity, Icons.monetization_on_outlined),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCurrencyField(
                          label: l10n.commissionLow,
                          controller: _commissionLowCtrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildCurrencyField(
                          label: l10n.commissionMedium,
                          controller: _commissionMediumCtrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildCurrencyField(
                          label: l10n.commissionHigh,
                          controller: _commissionHighCtrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildCurrencyField(
                          label: l10n.commissionCritical,
                          controller: _commissionCriticalCtrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Penalty Rates
                _buildSectionTitle(theme, l10n.penaltyRateSettings, Icons.percent_outlined),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPercentageField(
                          label: l10n.penaltyRate1,
                          controller: _penaltyRate1Ctrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildPercentageField(
                          label: l10n.penaltyRate2,
                          controller: _penaltyRate2Ctrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 16),
                        _buildPercentageField(
                          label: l10n.penaltyRate3,
                          controller: _penaltyRate3Ctrl,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.penaltyRateNote,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? const Color(0xFFFFCDD2) : const Color(0xFFB71C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _controller.isSaving ? null : () => _handleSave(l10n),
                    icon: _controller.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.saveWalletConfig),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyField({
    required String label,
    required TextEditingController controller,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'VNĐ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n.invalidNumber;
        }
        final parsed = double.tryParse(val.trim());
        if (parsed == null || parsed < 0) {
          return l10n.invalidNumber;
        }
        return null;
      },
    );
  }

  Widget _buildPercentageField({
    required String label,
    required TextEditingController controller,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n.invalidNumber;
        }
        final parsed = double.tryParse(val.trim());
        if (parsed == null || parsed < 0 || parsed > 100) {
          return l10n.invalidNumber;
        }
        return null;
      },
    );
  }
}

