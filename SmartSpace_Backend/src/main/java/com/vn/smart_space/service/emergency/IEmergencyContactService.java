package com.vn.smart_space.service.emergency;

import java.util.List;

import com.vn.smart_space.dto.request.emergency.EmergencyContactRequest;
import com.vn.smart_space.dto.request.emergency.ReorderEmergencyContactsRequest;
import com.vn.smart_space.dto.response.emergency.EmergencyContactResponse;
import com.vn.smart_space.dto.response.emergency.GuardianshipResponse;

public interface IEmergencyContactService {

    // Phía owner: quản lý danh sách khẩn cấp của mình

    List<EmergencyContactResponse> listMine(String ownerId);

    EmergencyContactResponse create(String ownerId, EmergencyContactRequest request);

    EmergencyContactResponse update(String ownerId, String contactId, EmergencyContactRequest request);

    void delete(String ownerId, String contactId);

    List<EmergencyContactResponse> reorder(String ownerId, ReorderEmergencyContactsRequest request);

    // Phía người được thêm (có tài khoản)

    List<GuardianshipResponse> listGuardianships(String userId);

    GuardianshipResponse acceptInvitation(String userId, String contactId);

    void rejectInvitation(String userId, String contactId);

    void revokeGuardianship(String userId, String contactId);
}
