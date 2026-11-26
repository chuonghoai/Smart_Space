import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/emergency/emergency_contacts_controller.dart';
import 'package:smartspace_client/ui/mobile/emergency/widgets/emergency_contact_widgets.dart';

/// Mở form thêm (contact == null) hoặc sửa liên hệ; trả về liên hệ đã lưu.
Future<EmergencyContactModel?> showEmergencyContactFormSheet(
  BuildContext context, {
  EmergencyContactModel? contact,
}) {
  return showModalBottomSheet<EmergencyContactModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => EmergencyContactFormSheet(contact: contact),
  );
}

class EmergencyContactFormSheet extends ConsumerStatefulWidget {
  final EmergencyContactModel? contact;

  const EmergencyContactFormSheet({super.key, this.contact});

  @override
  ConsumerState<EmergencyContactFormSheet> createState() => _EmergencyContactFormSheetState();
}

class _EmergencyContactFormSheetState extends ConsumerState<EmergencyContactFormSheet> {
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _relationshipFocus = FocusNode();
  final _emailFocus = FocusNode();

  EEmergencyRelationship? _relationship;
  bool _consentConfirmed = false;

  bool get _isEdit => widget.contact != null;

  bool get _hasAccount => _emailCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    // Xoá trống email khi sửa nghĩa là bỏ liên kết tài khoản, chuyển sang liên hệ qua SMS
    _emailCtrl = TextEditingController(text: c?.accountEmail ?? '');
    _relationship = c?.relationship;
    _consentConfirmed = c?.isSelfDeclared ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _relationshipFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final dto = EmergencyContactDto(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      relationship: _relationship!,
      accountEmail: _emailCtrl.text,
      consentConfirmed: !_hasAccount && _consentConfirmed,
    );
    final saved = await ref
        .read(emergencyContactFormControllerProvider.notifier)
        .submit(dto, editingId: widget.contact?.id);
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formState = ref.watch(emergencyContactFormControllerProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEdit ? l10n.emergencyFormEditTitle : l10n.emergencyFormAddTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(labelText: l10n.emergencyFormName, counterText: ''),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.emergencyFormNameRequired : null,
                onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: InputDecoration(labelText: l10n.phone),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.emergencyFormPhoneRequired;
                  return isValidVnMobile(v) ? null : l10n.emergencyFormPhoneInvalid;
                },
                onFieldSubmitted: (_) => _relationshipFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EEmergencyRelationship>(
                focusNode: _relationshipFocus,
                initialValue: _relationship,
                decoration: InputDecoration(labelText: l10n.emergencyFormRelationship),
                items: [
                  for (final r in EEmergencyRelationship.values)
                    DropdownMenuItem(value: r, child: Text(emergencyRelationshipLabel(l10n, r))),
                ],
                validator: (v) => v == null ? l10n.emergencyFormRelationshipRequired : null,
                onChanged: (v) {
                  setState(() => _relationship = v);
                  _emailFocus.requestFocus();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: l10n.emergencyFormAccountEmail,
                  helperText: l10n.emergencyFormAccountEmailHelp,
                  helperMaxLines: 3,
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return null;
                  return _emailRegex.hasMatch(value) ? null : l10n.emergencyFormEmailInvalid;
                },
                // Ô xác nhận chỉ áp dụng khi không liên kết tài khoản
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (!_hasAccount) ...[
                const SizedBox(height: 8),
                FormField<bool>(
                  initialValue: _consentConfirmed,
                  validator: (_) => _consentConfirmed ? null : l10n.emergencyFormConsentRequired,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: _consentConfirmed,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(l10n.emergencyFormConsent, style: theme.textTheme.bodyMedium),
                        onChanged: (v) {
                          setState(() => _consentConfirmed = v ?? false);
                          field.didChange(v);
                        },
                      ),
                      if (field.hasError)
                        Text(
                          field.errorText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (_isEdit) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.emergencyFormReconfirmNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (formState.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  formState.error!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: formState.isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: formState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.emergencyFormSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
