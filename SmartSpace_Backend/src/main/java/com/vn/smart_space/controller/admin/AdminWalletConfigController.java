package com.vn.smart_space.controller.admin;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.wallet.WalletConfigUpdateRequest;
import com.vn.smart_space.service.wallet.IWalletConfigService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({"/admin/wallet/config", "/api/v1/admin/wallet/config"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminWalletConfigController {

    IWalletConfigService walletConfigService;

    @PreAuthorize("hasRole('admin')")
    @GetMapping
    public ResponseEntity<ApiResponse> getConfig() {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", walletConfigService.getConfig()));
    }

    @PreAuthorize("hasRole('admin')")
    @PutMapping
    public ResponseEntity<ApiResponse> updateConfig(@Valid @RequestBody WalletConfigUpdateRequest request) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", walletConfigService.updateConfig(request)));
    }
}

