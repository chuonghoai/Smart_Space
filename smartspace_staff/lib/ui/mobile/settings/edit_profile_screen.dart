import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/settings/edit_profile_controller.dart';
import 'package:smartspace_staff/ui/shared/image/app_network_image.dart';

class MobileEditProfileScreen extends StatefulWidget {
  const MobileEditProfileScreen({super.key});

  @override
  State<MobileEditProfileScreen> createState() =>
      _MobileEditProfileScreenState();
}

class _MobileEditProfileScreenState extends State<MobileEditProfileScreen> {
  static const _dateFormat = 'yyyy-MM-dd';

  late final EditProfileController _controller;

  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _fullnameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController();
    _initData();
  }

  Future<void> _initData() async {
    await _controller.loadUser();
    final user = _controller.user;
    if (user != null) {
      _fullnameController.text = user.fullname;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _dateOfBirthController.text = user.dateOfBirth ?? '';
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _fullnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_dateOfBirthController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isBefore(now) ? current : now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat(_dateFormat).format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
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
                      // Avatar
                      Center(
                        child: GestureDetector(
                          onTap: () => _controller.selectAvatar(
                            ImageSource.gallery,
                            failedMessage: l10n.pickImageFailed,
                          ),
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
                                  : AppNetworkImage(
                                      url: _controller.user?.avatarUrl,
                                      width: 100,
                                      height: 100,
                                      isCircle: true,
                                      errorWidget: CircleAvatar(
                                        radius: 50,
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 50,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                              Container(
                                padding: const EdgeInsets.all(6),
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
                          l10n.changeAvatar,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Error
                      if (_controller.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _controller.error!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Fullname
                      _label(textTheme, l10n.fullname),
                      TextField(
                        controller: _fullnameController,
                        focusNode: _fullnameFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                        decoration: InputDecoration(
                          hintText: l10n.fullname,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email (read-only)
                      _label(textTheme, l10n.email),
                      TextField(
                        readOnly: true,
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date of birth
                      _label(textTheme, l10n.dateOfBirth),
                      TextField(
                        readOnly: true,
                        controller: _dateOfBirthController,
                        onTap: () => _selectDate(context),
                        decoration: const InputDecoration(
                          hintText: _dateFormat,
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Gender
                      _label(textTheme, l10n.gender),
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
                        selected: {_controller.selectedGender ?? 'other'},
                        onSelectionChanged: (s) =>
                            _controller.setGender(s.first),
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      _label(textTheme, l10n.phone),
                      TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(context),
                        decoration: InputDecoration(
                          hintText: l10n.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: _controller.isLoading
                            ? null
                            : () => _save(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _controller.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                l10n.saveChanges,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _controller.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(TextTheme textTheme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  void _save(BuildContext context) {
    _controller.saveProfile(
      context: context,
      fullName: _fullnameController.text,
      phone: _phoneController.text,
      dateOfBirth: _dateOfBirthController.text.isNotEmpty
          ? _dateOfBirthController.text
          : null,
    );
  }
}
