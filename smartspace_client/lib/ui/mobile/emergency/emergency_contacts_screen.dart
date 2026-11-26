import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/models/guardianship_model.dart';
import 'package:smartspace_client/features/emergency/providers/emergency_contacts_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/emergency/emergency_contact_form_sheet.dart';
import 'package:smartspace_client/ui/mobile/emergency/emergency_contacts_controller.dart';
import 'package:smartspace_client/ui/mobile/emergency/widgets/emergency_contact_widgets.dart';

/// Tab mở sẵn khi điều hướng tới màn hình (vd. từ thông báo lời mời).
enum EmergencyContactsTab {
  mine,
  guardian;

  static EmergencyContactsTab fromQuery(String? value) =>
      value == 'guardian' ? EmergencyContactsTab.guardian : EmergencyContactsTab.mine;
}

class MobileEmergencyContactsScreen extends ConsumerStatefulWidget {
  final EmergencyContactsTab initialTab;

  const MobileEmergencyContactsScreen({super.key, this.initialTab = EmergencyContactsTab.mine});

  @override
  ConsumerState<MobileEmergencyContactsScreen> createState() =>
      _MobileEmergencyContactsScreenState();
}

class _MobileEmergencyContactsScreenState extends ConsumerState<MobileEmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: EmergencyContactsTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    // Đổi tab thì thoát chế độ sắp xếp và cập nhật nút trên AppBar
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _reordering = false);
    });
    Future.microtask(() async {
      final error = await ref.read(emergencyContactsControllerProvider.notifier).load();
      if (error != null && mounted && ref.read(emergencyContactsProvider).lastFetched != null) {
        final l10n = AppLocalizations.of(context)!;
        Toast.show(ToastType.error, error.isNotEmpty ? error : l10n.genericError);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(emergencyContactsProvider);
    final pending = data.pendingInvitationCount;
    final canReorder =
        _tabController.index == EmergencyContactsTab.mine.index && data.contacts.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyContacts),
        actions: [
          if (canReorder)
            TextButton(
              onPressed: () => setState(() => _reordering = !_reordering),
              child: Text(_reordering ? l10n.emergencyReorderDone : l10n.emergencyReorder),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.emergencyTabMine),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(l10n.emergencyTabGuardian, overflow: TextOverflow.ellipsis)),
                  if (pending > 0) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('$pending')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(context, data),
    );
  }

  Widget _buildBody(BuildContext context, EmergencyContactsState data) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = ref.read(emergencyContactsControllerProvider.notifier);

    if (data.isLoading && data.lastFetched == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.error != null && data.lastFetched == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.emergencyLoadFailed, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                data.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: controller.load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _MyContactsTab(reordering: _reordering),
        const _GuardianTab(),
      ],
    );
  }
}

/// Làm mới danh sách và hiện toast nếu mạng/server báo lỗi.
Future<void> _refreshWithToast(WidgetRef ref, AppLocalizations l10n) async {
  final error = await ref.read(emergencyContactsControllerProvider.notifier).load();
  if (error != null) {
    Toast.show(ToastType.error, error.isNotEmpty ? error : l10n.genericError);
  }
}

/// Hiện thông báo kết quả: thành công dùng câu L10n của client, lỗi dùng thông điệp server.
void _toastResult(AppLocalizations l10n, ApiResponse<dynamic> res, String successMessage) {
  if (res.success) {
    Toast.show(ToastType.success, successMessage);
  } else {
    Toast.show(ToastType.error, res.message.isNotEmpty ? res.message : l10n.genericError);
  }
}

