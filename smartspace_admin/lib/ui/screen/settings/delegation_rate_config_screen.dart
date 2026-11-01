import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/delegation_config/application/delegation_rate_config_provider.dart';
import 'package:smartspace_admin/features/delegation_config/models/delegation_rate_config_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

/// Cấu hình hệ thống → Cấu hình hoa hồng công việc được nhờ.
/// Mỗi mức độ có một ô %, bên dưới là ví dụ số tiền tính ngay theo hoa hồng hiện tại.
class DelegationRateConfigScreen extends ConsumerStatefulWidget {
  const DelegationRateConfigScreen({super.key});

  @override
  ConsumerState<DelegationRateConfigScreen> createState() => _DelegationRateConfigScreenState();
}

class _DelegationRateConfigScreenState extends ConsumerState<DelegationRateConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lowCtrl = TextEditingController();
  final _mediumCtrl = TextEditingController();
  final _highCtrl = TextEditingController();
  final _criticalCtrl = TextEditingController();

  bool _populated = false;
  bool _isSaving = false;

  static final _money = NumberFormat('#,###', 'vi_VN');

  @override
  void dispose() {
    _lowCtrl.dispose();
    _mediumCtrl.dispose();
    _highCtrl.dispose();
    _criticalCtrl.dispose();
    super.dispose();
  }

  void _populate(DelegationRateConfigModel config) {
    String text(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
    _lowCtrl.text = text(config.rateLow);
    _mediumCtrl.text = text(config.rateMedium);
    _highCtrl.text = text(config.rateHigh);
    _criticalCtrl.text = text(config.rateCritical);
    _populated = true;
  }

  static double? _parse(String raw) {
    final value = double.tryParse(raw.trim());
    return value != null && value >= 0 && value <= 100 ? value : null;
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final error = await ref.read(delegationRateConfigProvider.notifier).save(
          low: _parse(_lowCtrl.text)!,
          medium: _parse(_mediumCtrl.text)!,
          high: _parse(_highCtrl.text)!,
          critical: _parse(_criticalCtrl.text)!,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error == null ? l10n.saveDelegationRateSuccess : (error.isNotEmpty ? error : l10n.saveWalletConfigFailed)),
          backgroundColor: error == null ? null : cs.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final configAsync = ref.watch(delegationRateConfigProvider);

    return AppLayout(
      customAppBar: AppBar(
        title: Text(l10n.delegationRateConfig),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      child: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: l10n.delegationRateLoadFailed,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(delegationRateConfigProvider),
        ),
        data: (config) {
          if (!_populated) _populate(config);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _InfoHeader(text: l10n.delegationRateConfigDescription),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _rateField(l10n, l10n.severityLow, _lowCtrl, config.commissionLow),
                        const SizedBox(height: 16),
                        _rateField(l10n, l10n.severityMedium, _mediumCtrl, config.commissionMedium),
                        const SizedBox(height: 16),
                        _rateField(l10n, l10n.severityHigh, _highCtrl, config.commissionHigh),
                        const SizedBox(height: 16),
                        _rateField(l10n, l10n.severityCritical, _criticalCtrl, config.commissionCritical),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.delegationRateNote,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : () => _save(l10n),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                          )
                        : Text(
                            l10n.saveWalletConfig,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  /// Ô % theo mức độ + dòng ví dụ số tiền cập nhật theo giá trị đang gõ.
  Widget _rateField(AppLocalizations l10n, String label, TextEditingController controller, double commission) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
          decoration: InputDecoration(
            labelText: label,
            suffixText: '%',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (value) => _parse(value ?? '') == null ? l10n.invalidNumber : null,
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final rate = _parse(value.text);
            if (rate == null) return const SizedBox.shrink();
            final bonus = DelegationRateConfigModel.bonusOf(commission, rate);
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                l10n.delegationRateExample(
                  value.text.trim(),
                  _money.format(commission),
                  _money.format(bonus),
                ),
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final String text;

  const _InfoHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final info = AppSemanticColors.of(context).info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.handshake_outlined, color: info, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.retryLabel, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
