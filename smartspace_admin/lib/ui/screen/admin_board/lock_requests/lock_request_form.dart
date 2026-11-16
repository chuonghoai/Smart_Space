import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/util/media_upload.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/features/users/models/user_detail_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/admin_board/lock_requests/lock_request_widgets.dart';
import 'package:smartspace_admin/ui/shared/image/person_avatar.dart';
import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';

const int _maxImageBytes = 5 * 1024 * 1024;

/// Mở form đề xuất khóa [user]. Khi gửi thành công: đóng form và hiện dialog xác nhận trên
/// navigator gốc (dialog / bottom sheet chi tiết người dùng phía dưới có thể đã được dựng lại).
Future<void> showLockRequestForm(BuildContext context, UserDetailModel user) async {
  final isWide = MediaQuery.sizeOf(context).width >= 640;
  if (isWide) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9),
          child: _LockRequestForm(user: user, isWide: true),
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.95,
      child: _LockRequestForm(user: user, isWide: false),
    ),
  );
}

/// Xác nhận đã gửi đề xuất. "Xem đề xuất" đóng mọi dialog / sheet đang mở rồi mở đúng đề xuất.
Future<void> _showLockProposalSentDialog(NavigatorState rootNavigator, String requestId) {
  return showDialog<void>(
    context: rootNavigator.context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        icon: Icon(Icons.how_to_vote_outlined, size: 36, color: AppSemanticColors.of(dialogContext).success),
        title: Text(l10n.lockProposalSentTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(l10n.lockProposalSentBody(kLockRequiredApprovals, kLockVotingHours)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.closeAction)),
          FilledButton(
            onPressed: () {
              final router = GoRouter.of(rootNavigator.context);
              // Đóng mọi dialog / bottom sheet (chi tiết người dùng, dialog này) rồi mở đúng đề xuất
              rootNavigator.popUntil((route) => route is! PopupRoute);
              router.push(RouterPath.adminBoardLockRequests(requestId));
            },
            child: Text(l10n.viewLockProposal),
          ),
        ],
      );
    },
  );
}

class _PickedImage {
  final Uint8List bytes;
  final String name;

  const _PickedImage(this.bytes, this.name);
}

class _LockRequestForm extends ConsumerStatefulWidget {
  final UserDetailModel user;
  final bool isWide;

  const _LockRequestForm({required this.user, required this.isWide});

  @override
  ConsumerState<_LockRequestForm> createState() => _LockRequestFormState();
}

