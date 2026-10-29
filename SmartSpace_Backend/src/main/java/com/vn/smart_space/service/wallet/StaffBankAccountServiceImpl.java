package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.request.wallet.CreateStaffBankAccountRequest;
import com.vn.smart_space.dto.response.wallet.StaffBankAccountResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.StaffBankAccount;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.StaffBankAccountRepository;
import com.vn.smart_space.repository.UserRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffBankAccountServiceImpl implements IStaffBankAccountService {

    StaffBankAccountRepository staffBankAccountRepository;
    UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public List<StaffBankAccountResponse> getMyBankAccounts(String userId) {
        List<StaffBankAccount> list = staffBankAccountRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return list.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public StaffBankAccountResponse addBankAccount(String userId, CreateStaffBankAccountRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));

        String cleanAccountNumber = request.getBankAccountNumber() != null ? request.getBankAccountNumber().trim() : "";
        if (cleanAccountNumber.isEmpty()) {
            throw new BadRequestException("wallet.withdraw.account_number.required");
        }

        // Check if account already exists for this staff
        var existing = staffBankAccountRepository.findByUserIdAndBankAccountNumber(userId, cleanAccountNumber);
        if (existing.isPresent()) {
            // Update info if existing
            StaffBankAccount acc = existing.get();
            acc.setBankName(request.getBankName().trim());
            acc.setBankAccountName(request.getBankAccountName().trim().toUpperCase());
            if (request.getBankCode() != null && !request.getBankCode().trim().isEmpty()) {
                acc.setBankCode(request.getBankCode().trim());
            }
            return mapToResponse(staffBankAccountRepository.save(acc));
        }

        StaffBankAccount newAccount = StaffBankAccount.builder()
                .user(user)
                .bankCode(request.getBankCode() != null ? request.getBankCode().trim() : "")
                .bankName(request.getBankName().trim())
                .bankAccountNumber(cleanAccountNumber)
                .bankAccountName(request.getBankAccountName().trim().toUpperCase())
                .build();

        return mapToResponse(staffBankAccountRepository.save(newAccount));
    }

    @Override
    @Transactional
    public void deleteBankAccount(String userId, String id) {
        StaffBankAccount account = staffBankAccountRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("bank_account.not_found"));

        if (!account.getUser().getId().equals(userId)) {
            throw new BadRequestException("bank_account.unauthorized");
        }

        staffBankAccountRepository.delete(account);
    }

    private StaffBankAccountResponse mapToResponse(StaffBankAccount entity) {
        return StaffBankAccountResponse.builder()
                .id(entity.getId())
                .userId(entity.getUser() != null ? entity.getUser().getId() : null)
                .bankCode(entity.getBankCode())
                .bankName(entity.getBankName())
                .bankAccountNumber(entity.getBankAccountNumber())
                .bankAccountName(entity.getBankAccountName())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}

