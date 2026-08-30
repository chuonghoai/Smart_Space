import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartspace_staff/ui/mobile/auth/register/register_controller.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'components/web_auth_layout.dart';

class WebCompleteProfileScreen extends StatefulWidget {
  const WebCompleteProfileScreen({super.key});

  @override
  State<WebCompleteProfileScreen> createState() =>
      _WebCompleteProfileScreenState();
}

class _WebCompleteProfileScreenState extends State<WebCompleteProfileScreen> {
  late final RegisterController _controller;
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _fullnameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = registerController;
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _fullnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return WebAuthLayout(
      showBackButton: false,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.completeProfile,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileTitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Avatar Picker
              Center(
                child: GestureDetector(
                  onTap: () {
                    _controller.selectAvatar(ImageSource.gallery);
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage: _controller.selectedAvatarFile != null
                            ? (kIsWeb
                                  ? NetworkImage(
                                          _controller.selectedAvatarFile!.path,
                                        )
                                        as ImageProvider
                                  : FileImage(
                                      File(
                                        _controller.selectedAvatarFile!.path,
                                      ),
                                    ))
                            : null,
                        child: _controller.selectedAvatarFile == null
                            ? Icon(
                                Icons.person_outline,
                                size: 50,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
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

              // Error message
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

              // Fullname input
              Text(
                l10n.fullname,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullnameController,
                focusNode: _fullnameFocusNode,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  if (!_controller.isLoading) {
                    _controller.completeProfile(
                      context: context,
                      fullname: _fullnameController.text,
                      phone: _phoneController.text,
                    );
                  }
                },
                decoration: InputDecoration(hintText: l10n.fullname),
                onChanged: (value) => _controller.clearError(),
              ),
              const SizedBox(height: 20),

              // Phone input
              Text(
                l10n.phone,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_controller.isLoading) {
                    _controller.completeProfile(
                      context: context,
                      fullname: _fullnameController.text,
                      phone: _phoneController.text,
                    );
                  }
                },
                decoration: InputDecoration(hintText: l10n.phone),
                onChanged: (value) => _controller.clearError(),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _controller.isLoading
                    ? null
                    : () {
                        _controller.completeProfile(
                          context: context,
                          fullname: _fullnameController.text,
                          phone: _phoneController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
            ],
          );
        },
      ),
    );
  }
}
