package com.vn.smart_space.controller.staff;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.wallet.CreateWithdrawalRequest;
import com.vn.smart_space.service.wallet.IStaffWalletService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Locale;

@RestController
@RequestMapping({"/staff/wallet", "/api/v1/staff/wallet"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffWalletController {

    IStaffWalletService staffWalletService;

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @GetMapping
    public ResponseEntity<ApiResponse> getWallet(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success", staffWalletService.getWalletResponse(userId)));
    }

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse> getTransactions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal Jwt jwt,
            Locale locale) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success",
                        staffWalletService.getTransactions(userId, page, size, locale)));
    }

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @PostMapping("/withdraw")
    public ResponseEntity<ApiResponse> createWithdrawal(
            @Valid @RequestBody CreateWithdrawalRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success", staffWalletService.createWithdrawalRequest(userId, request)));
    }

    @PreAuthorize("hasAnyRole('staff', 'admin')")
    @GetMapping("/withdrawals")
    public ResponseEntity<ApiResponse> getMyWithdrawals(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success", staffWalletService.getMyWithdrawals(userId)));
    }
}
