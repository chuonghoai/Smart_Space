package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.request.wallet.CreateStaffBankAccountRequest;
import com.vn.smart_space.dto.response.wallet.StaffBankAccountResponse;

import java.util.List;

public interface IStaffBankAccountService {
    List<StaffBankAccountResponse> getMyBankAccounts(String userId);

    StaffBankAccountResponse addBankAccount(String userId, CreateStaffBankAccountRequest request);

    void deleteBankAccount(String userId, String id);
}

