package com.vn.smart_space.service.call;

import com.vn.smart_space.dto.request.call.CallSignalRequest;
import com.vn.smart_space.dto.request.call.InitiateCallRequest;
import com.vn.smart_space.dto.response.call.CallPermissionResponse;
import com.vn.smart_space.dto.response.call.CallSessionResponse;
import com.vn.smart_space.dto.response.call.IceServerConfigResponse;

public interface ICallService {

    CallPermissionResponse checkCallPermission(
            String callerId,
            String receiverId,
            String conversationId,
            Boolean isAnonymous);

    IceServerConfigResponse getIceServers(String userId);

    CallSessionResponse initiateCall(String callerId, String callerDeviceId, InitiateCallRequest request);

    CallSessionResponse acknowledgeRinging(String receiverId, String deviceId, String callId);

    CallSessionResponse acceptCall(String receiverId, String deviceId, String callId);

    CallSessionResponse rejectCall(String receiverId, String callId, String reason);

    CallSessionResponse cancelCall(String callerId, String callId);

    CallSessionResponse markConnected(String userId, String callId);

    CallSessionResponse endCall(String userId, String callId, String reason);

    CallSessionResponse markFailed(String userId, String callId, String reason);

    CallSessionResponse getCallStatus(String userId, String callId);

    void relaySignal(String senderId, CallSignalRequest request);

    void expireStaleCalls();

    void handleUserWebSocketDisconnected(String userId, String sessionId, String deviceId);
}