/// Nhãn nhóm nhỏ, chữ thường theo câu.
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool first;

  const _SectionLabel(this.text, {this.first = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, first ? 16 : 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Dòng tiêu đề: tên đậm, phần phụ (quan hệ) nhạt, gói trong một dòng.
class _NameLine extends StatelessWidget {
  final String name;
  final String? secondary;

  const _NameLine({required this.name, this.secondary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        text: name,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        children: [
          if (secondary != null)
            TextSpan(
              text: ' · $secondary',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Tab "Của tôi"

class _MyContactsTab extends ConsumerWidget {
  final bool reordering;

  const _MyContactsTab({required this.reordering});

  Future<void> _openForm(BuildContext context, {EmergencyContactModel? editing}) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await showEmergencyContactFormSheet(context, contact: editing);
    if (saved == null || !context.mounted) return;

    final newInvite = saved.consentChannel == EEmergencyContactConsent.app &&
        saved.status == EEmergencyContactStatus.pending &&
        editing?.linkedUser?.id != saved.linkedUser?.id;
    if (newInvite) {
      Toast.show(ToastType.info, l10n.emergencyInviteSent(saved.linkedUser?.fullName ?? saved.name));
    } else {
      Toast.show(ToastType.success, l10n.emergencyContactSaved);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, EmergencyContactModel contact) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmEmergencyAction(
      context,
      title: l10n.emergencyDeleteTitle(contact.name),
      message: l10n.emergencyDeleteMessage(contact.name),
      confirmLabel: l10n.emergencyDelete,
    );
    if (!confirmed) return;
    final res = await ref.read(emergencyContactsControllerProvider.notifier).delete(contact.id);
    _toastResult(l10n, res, l10n.emergencyDeleted);
  }

  Future<void> _reorder(WidgetRef ref, AppLocalizations l10n, int oldIndex, int newIndex) async {
    final res = await ref.read(emergencyContactsControllerProvider.notifier).reorder(oldIndex, newIndex);
    if (!res.success) {
      Toast.show(ToastType.error, res.message.isNotEmpty ? res.message : l10n.genericError);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(emergencyContactsProvider);
    final ui = ref.watch(emergencyContactsControllerProvider);
    final contacts = data.contacts;
    Future<void> onRefresh() => _refreshWithToast(ref, l10n);

    final addButton = FilledButton.icon(
      onPressed: data.isFull ? null : () => _openForm(context),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(data.isFull ? Icons.check_rounded : Icons.person_add_alt_1_outlined),
      label: Text(data.isFull ? l10n.emergencyLimitShort : l10n.emergencyAddContact),
    );

    if (contacts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmergencyEmptyState(
              title: l10n.emergencyEmptyMineTitle,
              message: l10n.emergencyEmptyMine,
              action: addButton,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ReorderableListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: EmergencyCapacityMeter(count: contacts.length, max: kMaxEmergencyContacts),
              ),
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: contacts.length,
              // Dùng onReorder + chuẩn hóa newIndex để tương thích cả Flutter 3.41 và 3.47+.
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
                if (oldIndex == targetIndex) return;
                _reorder(ref, l10n, oldIndex, targetIndex);
              },
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Padding(
                  key: ValueKey(contact.id),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _ContactRow(
                    contact: contact,
                    index: index,
                    busy: ui.isBusy(contact.id),
                    reordering: reordering,
                    onEdit: () => _openForm(context, editing: contact),
                    onDelete: () => _delete(context, ref, contact),
                  ),
                );
              },
            ),
          ),
        ),
        if (!reordering)
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: addButton),
          ),
      ],
    );
  }
}

enum _ContactAction { edit, delete }

