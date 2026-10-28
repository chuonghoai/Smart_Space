package com.vn.smart_space.service.wallet;

import com.vn.smart_space.dto.request.wallet.WalletConfigUpdateRequest;
import com.vn.smart_space.dto.response.wallet.WalletConfigResponse;
import com.vn.smart_space.model.WalletConfig;
import com.vn.smart_space.repository.WalletConfigRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class WalletConfigServiceImpl implements IWalletConfigService {

    WalletConfigRepository walletConfigRepository;

    @Override
    @Transactional
    public WalletConfig getOrCreateDefaultConfig() {
        return walletConfigRepository.findAll().stream().findFirst().orElseGet(() -> {
            WalletConfig config = WalletConfig.builder()
                    .commissionLow(2000.0)
                    .commissionMedium(5000.0)
                    .commissionHigh(7000.0)
                    .commissionCritical(10000.0)
                    .penaltyRate1(20.0)
                    .penaltyRate2(20.0)
                    .penaltyRate3(60.0)
                    .build();
            return walletConfigRepository.save(config);
        });
    }

    @Override
    public WalletConfigResponse getConfig() {
        WalletConfig config = getOrCreateDefaultConfig();
        return mapToResponse(config);
    }

    @Override
    @Transactional
    public WalletConfigResponse updateConfig(WalletConfigUpdateRequest request) {
        WalletConfig config = getOrCreateDefaultConfig();
        config.setCommissionLow(request.getCommissionLow());
        config.setCommissionMedium(request.getCommissionMedium());
        config.setCommissionHigh(request.getCommissionHigh());
        config.setCommissionCritical(request.getCommissionCritical());
        config.setPenaltyRate1(request.getPenaltyRate1());
        config.setPenaltyRate2(request.getPenaltyRate2());
        config.setPenaltyRate3(request.getPenaltyRate3());

        WalletConfig saved = walletConfigRepository.save(config);
        return mapToResponse(saved);
    }

    private WalletConfigResponse mapToResponse(WalletConfig config) {
        return WalletConfigResponse.builder()
                .commissionLow(config.getCommissionLow())
                .commissionMedium(config.getCommissionMedium())
                .commissionHigh(config.getCommissionHigh())
                .commissionCritical(config.getCommissionCritical())
                .penaltyRate1(config.getPenaltyRate1())
                .penaltyRate2(config.getPenaltyRate2())
                .penaltyRate3(config.getPenaltyRate3())
                .build();
    }
}

