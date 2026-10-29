package com.vn.smart_space.controller.admin;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.wallet.ProcessWithdrawalRequest;
import com.vn.smart_space.service.wallet.IAdminWalletService;
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
@RequestMapping({"/admin/wallet", "/api/v1/admin/wallet"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminStaffWalletController {

    IAdminWalletService adminWalletService;

    @PreAuthorize("hasRole('admin')")
    @GetMapping("/staffs")
    public ResponseEntity<ApiResponse> getStaffWallets(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", adminWalletService.getStaffWallets(page, size, search)));
    }

    @PreAuthorize("hasRole('admin')")
    @GetMapping("/staffs/{staffId}")
    public ResponseEntity<ApiResponse> getStaffWalletDetail(@PathVariable String staffId) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", adminWalletService.getStaffWalletDetail(staffId)));
    }

    @PreAuthorize("hasRole('admin')")
    @GetMapping("/staffs/{staffId}/transactions")
    public ResponseEntity<ApiResponse> getStaffTransactions(
            @PathVariable String staffId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Locale locale) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", adminWalletService.getStaffTransactions(staffId, page, size, locale)));
    }

    @PreAuthorize("hasRole('admin')")
    @GetMapping("/withdrawals/pending-count")
    public ResponseEntity<ApiResponse> getPendingWithdrawalCount() {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", adminWalletService.getPendingWithdrawalCount()));
    }

    @PreAuthorize("hasRole('admin')")
    @GetMapping("/withdrawals")
    public ResponseEntity<ApiResponse> getWithdrawals(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", adminWalletService.getWithdrawals(status, page, size)));
    }

    @PreAuthorize("hasRole('admin')")
    @PutMapping("/withdrawals/{id}/process")
    public ResponseEntity<ApiResponse> processWithdrawal(
            @PathVariable String id,
            @Valid @RequestBody ProcessWithdrawalRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("system.success", adminWalletService.processWithdrawal(id, request, adminId)));
    }
}