class _ContactRow extends StatelessWidget {
  final EmergencyContactModel contact;
  final int index;
  final bool busy;
  final bool reordering;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactRow({
    required this.contact,
    required this.index,
    required this.busy,
    required this.reordering,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final Widget trailing;
    if (reordering) {
      trailing = ReorderableDragStartListener(
        index: index,
        child: Semantics(
          label: l10n.emergencyDragHandle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.drag_handle_rounded, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    } else if (busy) {
      trailing = const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.callActionLabel,
            onPressed: () => callEmergencyPhone(context, contact.phone),
            icon: Icon(Icons.call_outlined, color: theme.colorScheme.primary),
          ),
          PopupMenuButton<_ContactAction>(
            tooltip: l10n.emergencyMoreActions,
            onSelected: (action) => action == _ContactAction.edit ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(value: _ContactAction.edit, child: Text(l10n.emergencyEdit)),
              PopupMenuItem(
                value: _ContactAction.delete,
                child: Text(l10n.emergencyDelete, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        ],
      );
    }

    return EmergencyTile(
      onTap: reordering || busy ? null : onEdit,
      child: Row(
        children: [
          EmergencyAvatar(name: contact.name, avatarUrl: contact.linkedUser?.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameLine(
                  name: contact.name,
                  secondary: emergencyRelationshipLabel(l10n, contact.relationship),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      contact.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    EmergencyChannelIcon(channel: contact.consentChannel),
                    if (contact.status != EEmergencyContactStatus.accepted) ...[
                      const SizedBox(width: 10),
                      Flexible(child: EmergencyStatusLabel(contact: contact)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// Tab "Tôi bảo hộ"

class _GuardianTab extends ConsumerWidget {
  const _GuardianTab();

  Future<void> _accept(BuildContext context, WidgetRef ref, GuardianshipModel g) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await ref.read(emergencyContactsControllerProvider.notifier).accept(g.id);
    _toastResult(l10n, res, l10n.emergencyAccepted(g.owner.fullName));
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, GuardianshipModel g) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await ref.read(emergencyContactsControllerProvider.notifier).reject(g.id);
    _toastResult(l10n, res, l10n.emergencyDeclined);
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, GuardianshipModel g) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmEmergencyAction(
      context,
      title: l10n.emergencyLeaveTitle(g.owner.fullName),
      message: l10n.emergencyLeaveMessage(g.owner.fullName),
      confirmLabel: l10n.emergencyLeave,
    );
    if (!confirmed) return;
    final res = await ref.read(emergencyContactsControllerProvider.notifier).leave(g.id);
    _toastResult(l10n, res, l10n.emergencyLeft);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(emergencyContactsProvider);
    final ui = ref.watch(emergencyContactsControllerProvider);
    final pending = data.guardianships.where((g) => g.isPending).toList();
    final accepted = data.guardianships.where((g) => !g.isPending).toList();

    return RefreshIndicator(
      onRefresh: () => _refreshWithToast(ref, l10n),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (data.guardianships.isEmpty)
            EmergencyEmptyState(
              title: l10n.emergencyEmptyGuardian,
              message: l10n.emergencyGuardianIntro,
            ),
          if (pending.isNotEmpty) _SectionLabel(l10n.emergencyInvitationsHeader, first: true),
          for (final g in pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _InvitationRow(
                guardianship: g,
                busy: ui.isBusy(g.id),
                onAccept: () => _accept(context, ref, g),
                onDecline: () => _decline(context, ref, g),
              ),
            ),
          if (accepted.isNotEmpty) _SectionLabel(l10n.emergencyGuardingHeader, first: pending.isEmpty),
          for (final g in accepted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _GuardingRow(
                guardianship: g,
                busy: ui.isBusy(g.id),
                onLeave: () => _leave(context, ref, g),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  final GuardianshipModel guardianship;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationRow({
    required this.guardianship,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final owner = guardianship.owner;

    return EmergencyTile(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                EmergencyAvatar(name: owner.fullName, avatarUrl: owner.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.emergencyInviteFrom(owner.fullName),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.emergencyListedAs(
                          emergencyRelationshipLabel(l10n, guardianship.relationship),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onDecline,
                  style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
                  child: Text(l10n.emergencyDecline),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: busy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.emergencyAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardingRow extends StatelessWidget {
  final GuardianshipModel guardianship;
  final bool busy;
  final VoidCallback onLeave;

  const _GuardingRow({required this.guardianship, required this.busy, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final owner = guardianship.owner;
    final phone = guardianship.ownerPhone;

    return EmergencyTile(
      child: Row(
        children: [
          EmergencyAvatar(name: owner.fullName, avatarUrl: owner.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameLine(name: owner.fullName),
                const SizedBox(height: 4),
                Text(
                  l10n.emergencyListedAs(emergencyRelationshipLabel(l10n, guardianship.relationship)),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              tooltip: l10n.callActionLabel,
              onPressed: () => callEmergencyPhone(context, phone),
              icon: Icon(Icons.call_outlined, color: theme.colorScheme.primary),
            ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            PopupMenuButton<int>(
              tooltip: l10n.emergencyMoreActions,
              onSelected: (_) => onLeave(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 0,
                  child: Text(l10n.emergencyLeave, style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
