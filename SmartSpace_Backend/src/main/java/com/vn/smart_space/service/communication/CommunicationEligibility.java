package com.vn.smart_space.service.communication;

public record CommunicationEligibility(
        boolean canMessage,
        boolean canVoiceCall,
        boolean isAnonymous,
        String reasonCode,
        long eligibleRehandlingReportCount
) {
    public static CommunicationEligibility allowed(boolean isAnonymous, long eligibleCount) {
        return new CommunicationEligibility(true, true, isAnonymous, null, eligibleCount);
    }

    public static CommunicationEligibility denied(String reasonCode) {
        return new CommunicationEligibility(false, false, false, reasonCode, 0);
    }
}
