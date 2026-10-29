import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/wallet_config/application/wallet_config_controller.dart';
import 'package:smartspace_admin/features/wallet_config/models/wallet_config_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

class PenaltyRateConfigScreen extends StatefulWidget {
  const PenaltyRateConfigScreen({super.key});

  @override
  State<PenaltyRateConfigScreen> createState() => _PenaltyRateConfigScreenState();
}

class _PenaltyRateConfigScreenState extends State<PenaltyRateConfigScreen> {
  late final WalletConfigController _controller;

  final _formKey = GlobalKey<FormState>();
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
    _penaltyRate1Ctrl.dispose();
    _penaltyRate2Ctrl.dispose();
    _penaltyRate3Ctrl.dispose();
    super.dispose();
  }

  void _populateFields(WalletConfigModel config) {
    _penaltyRate1Ctrl.text = (config.penaltyRate1 * 100).round().toString();
    _penaltyRate2Ctrl.text = (config.penaltyRate2 * 100).round().toString();
    _penaltyRate3Ctrl.text = (config.penaltyRate3 * 100).round().toString();
    _initializedFromModel = true;
  }

  Future<void> _handleSave(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final p1 = (double.tryParse(_penaltyRate1Ctrl.text.trim()) ?? 0) / 100.0;
    final p2 = (double.tryParse(_penaltyRate2Ctrl.text.trim()) ?? 0) / 100.0;
    final p3 = (double.tryParse(_penaltyRate3Ctrl.text.trim()) ?? 0) / 100.0;

    final currentConfig = _controller.config;
    final updatedModel = WalletConfigModel(
      commissionLow: currentConfig?.commissionLow ?? 2000.0,
      commissionMedium: currentConfig?.commissionMedium ?? 5000.0,
      commissionHigh: currentConfig?.commissionHigh ?? 7000.0,
      commissionCritical: currentConfig?.commissionCritical ?? 10000.0,
      penaltyRate1: p1,
      penaltyRate2: p2,
      penaltyRate3: p3,
    );

    final success = await _controller.updateConfig(updatedModel);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.savePenaltyRateSuccess),
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
        title: Text(l10n.penaltyRateConfig),
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
                        ? const Color(0xFFE65100).withValues(alpha: 0.15)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE65100).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.percent_outlined,
                        color: Color(0xFFE65100),
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.penaltyRateConfigDescription,
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.penaltyRateNote,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildPercentageField({
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
        suffixText: '%',
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
        if (n == null || n < 0 || n > 100) {
          return l10n.invalidNumber;
        }
        return null;
      },
    );
  }
}

