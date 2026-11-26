import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/widgets/confirm_dialog.dart';
import 'package:smartspace_client/ui/mobile/auth/register/register_controller.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class MobileCompleteProfileScreen extends StatefulWidget {
  const MobileCompleteProfileScreen({super.key});

  @override
  State<MobileCompleteProfileScreen> createState() =>
      _MobileCompleteProfileScreenState();
}

class _MobileCompleteProfileScreenState
    extends State<MobileCompleteProfileScreen> {
  late final RegisterController _controller;

  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();

  final FocusNode _fullnameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  // Inline validation error states
  bool _fullnameError = false;
  bool _phoneError = false;

  @override
  void initState() {
    super.initState();
    _controller = registerController;
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _fullnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _controller.setDateOfBirth(_dateOfBirthController.text);
    }
  }

  Future<void> _submit() async {
    // Inline validation with focus & red border
    final fullnameEmpty = _fullnameController.text.trim().isEmpty;
    final phoneEmpty = _phoneController.text.trim().isEmpty;

    if (fullnameEmpty || phoneEmpty) {
      setState(() {
        _fullnameError = fullnameEmpty;
        _phoneError = phoneEmpty;
      });
      if (fullnameEmpty) {
        _fullnameFocusNode.requestFocus();
      } else {
        _phoneFocusNode.requestFocus();
      }
      return;
    }

    // Kiểm tra ngày sinh
    final l10n = AppLocalizations.of(context)!;
    if (_dateOfBirthController.text.isEmpty) {
      final confirmed = await ConfirmDialog.show(
        context: context,
        title: l10n.dateOfBirthEmptyTitle,
        message: l10n.dateOfBirthEmptyMessage,
        okLabel: l10n.confirm,
        cancelLabel: l10n.cancel,
      );
      if (confirmed != true) return;
      
      // Kiểm tra giới tính
      if (_controller.selectedGender == null) return;
      if (_controller.selectedGender == 'other') {
        final confirmed = await ConfirmDialog.show(
          // ignore: use_build_context_synchronously
          context: context,
          title: l10n.gender,
          message: l10n.genderOtherConfirmMessage,
          okLabel: l10n.confirm,
          cancelLabel: l10n.cancel,
        );
        if (confirmed != true) return;
      }
    }

    _controller.completeProfile(
      // ignore: use_build_context_synchronously
      context: context,
      fullname: _fullnameController.text,
      phone: _phoneController.text,
      dateOfBirth: _dateOfBirthController.text.isNotEmpty
          ? _dateOfBirthController.text
          : null,
      gender: _controller.selectedGender,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          l10n.completeProfile,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.profileTitle,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Avatar Picker
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              _controller.selectAvatar(ImageSource.gallery);
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                _controller.selectedAvatarBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          _controller.selectedAvatarBytes!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 50,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            l10n.avatar,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error message from controller
                        if (_controller.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _controller.error!,
                              style: TextStyle(color: colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Fullname — Bắt buộc
                        _buildLabel(
                          textTheme,
                          l10n.fullname,
                          required: true,
                        ),
                        TextField(
                          controller: _fullnameController,
                          focusNode: _fullnameFocusNode,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                          decoration: InputDecoration(
                            hintText: l10n.fullname,
                            prefixIcon: const Icon(Icons.person_outline),
                            errorText: _fullnameError
                                ? l10n.pleaseEnterFullName
                                : null,
                          ),
                          onChanged: (value) {
                            _controller.clearError();
                            if (_fullnameError && value.trim().isNotEmpty) {
                              setState(() => _fullnameError = false);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Phone — Bắt buộc
                        _buildLabel(
                          textTheme,
                          l10n.phone,
                          required: true,
                        ),
                        TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            // move focus to date field (triggers picker)
                            _selectDate(context);
                          },
                          decoration: InputDecoration(
                            hintText: l10n.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            errorText: _phoneError
                                ? l10n.pleaseEnterPhoneNumber
                                : null,
                          ),
                          onChanged: (value) {
                            _controller.clearError();
                            if (_phoneError && value.trim().isNotEmpty) {
                              setState(() => _phoneError = false);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Date of Birth — Không bắt buộc
                        _buildLabel(
                          textTheme,
                          l10n.dateOfBirth,
                          required: false,
                        ),
                        TextField(
                          readOnly: true,
                          controller: _dateOfBirthController,
                          onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            hintText: 'yyyy-MM-dd',
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Gender — Không bắt buộc
                        _buildLabel(
                          textTheme,
                          l10n.gender,
                          required: false,
                        ),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'male',
                              label: Text(l10n.genderMale),
                              icon: const Icon(Icons.male),
                            ),
                            ButtonSegment(
                              value: 'female',
                              label: Text(l10n.genderFemale),
                              icon: const Icon(Icons.female),
                            ),
                            ButtonSegment(
                              value: 'other',
                              label: Text(l10n.genderOther),
                            ),
                          ],
                          selected: {
                            _controller.selectedGender ?? 'other',
                          },
                          emptySelectionAllowed: true,
                          onSelectionChanged: (Set<String> newSelection) async {
                            if (newSelection.isEmpty) return;
                            final picked = newSelection.first;
                            _controller.setGender(picked);
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Footer: Submit button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: ElevatedButton(
                    onPressed: _controller.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _controller.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.continueText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Label row
  Widget _buildLabel(
    TextTheme textTheme,
    String text, {
    required bool required,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
