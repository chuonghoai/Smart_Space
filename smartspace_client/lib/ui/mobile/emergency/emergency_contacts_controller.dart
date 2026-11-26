import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/providers/emergency_contacts_provider.dart';

/// Số di động Việt Nam, khớp PhoneNumberUtils.VN_MOBILE_REGEX ở backend.
final RegExp kVnMobileRegex = RegExp(r'^(\+?84|0)[35789]\d{8}$');

bool isValidVnMobile(String raw) =>
    kVnMobileRegex.hasMatch(raw.replaceAll(RegExp(r'[\s.\-()]'), ''));

// Danh sách: theo dõi các dòng đang xử lý để khoá thao tác trùng

class EmergencyContactsUiState {
  final Set<String> busyIds;

  const EmergencyContactsUiState({this.busyIds = const {}});

  bool isBusy(String id) => busyIds.contains(id);
}

class EmergencyContactsController extends StateNotifier<EmergencyContactsUiState> {
  final Ref _ref;

  EmergencyContactsController(this._ref) : super(const EmergencyContactsUiState());

  EmergencyContactsNotifier get _data => _ref.read(emergencyContactsProvider.notifier);

  Future<String?> load() => _data.fetchAll();

  Future<ApiResponse<void>> delete(String id) => _run(id, () => _data.delete(id));

  Future<ApiResponse<void>> accept(String id) => _run(id, () => _data.acceptInvitation(id));

  Future<ApiResponse<void>> reject(String id) => _run(id, () => _data.rejectInvitation(id));

  Future<ApiResponse<void>> leave(String id) => _run(id, () => _data.revokeGuardianship(id));

  Future<ApiResponse<void>> reorder(int oldIndex, int newIndex) =>
      _data.reorder(oldIndex, newIndex);

  Future<ApiResponse<T>> _run<T>(String id, Future<ApiResponse<T>> Function() action) async {
    state = EmergencyContactsUiState(busyIds: {...state.busyIds, id});
    try {
      return await action();
    } finally {
      if (mounted) {
        state = EmergencyContactsUiState(busyIds: {...state.busyIds}..remove(id));
      }
    }
  }
}

final emergencyContactsControllerProvider = StateNotifierProvider.autoDispose<
    EmergencyContactsController, EmergencyContactsUiState>(
  (ref) => EmergencyContactsController(ref),
);

// Form thêm / sửa

class EmergencyContactFormState {
  final bool isSubmitting;
  final String? error;

  const EmergencyContactFormState({this.isSubmitting = false, this.error});
}

class EmergencyContactFormController extends StateNotifier<EmergencyContactFormState> {
  final Ref _ref;

  EmergencyContactFormController(this._ref) : super(const EmergencyContactFormState());

  /// Trả về liên hệ đã lưu, hoặc null kèm [EmergencyContactFormState.error].
  Future<EmergencyContactModel?> submit(EmergencyContactDto dto, {String? editingId}) async {
    if (state.isSubmitting) return null;
    state = const EmergencyContactFormState(isSubmitting: true);

    final notifier = _ref.read(emergencyContactsProvider.notifier);
    final res = editingId == null
        ? await notifier.create(dto)
        : await notifier.update(editingId, dto);
    if (!mounted) return res.data;

    if (res.success && res.data != null) {
      state = const EmergencyContactFormState();
      return res.data;
    }
    state = EmergencyContactFormState(error: res.message);
    return null;
  }
}

final emergencyContactFormControllerProvider = StateNotifierProvider.autoDispose<
    EmergencyContactFormController, EmergencyContactFormState>(
  (ref) => EmergencyContactFormController(ref),
);
