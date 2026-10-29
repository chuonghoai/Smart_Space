package com.vn.smart_space.controller.staff;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.wallet.CreateStaffBankAccountRequest;
import com.vn.smart_space.service.wallet.IStaffBankAccountService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({"/staff/bank-accounts", "/api/v1/staff/bank-accounts"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffBankAccountController {

    IStaffBankAccountService staffBankAccountService;

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @GetMapping
    public ResponseEntity<ApiResponse> getMyBankAccounts(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success", staffBankAccountService.getMyBankAccounts(userId)));
    }

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @PostMapping
    public ResponseEntity<ApiResponse> addBankAccount(
            @Valid @RequestBody CreateStaffBankAccountRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success", staffBankAccountService.addBankAccount(userId, request)));
    }

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> deleteBankAccount(
            @PathVariable String id,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        staffBankAccountService.deleteBankAccount(userId, id);
        return ResponseEntity.ok(ApiResponse.success("system.success", null));
    }
}

