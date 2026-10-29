import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/wallet_config/application/wallet_config_controller.dart';
import 'package:smartspace_admin/features/wallet_config/models/wallet_config_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

class CommissionConfigScreen extends StatefulWidget {
  const CommissionConfigScreen({super.key});

  @override
  State<CommissionConfigScreen> createState() => _CommissionConfigScreenState();
}

class _CommissionConfigScreenState extends State<CommissionConfigScreen> {
  late final WalletConfigController _controller;

  final _formKey = GlobalKey<FormState>();
  final _commissionLowCtrl = TextEditingController();
  final _commissionMediumCtrl = TextEditingController();
  final _commissionHighCtrl = TextEditingController();
  final _commissionCriticalCtrl = TextEditingController();

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
    super.dispose();
  }

  void _populateFields(WalletConfigModel config) {
    _commissionLowCtrl.text = config.commissionLow.round().toString();
    _commissionMediumCtrl.text = config.commissionMedium.round().toString();
    _commissionHighCtrl.text = config.commissionHigh.round().toString();
    _commissionCriticalCtrl.text = config.commissionCritical.round().toString();
    _initializedFromModel = true;
  }

  Future<void> _handleSave(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final low = double.tryParse(_commissionLowCtrl.text.trim()) ?? 0;
    final medium = double.tryParse(_commissionMediumCtrl.text.trim()) ?? 0;
    final high = double.tryParse(_commissionHighCtrl.text.trim()) ?? 0;
    final critical = double.tryParse(_commissionCriticalCtrl.text.trim()) ?? 0;

    final currentConfig = _controller.config;
    final updatedModel = WalletConfigModel(
      commissionLow: low,
      commissionMedium: medium,
      commissionHigh: high,
      commissionCritical: critical,
      penaltyRate1: currentConfig?.penaltyRate1 ?? 0.2,
      penaltyRate2: currentConfig?.penaltyRate2 ?? 0.2,
      penaltyRate3: currentConfig?.penaltyRate3 ?? 0.6,
    );

    final success = await _controller.updateConfig(updatedModel);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveCommissionSuccess),
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppLayout(
      customAppBar: AppBar(
        title: Text(l10n.commissionConfig),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                // Info header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                        : colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.commissionConfigDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
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
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _controller.isSaving ? null : () => _handleSave(l10n),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _controller.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.saveWalletConfig,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n.invalidNumber;
        }
        final n = double.tryParse(val.trim());
        if (n == null || n < 0) {
          return l10n.invalidNumber;
        }
        return null;
      },
    );
  }
}

