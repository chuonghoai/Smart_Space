import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/models/guardianship_model.dart';
import 'package:smartspace_client/features/emergency/services/emergency_contact_service.dart';

/// Giới hạn trùng với backend (EmergencyContactServiceImpl.MAX_CONTACTS).
const int kMaxEmergencyContacts = 5;

class EmergencyContactsState {
  final List<EmergencyContactModel> contacts;
  final List<GuardianshipModel> guardianships;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetched;

  const EmergencyContactsState({
    this.contacts = const [],
    this.guardianships = const [],
    this.isLoading = false,
    this.error,
    this.lastFetched,
  });

  bool get isFull => contacts.length >= kMaxEmergencyContacts;

  int get pendingInvitationCount => guardianships.where((g) => g.isPending).length;

  EmergencyContactsState copyWith({
    List<EmergencyContactModel>? contacts,
    List<GuardianshipModel>? guardianships,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
  }) {
    return EmergencyContactsState(
      contacts: contacts ?? this.contacts,
      guardianships: guardianships ?? this.guardianships,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

/// Danh sách khẩn cấp của tôi và các lời mời/quan hệ bảo hộ của người khác.
class EmergencyContactsNotifier extends StateNotifier<EmergencyContactsState> {
  final EmergencyContactService _service;

  EmergencyContactsNotifier(this._service) : super(const EmergencyContactsState());

  /// Trả về thông điệp lỗi nếu có API thất bại (để UI hiện toast khi pull-to-refresh).
  Future<String?> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    final results = await Future.wait([
      _service.getMyContacts(),
      _service.getGuardianships(),
    ]);
    if (!mounted) return null;

    final contactsRes = results[0] as ApiResponse<List<EmergencyContactModel>>;
    final guardianRes = results[1] as ApiResponse<List<GuardianshipModel>>;

    if (contactsRes.success && guardianRes.success) {
      state = state.copyWith(
        contacts: _sorted(contactsRes.data ?? const []),
        guardianships: guardianRes.data ?? const [],
        isLoading: false,
        lastFetched: DateTime.now(),
      );
      return null;
    }

    final errorMessage = contactsRes.success ? guardianRes.message : contactsRes.message;
    state = state.copyWith(
      contacts: contactsRes.success ? _sorted(contactsRes.data ?? const []) : null,
      guardianships: guardianRes.success ? (guardianRes.data ?? const []) : null,
      isLoading: false,
      error: errorMessage,
      lastFetched: (contactsRes.success || guardianRes.success) ? DateTime.now() : null,
    );
    return errorMessage;
  }

  Future<ApiResponse<EmergencyContactModel>> create(EmergencyContactDto dto) async {
    final res = await _service.createContact(dto);
    if (mounted && res.success && res.data != null) {
      state = state.copyWith(contacts: _sorted([...state.contacts, res.data!]));
    }
    return res;
  }

  Future<ApiResponse<EmergencyContactModel>> update(String id, EmergencyContactDto dto) async {
    final res = await _service.updateContact(id, dto);
    if (mounted && res.success && res.data != null) {
      _replaceContact(res.data!);
    }
    return res;
  }

  Future<ApiResponse<void>> delete(String id) async {
    final res = await _service.deleteContact(id);
    if (mounted && res.success) {
      state = state.copyWith(contacts: state.contacts.where((c) => c.id != id).toList());
    }
    return res;
  }

  /// [newIndex] là vị trí sau khi đã gỡ phần tử cũ. Cập nhật lạc quan, hoàn tác nếu server từ chối.
  Future<ApiResponse<List<EmergencyContactModel>>> reorder(int oldIndex, int newIndex) async {
    final previous = state.contacts;
    final next = List.of(previous);
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), moved);
    state = state.copyWith(contacts: next);

    final res = await _service.reorderContacts(next.map((c) => c.id).toList());
    if (!mounted) return res;
    if (res.success && res.data != null) {
      state = state.copyWith(contacts: _sorted(res.data!));
    } else {
      state = state.copyWith(contacts: previous);
    }
    return res;
  }

  Future<ApiResponse<GuardianshipModel>> acceptInvitation(String id) async {
    final res = await _service.acceptInvitation(id);
    if (mounted && res.success && res.data != null) {
      state = state.copyWith(
        guardianships: [
          for (final g in state.guardianships) g.id == id ? res.data! : g,
        ],
      );
    }
    return res;
  }

  Future<ApiResponse<void>> rejectInvitation(String id) async {
    final res = await _service.rejectInvitation(id);
    if (mounted && res.success) _removeGuardianship(id);
    return res;
  }

  Future<ApiResponse<void>> revokeGuardianship(String id) async {
    final res = await _service.revokeGuardianship(id);
    if (mounted && res.success) _removeGuardianship(id);
    return res;
  }

  void _replaceContact(EmergencyContactModel updated) {
    state = state.copyWith(
      contacts: [for (final c in state.contacts) c.id == updated.id ? updated : c],
    );
  }

  void _removeGuardianship(String id) {
    state = state.copyWith(
      guardianships: state.guardianships.where((g) => g.id != id).toList(),
    );
  }

  static List<EmergencyContactModel> _sorted(List<EmergencyContactModel> list) {
    return List.of(list)..sort((a, b) => a.priority.compareTo(b.priority));
  }
}

final emergencyContactsProvider =
    StateNotifierProvider.autoDispose<EmergencyContactsNotifier, EmergencyContactsState>(
  (ref) => EmergencyContactsNotifier(emergencyContactService),
);
