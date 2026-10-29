package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.wallet.ProcessWithdrawalRequest;
import com.vn.smart_space.dto.response.wallet.StaffWalletSummaryResponse;
import com.vn.smart_space.dto.response.wallet.StaffWalletTransactionResponse;
import com.vn.smart_space.dto.response.wallet.StaffWithdrawalRequestResponse;

import java.util.Locale;

public interface IAdminWalletService {
    PageResponse<StaffWalletSummaryResponse> getStaffWallets(int page, int size, String search);

    StaffWalletSummaryResponse getStaffWalletDetail(String staffId);

    PageResponse<StaffWalletTransactionResponse> getStaffTransactions(String staffId, int page, int size, Locale locale);

    long getPendingWithdrawalCount();

    PageResponse<StaffWithdrawalRequestResponse> getWithdrawals(String status, int page, int size);

    StaffWithdrawalRequestResponse processWithdrawal(String id, ProcessWithdrawalRequest request, String adminId);
}

