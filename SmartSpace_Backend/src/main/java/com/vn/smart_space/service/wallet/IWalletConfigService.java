package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.request.wallet.DelegationRateConfigUpdateRequest;
import com.vn.smart_space.dto.request.wallet.WalletConfigUpdateRequest;
import com.vn.smart_space.dto.response.wallet.DelegationRateConfigResponse;
import com.vn.smart_space.dto.response.wallet.WalletConfigResponse;
import com.vn.smart_space.model.WalletConfig;

public interface IWalletConfigService {
    WalletConfig getOrCreateDefaultConfig();
    WalletConfigResponse getConfig();
    WalletConfigResponse updateConfig(WalletConfigUpdateRequest request);

    // Tỷ lệ bonus nhờ làm giùm — endpoint riêng để không phá PUT cấu hình ví hiện có
    DelegationRateConfigResponse getDelegationRates();
    DelegationRateConfigResponse updateDelegationRates(DelegationRateConfigUpdateRequest request);
}

