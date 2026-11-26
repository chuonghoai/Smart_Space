package com.vn.smart_space.service.sos;

import java.util.Map;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.sos.ResolveSosRequest;
import com.vn.smart_space.dto.request.sos.SosLocationRequest;
import com.vn.smart_space.dto.request.sos.StartSosRequest;
import com.vn.smart_space.dto.response.sos.SosAlertResponse;

public interface ISosService {

    // Cư dân

    /** Tạo SOS; nếu đang có SOS mở thì cập nhật vị trí và trả lại chính nó (không báo lại). */
    SosAlertResponse start(String userId, StartSosRequest request);

    /** SOS đang mở của người dùng, hoặc null. */
    SosAlertResponse getActive(String userId);

    SosAlertResponse updateLocation(String userId, String sosId, SosLocationRequest request);

    SosAlertResponse markSafe(String userId, String sosId);

    /** Người gửi hoặc liên hệ khẩn cấp có tài khoản đã đồng ý mới xem được. */
    SosAlertResponse getForViewer(String viewerId, String sosId);

    // Admin

    PageResponse<SosAlertResponse> list(String status, int page, int size);

    Map<String, Long> openCount();

    SosAlertResponse getDetail(String sosId);

    SosAlertResponse acknowledge(String adminId, String sosId);

    SosAlertResponse resolve(String adminId, String sosId, ResolveSosRequest request);
}
