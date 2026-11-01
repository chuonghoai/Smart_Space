package com.vn.smart_space.configuration;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.vn.smart_space.service.report.IReportDensityService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class ReportDensityCacheInitializer implements ApplicationRunner {

    private final IReportDensityService reportDensityService;

    @Override
    public void run(ApplicationArguments args) {
        log.info("[ReportDensityCacheInitializer] Checking map density cache validity on startup...");
        try {
            reportDensityService.initializeCacheIfAbsent();
        } catch (Exception e) {
            log.warn("[ReportDensityCacheInitializer] Failed to check/initialize density cache on startup: {}", e.getMessage());
        }
    }
}