class _LockRequestFormState extends ConsumerState<_LockRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final List<_PickedImage> _images = [];
  final Set<String> _reportIds = {};
  bool _isSubmitting = false;
  bool _showEvidenceError = false;
  String? _submitError;

  bool get _hasEvidence => _images.isNotEmpty || _reportIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _reasonCtrl.addListener(() => setState(() {})); // bộ đếm ký tự
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    final remaining = kLockMaxEvidenceImages - _images.length;
    if (remaining <= 0) return;

    final files = await ImagePicker().pickMultiImage(maxWidth: 1920, maxHeight: 1920, imageQuality: 85, limit: remaining);
    if (files.isEmpty) return;

    var tooLarge = false;
    final picked = <_PickedImage>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxImageBytes) {
        tooLarge = true;
        continue;
      }
      picked.add(_PickedImage(bytes, file.name));
    }
    if (!mounted) return;
    setState(() {
      _images.addAll(picked);
      _showEvidenceError = false;
      _submitError = tooLarge ? l10n.lockImageTooLarge : null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!_hasEvidence) setState(() => _showEvidenceError = true);
    if (!formValid || !_hasEvidence) return;

    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final actions = ref.read(accountLockActionsProvider);

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    LockCreateResult result;
    try {
      // Tải ảnh lên trước (Cloudinary) rồi gửi URL cho backend
      final urls = <String>[];
      for (final image in _images) {
        urls.add(await mediaUploadUtil.uploadMedia(image.bytes, image.name));
      }
      result = await actions.create(
        targetUserId: widget.user.id,
        reason: _reasonCtrl.text.trim(),
        evidenceImageUrls: urls,
        reportIds: _reportIds.toList(),
      );
    } catch (_) {
      result = (requestId: null, error: '');
    }
    if (!mounted) return;

    final requestId = result.requestId;
    if (requestId != null) {
      navigator.pop();
      await _showLockProposalSentDialog(rootNavigator, requestId);
      return;
    }
    // Lỗi hiện NGAY TRONG form (SnackBar sẽ bị dialog / bottom sheet che)
    setState(() {
      _isSubmitting = false;
      _submitError = (result.error?.isNotEmpty ?? false) ? result.error : l10n.lockActionFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fieldLabel = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
    final helper = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final user = widget.user;
    final name = user.fullName.isNotEmpty ? user.fullName : user.email;

    final submitButton = FilledButton(
      onPressed: _isSubmitting ? null : _submit,
      style: FilledButton.styleFrom(minimumSize: Size(widget.isWide ? 0 : double.infinity, 44)),
      child: _isSubmitting
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
          : Text(l10n.lockSubmitProposal),
    );
    final cancelButton = TextButton(
      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
      style: TextButton.styleFrom(minimumSize: Size(widget.isWide ? 0 : double.infinity, 44)),
      child: Text(l10n.cancel),
    );

    final body = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Người bị đề xuất
          Row(
            children: [
              PersonAvatar(avatarUrl: user.avatarUrl, name: name, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(user.email, style: helper),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lý do — nhãn ở trên, hướng dẫn + bộ đếm ở dưới
          Text('${l10n.lockReasonLabel} *', style: fieldLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reasonCtrl,
            enabled: !_isSubmitting,
            minLines: 4,
            maxLines: 8,
            maxLength: kLockMaxReasonLength,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              hintText: l10n.lockReasonHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (v) => (v?.trim().length ?? 0) < kLockMinReasonLength ? l10n.lockReasonTooShort : null,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(l10n.lockReasonHelper, style: helper)),
              Text(
                '${_reasonCtrl.text.trim().length}/$kLockMaxReasonLength',
                style: helper?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bằng chứng
          Row(
            children: [
              Expanded(child: Text('${l10n.lockEvidenceLabel} *', style: fieldLabel)),
              Text(
                '${_images.length}/$kLockMaxEvidenceImages',
                style: helper?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(l10n.lockEvidenceHelper, style: helper),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _images.length; i++)
                _ImagePreview(
                  bytes: _images[i].bytes,
                  tooltip: l10n.lockRemoveImage,
                  onRemove: _isSubmitting ? null : () => setState(() => _images.removeAt(i)),
                ),
              if (_images.length < kLockMaxEvidenceImages)
                SizedBox(
                  width: 96,
                  height: 96,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _pickImages,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 20),
                        const SizedBox(height: 4),
                        Text(l10n.lockAddImage, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.lockEvidenceReports, style: helper?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          if (user.recentReports.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(l10n.lockNoPublicReports, style: helper))
          else
            for (final report in user.recentReports)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _reportIds.contains(report.id),
                onChanged: _isSubmitting
                    ? null
                    : (checked) => setState(() {
                          checked == true ? _reportIds.add(report.id) : _reportIds.remove(report.id);
                          _showEvidenceError = false;
                        }),
                title: Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${reportStatusLabel(l10n, report.status)} · ${formatLockDate(report.createdAt)}',
                  style: helper?.copyWith(color: reportStatusColor(context, report.status)),
                ),
              ),
          if (_showEvidenceError) ...[
            const SizedBox(height: 6),
            Text(l10n.lockEvidenceRequired, style: theme.textTheme.bodySmall?.copyWith(color: cs.error)),
          ],
          const SizedBox(height: 20),

          // Hậu quả nói bằng lời, trước khi gửi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lockWhatHappensTitle, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(l10n.lockWhatHappensBody(kLockRequiredApprovals, kLockVotingHours), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 16),
            LockInlineError(message: _submitError!),
          ],
        ],
      ),
    );

    final header = Padding(
      padding: EdgeInsets.fromLTRB(24, widget.isWide ? 20 : 12, 12, 8),
      child: Column(
        children: [
          if (!widget.isWide)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
          Row(
            children: [
              Expanded(
                child: Text(l10n.proposeLockAction, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: l10n.closeAction,
                icon: const Icon(Icons.close),
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );

    // Nút ghim ở đáy: luôn thấy dù form dài; lỗi hiện ngay phía trên nút
    final footer = Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: widget.isWide
          ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [cancelButton, const SizedBox(width: 8), submitButton])
          : Column(mainAxisSize: MainAxisSize.min, children: [submitButton, const SizedBox(height: 4), cancelButton]),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: body)),
          SafeArea(top: false, child: footer),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List bytes;
  final String tooltip;
  final VoidCallback? onRemove;

  const _ImagePreview({required this.bytes, required this.tooltip, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 96, height: 96, fit: BoxFit.cover),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: cs.surface.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: tooltip,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: Icon(Icons.close, color: cs.onSurface),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unlock
// ─────────────────────────────────────────────────────────────────────────────

/// Mở khóa: một admin là đủ, bắt buộc lý do. Thao tác chạy trong dialog, lỗi hiện ngay trong dialog.
Future<void> showUnlockUserDialog(BuildContext context, UserDetailModel user) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final done = await showDialog<bool>(context: context, builder: (_) => _UnlockDialog(user: user));
  if (done == true) messenger.showSnackBar(SnackBar(content: Text(l10n.userUnlocked)));
}

class _UnlockDialog extends ConsumerStatefulWidget {
  final UserDetailModel user;

  const _UnlockDialog({required this.user});

  @override
  ConsumerState<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends ConsumerState<_UnlockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _error = null;
    });
    String? error;
    try {
      error = await ref.read(accountLockActionsProvider).unlockUser(widget.user.id, _reasonCtrl.text.trim());
    } catch (_) {
      error = '';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = error!.isNotEmpty ? error : l10n.lockActionFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.email;
    return AlertDialog(
      title: Text(l10n.unlockAccount),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                enabled: !_submitting,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                maxLength: kUnlockMaxReasonLength,
                decoration: InputDecoration(
                  hintText: l10n.unlockReasonHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v?.trim().length ?? 0) < kUnlockMinReasonLength ? l10n.unlockReasonTooShort : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                LockInlineError(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                )
              : Text(l10n.unlockAccount),
        ),
      ],
    );
  }
}
