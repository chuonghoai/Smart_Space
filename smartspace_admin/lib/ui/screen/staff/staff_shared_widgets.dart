import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/util/media_upload.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_list_response.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Summary card — hiển thị 1 KPI (icon + value + label)
class StaffSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StaffSummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Card nhân viên — hiển thị avatar, tên, email, trạng thái
class StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onTap;

  const StaffCard({super.key, required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: staff.isBlocked ? 0.6 : 1.0,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                StaffAvatar(staff: staff, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (staff.phoneNumber != null &&
                          staff.phoneNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          staff.phoneNumber!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                      if (staff.processingCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${staff.processingCount} ${AppLocalizations.of(context)!.processingStatus.toLowerCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StaffStatusChip(isActive: staff.isActive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar nhân viên — hiển thị ảnh hoặc chữ cái đầu
class StaffAvatar extends StatelessWidget {
  final StaffModel staff;
  final double radius;
  const StaffAvatar({super.key, required this.staff, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      backgroundImage: staff.avatarUrl != null
          ? NetworkImage(staff.avatarUrl!)
          : null,
      child: staff.avatarUrl == null
          ? Text(
              staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
    );
  }
}

/// Chip trạng thái — "Hoạt động" (xanh) hoặc "Đã khoá" (đỏ)
class StaffStatusChip extends StatelessWidget {
  final bool isActive;
  const StaffStatusChip({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final successColor = theme.brightness == Brightness.light
        ? const Color(0xFF2E7D32)
        : const Color(0xFF66BB6A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? successColor.withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? l10n.activeStatus : l10n.blockedStatus,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? successColor : theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Nút phân trang — Previous / 1 2 3 / Next
class StaffPaginationControls extends ConsumerWidget {
  final StaffListResponse data;
  const StaffPaginationControls({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (data.totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: data.currentPage > 1
              ? () => ref.read(staffListProvider.notifier).previousPage()
              : null,
        ),
        const SizedBox(width: 8),
        ...List.generate(data.totalPages, (i) {
          final page = i + 1;
          final isCurrent = page == data.currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: isCurrent ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: isCurrent
                    ? null
                    : () => ref.read(staffListProvider.notifier).goToPage(page),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Text(
                    '$page',
                    style: TextStyle(
                      color: isCurrent
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: data.currentPage < data.totalPages
              ? () => ref.read(staffListProvider.notifier).nextPage()
              : null,
        ),
      ],
    );
  }
}

/// Row chi tiết — icon + text (dùng trong detail panel)
class StaffDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const StaffDetailRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Dialog thêm/chỉnh sửa nhân viên — Web (2 cột) và Mobile (1 cột bottom sheet)
void showStaffFormDialog(
  BuildContext context,
  AppLocalizations l10n,
  ThemeData theme,
  WidgetRef ref, {
  StaffModel? editingStaff,
}) {
  final isWeb = MediaQuery.sizeOf(context).width >= 640;

  if (isWeb) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 560,
          child: _StaffForm(l10n: l10n, isWeb: true, ref: ref, editingStaff: editingStaff),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => _StaffForm(
          l10n: l10n,
          isWeb: false,
          ref: ref,
          editingStaff: editingStaff,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Form thêm/chỉnh sửa nhân viên — StatefulWidget dùng chung cho Web và Mobile
class _StaffForm extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isWeb;
  final WidgetRef ref;
  final StaffModel? editingStaff;
  final ScrollController? scrollController;

  const _StaffForm({
    required this.l10n,
    required this.isWeb,
    required this.ref,
    this.editingStaff,
    this.scrollController,
  });

  bool get isEditMode => editingStaff != null;

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _obscurePass = true;

  bool _isLoading = false;

  // Avatar state
  Uint8List? _avatarBytes;
  String? _avatarFileName;
  String? _existingAvatarUrl;

  @override
  void initState() {
    super.initState();
    final staff = widget.editingStaff;
    if (staff != null) {
      _nameCtrl.text = staff.fullName;
      _emailCtrl.text = staff.email;
      _phoneCtrl.text = staff.phoneNumber ?? '';
      _existingAvatarUrl = staff.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder get _inputBorder =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(8));

  /// Mở date picker
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: widget.l10n.selectDate,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Chọn ảnh avatar
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    // Kiểm tra dung lượng (5MB)
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.avatarSizeError)),
      );
      return;
    }

    setState(() {
      _avatarBytes = bytes;
      _avatarFileName = pickedFile.name;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Upload avatar nếu có ảnh mới
      String? avatarUrl = _existingAvatarUrl;
      if (_avatarBytes != null && _avatarFileName != null) {
        avatarUrl = await mediaUploadUtil.uploadMedia(
          _avatarBytes!,
          _avatarFileName!,
        );
      }

      final dateStr = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;

      bool success;
      if (widget.isEditMode) {
        success = await widget.ref.read(staffListProvider.notifier).updateStaff(
          staffId: widget.editingStaff!.id,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          dateOfBirth: dateStr,
          gender: _selectedGender,
          avatarUrl: avatarUrl,
        );
      } else {
        success = await widget.ref.read(staffListProvider.notifier).createStaff(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim(),
          dateOfBirth: dateStr,
          gender: _selectedGender,
          avatarUrl: avatarUrl,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditMode
              ? widget.l10n.updateStaffSuccess
              : widget.l10n.addStaffSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditMode
              ? widget.l10n.updateStaffFailed
              : widget.l10n.addStaffFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditMode
            ? widget.l10n.updateStaffFailed
            : widget.l10n.addStaffFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;

    final content = SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle (mobile only)
            if (!widget.isWeb) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],

            // ── Header
            Text(
              widget.isEditMode ? l10n.editStaff : l10n.addNewStaff,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // ── Avatar upload area
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!) as ImageProvider
                          : (_existingAvatarUrl != null
                              ? NetworkImage(_existingAvatarUrl!)
                              : null),
                      child: (_avatarBytes != null || _existingAvatarUrl != null)
                          ? null
                          : Icon(
                              Icons.person,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          (_avatarBytes != null || _existingAvatarUrl != null)
                              ? Icons.edit
                              : Icons.camera_alt,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                (_avatarBytes != null || _existingAvatarUrl != null)
                    ? l10n.changeAvatar
                    : l10n.uploadAvatar,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Fields
            if (widget.isWeb)
              _buildWebFields(theme, l10n)
            else
              _buildMobileFields(theme, l10n),

            const SizedBox(height: 24),

            // ── Actions
            if (widget.isWeb)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isEditMode ? l10n.updateStaff : l10n.createStaff),
                  ),
                ],
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isEditMode ? l10n.updateStaff : l10n.createStaff),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return widget.isWeb
        ? content
        : Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: content,
          );
  }

  /// Web: layout 2 cột
  Widget _buildWebFields(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        // Row 1: Họ tên + Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildNameField(l10n)),
            const SizedBox(width: 16),
            Expanded(child: _buildEmailField(l10n)),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: SĐT + Ngày sinh
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPhoneField(l10n)),
            const SizedBox(width: 16),
            Expanded(child: _buildDateField(theme, l10n)),
          ],
        ),
        const SizedBox(height: 16),
        // Row 3: Giới tính + Mật khẩu (chỉ hiển khi thêm mới)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGenderField(l10n)),
            const SizedBox(width: 16),
            if (!widget.isEditMode)
              Expanded(child: _buildPasswordField(l10n))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  /// Mobile: layout 1 cột
  Widget _buildMobileFields(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        _buildNameField(l10n),
        const SizedBox(height: 12),
        _buildEmailField(l10n),
        const SizedBox(height: 12),
        _buildPhoneField(l10n),
        const SizedBox(height: 12),
        _buildDateField(theme, l10n),
        const SizedBox(height: 12),
        _buildGenderField(l10n),
        if (!widget.isEditMode) ...[
          const SizedBox(height: 12),
          _buildPasswordField(l10n),
        ],
      ],
    );
  }

  Widget _buildNameField(AppLocalizations l10n) => TextFormField(
    controller: _nameCtrl,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: '${l10n.fullname} *',
      prefixIcon: const Icon(Icons.person_outline),
      border: _inputBorder,
    ),
    validator: (v) =>
        (v == null || v.trim().isEmpty) ? l10n.fullnameRequired : null,
  );

  Widget _buildEmailField(AppLocalizations l10n) => TextFormField(
    controller: _emailCtrl,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: '${l10n.email} *',
      prefixIcon: const Icon(Icons.email_outlined),
      border: _inputBorder,
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return l10n.emailRequired;
      if (!v.contains('@')) return l10n.invalidEmail;
      return null;
    },
  );

  Widget _buildPhoneField(AppLocalizations l10n) => TextFormField(
    controller: _phoneCtrl,
    keyboardType: TextInputType.phone,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: l10n.phone,
      prefixIcon: const Icon(Icons.phone_outlined),
      border: _inputBorder,
    ),
  );

  Widget _buildDateField(ThemeData theme, AppLocalizations l10n) =>
      TextFormField(
        readOnly: true,
        onTap: _pickDate,
        initialValue: _selectedDate != null ? _formatDate(_selectedDate!) : '',
        key: ValueKey(_selectedDate),
        decoration: InputDecoration(
          labelText: l10n.dateOfBirth,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          hintText: 'dd/mm/yyyy',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          border: _inputBorder,
        ),
      );

  Widget _buildGenderField(AppLocalizations l10n) =>
      DropdownButtonFormField<String>(
        value: _selectedGender,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.gender,
          prefixIcon: const Icon(Icons.wc_outlined),
          border: _inputBorder,
        ),
        hint: Text(l10n.selectGender),
        items: [
          DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
          DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
          DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
        ],
        onChanged: (v) => setState(() => _selectedGender = v),
      );

  Widget _buildPasswordField(AppLocalizations l10n) => TextFormField(
    controller: _passCtrl,
    obscureText: _obscurePass,
    textInputAction: TextInputAction.done,
    onFieldSubmitted: (_) => _submit(),
    decoration: InputDecoration(
      labelText: '${l10n.password} *',
      prefixIcon: const Icon(Icons.lock_outline),
      border: _inputBorder,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePass
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscurePass = !_obscurePass),
      ),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return l10n.passwordRequired;
      if (v.length < 6) return l10n.passwordReqLength;
      return null;
    },
  );
}

