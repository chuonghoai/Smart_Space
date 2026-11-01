package com.vn.smart_space.service.report;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.geo.Circle;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResult;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.RedisGeoCommands;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uber.h3core.H3Core;
import com.uber.h3core.util.LatLng;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.dto.response.report.ReportDensityCellDto;
import com.vn.smart_space.dto.response.report.ReportDensityResponse;
import com.vn.smart_space.dto.response.report.ReportDensityStatusResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.repository.ReportRepository;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class ReportDensityServiceImpl implements IReportDensityService {

    public static final int H3_RESOLUTION = 11;
    public static final int CACHE_VERSION = 1;
    public static final double HEXAGON_AREA_SCALE = 1.5;
    public static final double HEXAGON_RADIUS_SCALE = Math.sqrt(HEXAGON_AREA_SCALE);

    public static final String KEY_CELLS = "map:density:cells";
    public static final String KEY_GEO = "map:density:geo";
    public static final String KEY_META = "map:density:meta";
    public static final String KEY_LOCK = "lock:map:density:recalc";
    public static final String KEY_REPORT_PREFIX = "map:density:report:";

    private final ReportRepository reportRepository;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final H3Core h3;

    public ReportDensityServiceImpl(
            ReportRepository reportRepository,
            StringRedisTemplate redisTemplate,
            @Autowired(required = false) ObjectMapper objectMapper) {
        this.reportRepository = reportRepository;
        this.redisTemplate = redisTemplate;
        this.objectMapper = (objectMapper != null) ? objectMapper : new ObjectMapper();
        try {
            this.h3 = H3Core.newInstance();
            log.info("[ReportDensity] Uber H3 v4 initialized successfully with Resolution: {}", H3_RESOLUTION);
        } catch (Exception e) {
            log.error("[ReportDensity] Failed to initialize Uber H3 library", e);
            throw new RuntimeException("Could not initialize Uber H3", e);
        }
    }

    @Override
    public ReportDensityResponse getDensity(Double north, Double south, Double east, Double west, Double zoom) {
        // 1. Validate parameters
        if (north == null || south == null || east == null || west == null) {
            throw new BadRequestException("report.density.bounds_required");
        }
        if (south > north || south < -90.0 || north > 90.0) {
            throw new BadRequestException("report.density.invalid_latitude");
        }
        if (zoom == null || zoom < 0) {
            zoom = 14.0;
        }

        // 2. Ensure cache is ready (auto-heal / fallback if absent)
        ensureCacheReady();

        // 3. Determine zoom limits
        int maxLimit = getLimitForZoom(zoom);

        // 4. Query intersecting cells from Redis
        double centerLat = (north + south) / 2.0;
        double heightKm = Math.max(0.05, (north - south) * 111.32);

        // Handle antimeridian crossing if west > east
        List<String> cellIds = new ArrayList<>();
        if (west <= east) {
            double centerLng = (west + east) / 2.0;
            double widthKm = Math.max(0.05, (east - west) * 111.32 * Math.cos(Math.toRadians(centerLat)));
            double radiusKm = Math.hypot(widthKm, heightKm) / 2.0;
            cellIds.addAll(queryCellIdsInRadius(centerLng, centerLat, radiusKm, south, north, west, east, maxLimit));
        } else {
            // Split across antimeridian: [west, 180] and [-180, east]
            double centerLng1 = (west + 180.0) / 2.0;
            double widthKm1 = Math.max(0.05, (180.0 - west) * 111.32 * Math.cos(Math.toRadians(centerLat)));
            double radiusKm1 = Math.hypot(widthKm1, heightKm) / 2.0;
            cellIds.addAll(queryCellIdsInRadius(centerLng1, centerLat, radiusKm1, south, north, west, 180.0, maxLimit / 2));

            double centerLng2 = (-180.0 + east) / 2.0;
            double widthKm2 = Math.max(0.05, (east - (-180.0)) * 111.32 * Math.cos(Math.toRadians(centerLat)));
            double radiusKm2 = Math.hypot(widthKm2, heightKm) / 2.0;
            cellIds.addAll(queryCellIdsInRadius(centerLng2, centerLat, radiusKm2, south, north, -180.0, east, maxLimit / 2));
        }

        boolean truncated = cellIds.size() >= maxLimit;

        // 5. Fetch details from Hash
        List<ReportDensityCellDto> cellDtos = new ArrayList<>();
        if (!cellIds.isEmpty()) {
            List<Object> rawCells = redisTemplate.opsForHash().multiGet(KEY_CELLS, new ArrayList<>(cellIds));
            for (Object raw : rawCells) {
                if (raw != null) {
                    try {
                        ReportDensityCellDto dto = objectMapper.readValue(raw.toString(), ReportDensityCellDto.class);
                        cellDtos.add(dto);
                    } catch (Exception e) {
                        log.warn("[ReportDensity] Failed to deserialize cell JSON: {}", e.getMessage());
                    }
                }
            }
        }

        // 6. Build GeoJSON FeatureCollection
        Map<String, Object> geoJson = buildGeoJsonFeatureCollection(cellDtos);

        return ReportDensityResponse.builder()
                .resolution(H3_RESOLUTION)
                .zoom(zoom)
                .totalCells(cellDtos.size())
                .truncated(truncated)
                .cells(cellDtos)
                .geojson(geoJson)
                .build();
    }

    private int getLimitForZoom(double zoom) {
        if (zoom < 11.0) {
            return 100;
        } else if (zoom < 14.0) {
            return 500;
        } else {
            return 1000;
        }
    }

    private List<String> queryCellIdsInRadius(double centerLng, double centerLat, double radiusKm,
                                              double south, double north, double west, double east, int limit) {
        try {
            Circle circle = new Circle(new Point(centerLng, centerLat), new Distance(radiusKm, Metrics.KILOMETERS));
            RedisGeoCommands.GeoRadiusCommandArgs args = RedisGeoCommands.GeoRadiusCommandArgs.newGeoRadiusArgs()
                    .includeCoordinates()
                    .limit(limit);

            GeoResults<RedisGeoCommands.GeoLocation<String>> results = redisTemplate.opsForGeo().radius(KEY_GEO, circle, args);

            if (results == null) return Collections.emptyList();

            List<String> list = new ArrayList<>();
            for (GeoResult<RedisGeoCommands.GeoLocation<String>> res : results) {
                if (res != null && res.getContent() != null) {
                    Point pt = res.getContent().getPoint();
                    if (pt != null) {
                        double lng = pt.getX();
                        double lat = pt.getY();
                        // Strict bounding box check to exclude cells in circle but outside rectangle
                        if (lat >= south && lat <= north && lng >= west && lng <= east) {
                            list.add(res.getContent().getName());
                        }
                    } else {
                        list.add(res.getContent().getName());
                    }
                }
            }
            return list;
        } catch (Exception e) {
            log.warn("[ReportDensity] Error querying GEORADIUS from Redis: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private Map<String, Object> buildGeoJsonFeatureCollection(List<ReportDensityCellDto> cells) {
        List<Map<String, Object>> features = new ArrayList<>();
        for (ReportDensityCellDto cell : cells) {
            Map<String, Object> feature = new HashMap<>();
            feature.put("type", "Feature");

            Map<String, Object> properties = new HashMap<>();
            properties.put("cellId", cell.getCellId());
            properties.put("count", cell.getCount());
            properties.put("level", cell.getLevel());
            properties.put("color", cell.getColor());
            feature.put("properties", properties);

            Map<String, Object> geometry = new HashMap<>();
            geometry.put("type", "Polygon");

            // Convert [lat, lng] to GeoJSON standard [lng, lat] with closed linear ring
            List<List<Double>> ring = new ArrayList<>();
            if (cell.getCoordinates() != null && !cell.getCoordinates().isEmpty()) {
                for (List<Double> pt : cell.getCoordinates()) {
                    if (pt.size() >= 2) {
                        ring.add(List.of(pt.get(1), pt.get(0)));
                    }
                }
                // Close ring if not closed
                if (!ring.isEmpty() && !ring.get(0).equals(ring.get(ring.size() - 1))) {
                    ring.add(ring.get(0));
                }
            }

            geometry.put("coordinates", List.of(ring));
            feature.put("geometry", geometry);
            features.add(feature);
        }

        Map<String, Object> fc = new HashMap<>();
        fc.put("type", "FeatureCollection");
        fc.put("features", features);
        return fc;
    }

    @Override
    public synchronized ReportDensityStatusResponse triggerFullRecalculation(boolean async) {
        // Check lock
        String lockVal = UUID.randomUUID().toString();
        Boolean acquired = redisTemplate.opsForValue().setIfAbsent(KEY_LOCK, lockVal, Duration.ofMinutes(5));
        if (Boolean.FALSE.equals(acquired)) {
            ReportDensityStatusResponse currentStatus = getStatus();
            currentStatus.setMessage("Full recalculation is already in progress by another task");
            return currentStatus;
        }

        if (async) {
            CompletableFuture.runAsync(() -> {
                try {
                    doFullRecalculationInternal(lockVal);
                } catch (Exception e) {
                    log.error("[ReportDensity] Asynchronous full recalculation failed", e);
                }
            });
            return ReportDensityStatusResponse.builder()
                    .status("RUNNING")
                    .resolution(H3_RESOLUTION)
                    .message("Recalculation started asynchronously")
                    .lastCalculatedAt(Instant.now().toString())
                    .build();
        } else {
            try {
                return doFullRecalculationInternal(lockVal);
            } finally {
                releaseLock(lockVal);
            }
        }
    }

    private ReportDensityStatusResponse doFullRecalculationInternal(String lockVal) {
        long startTime = System.currentTimeMillis();
        String stagingId = UUID.randomUUID().toString();
        String stagingCellsKey = KEY_CELLS + ":staging:" + stagingId;
        String stagingGeoKey = KEY_GEO + ":staging:" + stagingId;

        try {
            log.info("[ReportDensity] Starting Full Recalculation (Staging ID: {})...", stagingId);

            // 1. Fetch all valid coordinates from DB
            List<Object[]> rawReports = reportRepository.findValidCoordinatesForDensity(EReportStatus.rejected);
            log.info("[ReportDensity] Fetched {} valid reports with coordinates from database", rawReports.size());

            // 2. Aggregate counts per H3 cell
            Map<String, Integer> cellCounts = new HashMap<>();
            for (Object[] row : rawReports) {
                if (row == null || row.length < 3) continue;
                String reportId = row[0] != null ? row[0].toString() : null;
                Double lat = row[1] != null ? (Double) row[1] : null;
                Double lng = row[2] != null ? (Double) row[2] : null;

                if (lat != null && lng != null) {
                    try {
                        String cellId = h3.latLngToCellAddress(lat, lng, H3_RESOLUTION);
                        cellCounts.put(cellId, cellCounts.getOrDefault(cellId, 0) + 1);

                        // Save report-to-cell mapping for idempotency
                        if (reportId != null) {
                            redisTemplate.opsForValue().set(KEY_REPORT_PREFIX + reportId, cellId, Duration.ofDays(30));
                        }
                    } catch (Exception e) {
                        log.warn("[ReportDensity] Failed to convert lat/lng ({}, {}) to H3: {}", lat, lng, e.getMessage());
                    }
                }
            }

            // 3. Write aggregated cells to staging keys
            int cellCount = 0;
            Map<String, String> stagingCells = new HashMap<>();
            for (Map.Entry<String, Integer> entry : cellCounts.entrySet()) {
                String cellId = entry.getKey();
                int count = entry.getValue();
                if (count <= 0) continue;

                ReportDensityCellDto dto = buildCellDto(cellId, count);
                stagingCells.put(cellId, objectMapper.writeValueAsString(dto));

                // Add to staging GEO set
                redisTemplate.opsForGeo().add(
                        stagingGeoKey,
                        new Point(dto.getLongitude(), dto.getLatitude()),
                        cellId);
                cellCount++;
            }

            if (!stagingCells.isEmpty()) {
                redisTemplate.opsForHash().putAll(stagingCellsKey, stagingCells);
            }

            // 4. Atomic switch using Redis RENAME
            if (redisTemplate.hasKey(stagingCellsKey)) {
                redisTemplate.rename(stagingCellsKey, KEY_CELLS);
            } else {
                redisTemplate.delete(KEY_CELLS);
            }

            if (redisTemplate.hasKey(stagingGeoKey)) {
                redisTemplate.rename(stagingGeoKey, KEY_GEO);
            } else {
                redisTemplate.delete(KEY_GEO);
            }

            // 5. Update metadata
            String nowStr = Instant.now().toString();
            Map<String, String> meta = Map.of(
                    "status", "READY",
                    "resolution", String.valueOf(H3_RESOLUTION),
                    "totalCells", String.valueOf(cellCount),
                    "totalReports", String.valueOf(rawReports.size()),
                    "version", String.valueOf(CACHE_VERSION),
                    "lastCalculatedAt", nowStr
            );
            redisTemplate.opsForHash().putAll(KEY_META, meta);

            long durationMs = System.currentTimeMillis() - startTime;
            log.info("[ReportDensity] Full Recalculation completed successfully in {} ms: {} cells, {} reports",
                    durationMs, cellCount, rawReports.size());

            return ReportDensityStatusResponse.builder()
                    .status("READY")
                    .resolution(H3_RESOLUTION)
                    .totalCells(cellCount)
                    .totalReports(rawReports.size())
                    .lastCalculatedAt(nowStr)
                    .message("Recalculation succeeded in " + durationMs + " ms")
                    .build();

        } catch (Exception e) {
            log.error("[ReportDensity] Full Recalculation failed: {}", e.getMessage(), e);
            // Clean up staging keys on error to preserve active cache
            try {
                redisTemplate.delete(stagingCellsKey);
                redisTemplate.delete(stagingGeoKey);
            } catch (Exception ignored) {
            }
            throw new RuntimeException("Recalculation failed: " + e.getMessage(), e);
        } finally {
            releaseLock(lockVal);
        }
    }

    private void releaseLock(String lockVal) {
        try {
            String current = redisTemplate.opsForValue().get(KEY_LOCK);
            if (lockVal.equals(current)) {
                redisTemplate.delete(KEY_LOCK);
            }
        } catch (Exception e) {
            log.warn("[ReportDensity] Failed to release lock: {}", e.getMessage());
        }
    }

    private ReportDensityCellDto buildCellDto(String cellId, int count) {
        String level = classifyLevel(count);
        String color = classifyColor(level);

        LatLng center = h3.cellToLatLng(cellId);
        List<LatLng> boundary = h3.cellToBoundary(cellId);

        List<List<Double>> coords = new ArrayList<>();
        for (LatLng pt : boundary) {
            // Scale vertices outward from centroid by sqrt(1.5) to increase polygon area by exactly 1.5x
            double scaledLat = center.lat + (pt.lat - center.lat) * HEXAGON_RADIUS_SCALE;
            double scaledLng = center.lng + (pt.lng - center.lng) * HEXAGON_RADIUS_SCALE;
            coords.add(List.of(scaledLat, scaledLng));
        }

        return ReportDensityCellDto.builder()
                .cellId(cellId)
                .count(count)
                .level(level)
                .color(color)
                .latitude(center.lat)
                .longitude(center.lng)
                .coordinates(coords)
                .build();
    }

    public static String classifyLevel(int count) {
        if (count <= 2) {
            return "LOW";
        } else if (count <= 5) {
            return "MEDIUM";
        } else {
            return "HIGH";
        }
    }

    public static String classifyColor(String level) {
        switch (level) {
            case "LOW":
                return "#22C55E";
            case "MEDIUM":
                return "#F59E0B";
            case "HIGH":
            default:
                return "#EF4444";
        }
    }

    @Override
    public ReportDensityStatusResponse getStatus() {
        try {
            Map<Object, Object> entries = redisTemplate.opsForHash().entries(KEY_META);
            if (entries.isEmpty()) {
                return ReportDensityStatusResponse.builder()
                        .status("NOT_INITIALIZED")
                        .resolution(H3_RESOLUTION)
                        .totalCells(0)
                        .totalReports(0)
                        .message("Cache not yet initialized")
                        .build();
            }

            String status = entries.getOrDefault("status", "READY").toString();
            int totalCells = Integer.parseInt(entries.getOrDefault("totalCells", "0").toString());
            long totalReports = Long.parseLong(entries.getOrDefault("totalReports", "0").toString());
            String lastCalculatedAt = entries.getOrDefault("lastCalculatedAt", "").toString();

            return ReportDensityStatusResponse.builder()
                    .status(status)
                    .resolution(H3_RESOLUTION)
                    .totalCells(totalCells)
                    .totalReports(totalReports)
                    .lastCalculatedAt(lastCalculatedAt)
                    .message("Current cache status: " + status)
                    .build();
        } catch (Exception e) {
            log.error("[ReportDensity] Failed to read status from Redis", e);
            return ReportDensityStatusResponse.builder()
                    .status("ERROR")
                    .resolution(H3_RESOLUTION)
                    .message(e.getMessage())
                    .build();
        }
    }

    @Override
    public void initializeCacheIfAbsent() {
        try {
            Boolean hasMeta = redisTemplate.hasKey(KEY_META);
            if (Boolean.TRUE.equals(hasMeta)) {
                Object status = redisTemplate.opsForHash().get(KEY_META, "status");
                Object version = redisTemplate.opsForHash().get(KEY_META, "version");
                if ("READY".equals(status) && String.valueOf(CACHE_VERSION).equals(version)) {
                    log.info("[ReportDensity] Cache is already initialized and valid (Status: READY, Version: {})", version);
                    return;
                }
            }

            log.info("[ReportDensity] Cache missing or invalid on startup. Triggering initial Full Recalculation...");
            triggerFullRecalculation(true);
        } catch (Exception e) {
            log.warn("[ReportDensity] Could not verify cache during startup: {}", e.getMessage());
        }
    }

    private void ensureCacheReady() {
        try {
            Boolean hasMeta = redisTemplate.hasKey(KEY_META);
            if (Boolean.TRUE.equals(hasMeta)) {
                Object status = redisTemplate.opsForHash().get(KEY_META, "status");
                if ("READY".equals(status)) {
                    return;
                }
            }

            log.warn("[ReportDensity] Cache not ready upon query request. Attempting synchronization...");
            // Acquire lock and recalculate if needed
            String lockVal = UUID.randomUUID().toString();
            Boolean acquired = redisTemplate.opsForValue().setIfAbsent(KEY_LOCK, lockVal, Duration.ofMinutes(5));
            if (Boolean.TRUE.equals(acquired)) {
                try {
                    doFullRecalculationInternal(lockVal);
                } finally {
                    releaseLock(lockVal);
                }
            } else {
                // Wait briefly for calculation to complete
                for (int i = 0; i < 6; i++) {
                    Thread.sleep(500);
                    Object status = redisTemplate.opsForHash().get(KEY_META, "status");
                    if ("READY".equals(status)) {
                        return;
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[ReportDensity] ensureCacheReady encountered error: {}", e.getMessage());
        }
    }

    @Override
    public void onReportCreated(String reportId, Double latitude, Double longitude) {
        if (latitude == null || longitude == null || reportId == null) return;
        try {
            String cellId = h3.latLngToCellAddress(latitude, longitude, H3_RESOLUTION);

            // Idempotency check: SETNX report key
            Boolean isNew = redisTemplate.opsForValue().setIfAbsent(KEY_REPORT_PREFIX + reportId, cellId, Duration.ofDays(30));
            if (Boolean.FALSE.equals(isNew)) {
                log.info("[ReportDensity] Report {} already processed for cell {}. Skipping duplicate increment.", reportId, cellId);
                return;
            }

            incrementCell(cellId);
            log.info("[ReportDensity] Incremented cell {} for new report {}", cellId, reportId);
        } catch (Exception e) {
            log.warn("[ReportDensity] Failed incremental update on create report {}: {}", reportId, e.getMessage());
        }
    }

    @Override
    public void onReportMoved(String reportId, Double oldLat, Double oldLng, Double newLat, Double newLng) {
        if (reportId == null || newLat == null || newLng == null) return;
        try {
            String newCellId = h3.latLngToCellAddress(newLat, newLng, H3_RESOLUTION);
            String oldCellId = redisTemplate.opsForValue().get(KEY_REPORT_PREFIX + reportId);

            if (oldCellId == null && oldLat != null && oldLng != null) {
                oldCellId = h3.latLngToCellAddress(oldLat, oldLng, H3_RESOLUTION);
            }

            if (newCellId.equals(oldCellId)) {
                return; // Same cell, no update needed
            }

            if (oldCellId != null) {
                decrementCell(oldCellId);
            }
            incrementCell(newCellId);
            redisTemplate.opsForValue().set(KEY_REPORT_PREFIX + reportId, newCellId, Duration.ofDays(30));
            log.info("[ReportDensity] Moved report {} from cell {} to cell {}", reportId, oldCellId, newCellId);
        } catch (Exception e) {
            log.warn("[ReportDensity] Failed incremental update on move report {}: {}", reportId, e.getMessage());
        }
    }

    @Override
    public void onReportRejected(String reportId, Double latitude, Double longitude) {
        if (reportId == null) return;
        try {
            String cellId = redisTemplate.opsForValue().get(KEY_REPORT_PREFIX + reportId);
            if (cellId == null && latitude != null && longitude != null) {
                cellId = h3.latLngToCellAddress(latitude, longitude, H3_RESOLUTION);
            }
            if (cellId != null) {
                decrementCell(cellId);
                redisTemplate.delete(KEY_REPORT_PREFIX + reportId);
                log.info("[ReportDensity] Decremented cell {} for rejected report {}", cellId, reportId);
            }
        } catch (Exception e) {
            log.warn("[ReportDensity] Failed incremental update on reject report {}: {}", reportId, e.getMessage());
        }
    }

    private synchronized void incrementCell(String cellId) {
        try {
            Object raw = redisTemplate.opsForHash().get(KEY_CELLS, cellId);
            ReportDensityCellDto dto;
            if (raw == null) {
                dto = buildCellDto(cellId, 1);
            } else {
                dto = objectMapper.readValue(raw.toString(), ReportDensityCellDto.class);
                dto.setCount(dto.getCount() + 1);
                dto.setLevel(classifyLevel(dto.getCount()));
                dto.setColor(classifyColor(dto.getLevel()));
            }

            redisTemplate.opsForHash().put(KEY_CELLS, cellId, objectMapper.writeValueAsString(dto));
            redisTemplate.opsForGeo().add(KEY_GEO, new Point(dto.getLongitude(), dto.getLatitude()), cellId);
        } catch (Exception e) {
            log.warn("[ReportDensity] Error in incrementCell: {}", e.getMessage());
        }
    }

    private synchronized void decrementCell(String cellId) {
        try {
            Object raw = redisTemplate.opsForHash().get(KEY_CELLS, cellId);
            if (raw == null) return;

            ReportDensityCellDto dto = objectMapper.readValue(raw.toString(), ReportDensityCellDto.class);
            int newCount = dto.getCount() - 1;
            if (newCount <= 0) {
                redisTemplate.opsForHash().delete(KEY_CELLS, cellId);
                redisTemplate.opsForZSet().remove(KEY_GEO, cellId);
            } else {
                dto.setCount(newCount);
                dto.setLevel(classifyLevel(newCount));
                dto.setColor(classifyColor(dto.getLevel()));
                redisTemplate.opsForHash().put(KEY_CELLS, cellId, objectMapper.writeValueAsString(dto));
            }
        } catch (Exception e) {
            log.warn("[ReportDensity] Error in decrementCell: {}", e.getMessage());
        }
    }
}
