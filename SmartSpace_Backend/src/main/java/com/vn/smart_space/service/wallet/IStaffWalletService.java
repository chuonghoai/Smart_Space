package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.wallet.StaffWalletResponse;
import com.vn.smart_space.dto.response.wallet.StaffWalletTransactionResponse;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.StaffWallet;

import java.util.Locale;

public interface IStaffWalletService {
    StaffWallet getOrCreateWallet(String userId);
    StaffWalletResponse getWalletResponse(String userId);
    PageResponse<StaffWalletTransactionResponse> getTransactions(String userId, int page, int size, Locale locale);
    void processReportCompletedCommission(Report report);
    void processReportReopenPenalty(Report report);
    java.util.List<com.vn.smart_space.dto.response.report.ReportDetailResponse.PenaltyDeductionItem> getPenaltyDeductionsForReport(Report report);
}