/// Bottom Sheet chi tiết nhân viên
void showStaffDetailSheet(
  BuildContext context,
  AppLocalizations l10n,
  ThemeData theme,
  StaffModel staff,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (sheetContext, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            StaffAvatar(staff: staff, radius: 36),
            const SizedBox(height: 12),
            Text(
              staff.fullName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            StaffStatusChip(isActive: staff.isActive),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            StaffDetailRow(icon: Icons.email_outlined, text: staff.email),
            const SizedBox(height: 12),
            StaffDetailRow(
              icon: Icons.phone_outlined,
              text: staff.phoneNumber ?? '—',
            ),
            if (staff.processingCount > 0) ...[
              const SizedBox(height: 12),
              StaffDetailRow(
                icon: Icons.assignment_outlined,
                text: l10n.processingReports(staff.processingCount.toInt()),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                // Nút Chỉnh sửa
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Đóng bottom sheet
                      showStaffFormDialog(context, l10n, theme, ref,
                          editingStaff: staff);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.editInfo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nút Khoá/Mở khoá
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Đóng bottom sheet
                      confirmToggleStaffStatus(context, l10n, theme, staff, ref);
                    },
                    icon: Icon(
                      staff.isActive ? Icons.lock_outline : Icons.lock_open,
                    ),
                    label: Text(
                      staff.isActive ? l10n.lockAccount : l10n.unlockAccount,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: staff.isActive
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      side: BorderSide(
                        color: staff.isActive
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Dialog xác nhận khoá/mở khoá tài khoản
void confirmToggleStaffStatus(
  BuildContext parentContext,
  AppLocalizations l10n,
  ThemeData theme,
  StaffModel staff,
  WidgetRef ref,
) {
  showDialog(
    context: parentContext,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(staff.isActive ? l10n.lockAccount : l10n.unlockAccount),
      content: Text(
        staff.isActive ? l10n.lockAccountConfirm : l10n.unlockAccountConfirm,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext); // Đóng dialog
            final success = await ref
                .read(staffListProvider.notifier)
                .toggleStaffStatus(staff.id, staff.isActive);
            if (parentContext.mounted) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.updateStatusSuccess
                        : l10n.updateStatusFailed,
                  ),
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: staff.isActive
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
}
