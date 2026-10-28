package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.request.wallet.WalletConfigUpdateRequest;
import com.vn.smart_space.dto.response.wallet.WalletConfigResponse;
import com.vn.smart_space.model.WalletConfig;

public interface IWalletConfigService {
    WalletConfig getOrCreateDefaultConfig();
    WalletConfigResponse getConfig();
    WalletConfigResponse updateConfig(WalletConfigUpdateRequest request);
}

