package com.vn.smart_space.service.report;

import static org.junit.jupiter.api.Assertions.*;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uber.h3core.H3Core;
import com.uber.h3core.util.LatLng;
import com.vn.smart_space.consts.EDensityTimeframe;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.repository.ReportRepository;

@ExtendWith(MockitoExtension.class)
class ReportDensityServiceTest {

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private StringRedisTemplate redisTemplate;

    private ObjectMapper objectMapper;
    private ReportDensityServiceImpl densityService;
    private H3Core h3;

    @BeforeEach
    void setUp() throws Exception {
        objectMapper = new ObjectMapper();
        h3 = H3Core.newInstance();
        densityService = new ReportDensityServiceImpl(reportRepository, redisTemplate, objectMapper);
    }

    @Test
    @DisplayName("H3 Resolution 11: Converts lat/lng to valid 15-char hex cell address")
    void testH3ConversionResolution11() {
        double lat = 10.7769;
        double lng = 106.7009;

        String cell = h3.latLngToCellAddress(lat, lng, ReportDensityServiceImpl.H3_RESOLUTION);

        assertNotNull(cell);
        assertEquals(15, cell.length());

        LatLng center = h3.cellToLatLng(cell);
        // Distance between cell center and point should be well under 50m
        double latDiff = Math.abs(center.lat - lat);
        double lngDiff = Math.abs(center.lng - lng);
        assertTrue(latDiff < 0.001);
        assertTrue(lngDiff < 0.001);

        List<LatLng> boundary = h3.cellToBoundary(cell);
        assertEquals(6, boundary.size(), "Hexagon cell must have 6 boundary vertices");
    }

    @Test
    @DisplayName("H3 Resolution 11: Points ~15m apart share same cell; points 200m apart have different cells")
    void testH3CellGrouping() {
        double lat1 = 10.776900;
        double lng1 = 106.700900;

        // ~11 meters offset (0.0001 deg lat is ~11.1 meters)
        double lat2 = 10.776990;
        double lng2 = 106.700910;

        // ~220 meters offset
        double latFar = 10.778900;
        double lngFar = 106.702900;

        String cell1 = h3.latLngToCellAddress(lat1, lng1, ReportDensityServiceImpl.H3_RESOLUTION);
        String cell2 = h3.latLngToCellAddress(lat2, lng2, ReportDensityServiceImpl.H3_RESOLUTION);
        String cellFar = h3.latLngToCellAddress(latFar, lngFar, ReportDensityServiceImpl.H3_RESOLUTION);

        assertEquals(cell1, cell2, "Points ~15m apart in the cell interior should share the same H3 resolution 11 cell");
        assertNotEquals(cell1, cellFar, "Points 200m apart must belong to different cells");
    }

    @Test
    @DisplayName("Classification: Correct level and color thresholds")
    void testDensityClassificationThresholds() {
        // 1-2: LOW (#22C55E)
        assertEquals("LOW", ReportDensityServiceImpl.classifyLevel(1));
        assertEquals("#22C55E", ReportDensityServiceImpl.classifyColor("LOW"));

        assertEquals("LOW", ReportDensityServiceImpl.classifyLevel(2));

        // 3-5: MEDIUM (#F59E0B)
        assertEquals("MEDIUM", ReportDensityServiceImpl.classifyLevel(3));
        assertEquals("#F59E0B", ReportDensityServiceImpl.classifyColor("MEDIUM"));

        assertEquals("MEDIUM", ReportDensityServiceImpl.classifyLevel(4));
        assertEquals("MEDIUM", ReportDensityServiceImpl.classifyLevel(5));

        // > 5: HIGH (#EF4444)
        assertEquals("HIGH", ReportDensityServiceImpl.classifyLevel(6));
        assertEquals("#EF4444", ReportDensityServiceImpl.classifyColor("HIGH"));

        assertEquals("HIGH", ReportDensityServiceImpl.classifyLevel(20));
    }

    @Test
    @DisplayName("Validation: Rejects missing or invalid bounds")
    void testValidationInvalidBounds() {
        // Null values
        assertThrows(BadRequestException.class, () -> densityService.getDensity(null, 10.0, 106.0, 105.0, 14.0));
        assertThrows(BadRequestException.class, () -> densityService.getDensity(11.0, null, 106.0, 105.0, 14.0));

        // South > North
        assertThrows(BadRequestException.class, () -> densityService.getDensity(10.0, 11.0, 106.0, 105.0, 14.0));

        // Out of latitude range
        assertThrows(BadRequestException.class, () -> densityService.getDensity(95.0, 10.0, 106.0, 105.0, 14.0));
        assertThrows(BadRequestException.class, () -> densityService.getDensity(10.0, -95.0, 106.0, 105.0, 14.0));
    }

    @Test
    @DisplayName("Geometry Scaling: Hexagon polygon area scaled by 1.5x (radius scale sqrt(1.5))")
    void testHexagonPolygonScaling() {
        assertEquals(1.5, ReportDensityServiceImpl.HEXAGON_AREA_SCALE, 0.0001);
        assertEquals(Math.sqrt(1.5), ReportDensityServiceImpl.HEXAGON_RADIUS_SCALE, 0.000001);
    }

    @Test
    @DisplayName("Timeframe: EDensityTimeframe mappings and cutoff dates")
    void testDensityTimeframeCutoffs() {
        assertEquals(EDensityTimeframe.ALL, EDensityTimeframe.fromCode("all"));
        assertEquals(EDensityTimeframe.ALL, EDensityTimeframe.fromCode(null));
        assertEquals(EDensityTimeframe.ALL, EDensityTimeframe.fromCode("invalid"));

        assertEquals(EDensityTimeframe.MONTH_1, EDensityTimeframe.fromCode("1m"));
        assertEquals(EDensityTimeframe.MONTH_3, EDensityTimeframe.fromCode("3m"));
        assertEquals(EDensityTimeframe.MONTH_6, EDensityTimeframe.fromCode("6m"));
        assertEquals(EDensityTimeframe.MONTH_9, EDensityTimeframe.fromCode("9m"));
        assertEquals(EDensityTimeframe.MONTH_12, EDensityTimeframe.fromCode("12m"));

        LocalDateTime now = LocalDateTime.of(2026, 11, 2, 0, 0);
        assertNull(EDensityTimeframe.ALL.getCutoff(now));
        assertEquals(now.minusMonths(1), EDensityTimeframe.MONTH_1.getCutoff(now));
        assertEquals(now.minusMonths(3), EDensityTimeframe.MONTH_3.getCutoff(now));
        assertEquals(now.minusMonths(6), EDensityTimeframe.MONTH_6.getCutoff(now));
        assertEquals(now.minusMonths(9), EDensityTimeframe.MONTH_9.getCutoff(now));
        assertEquals(now.minusMonths(12), EDensityTimeframe.MONTH_12.getCutoff(now));
    }

    @Test
    @DisplayName("Redis Keys: Format matches timeframe")
    void testRedisKeyFormatting() {
        assertEquals("map:density:cells", densityService.getKeyCells(EDensityTimeframe.ALL));
        assertEquals("map:density:geo", densityService.getKeyGeo(EDensityTimeframe.ALL));
        assertEquals("map:density:meta", densityService.getKeyMeta(EDensityTimeframe.ALL));

        assertEquals("map:density:1m:cells", densityService.getKeyCells(EDensityTimeframe.MONTH_1));
        assertEquals("map:density:1m:geo", densityService.getKeyGeo(EDensityTimeframe.MONTH_1));
        assertEquals("map:density:1m:meta", densityService.getKeyMeta(EDensityTimeframe.MONTH_1));

        assertEquals("map:density:12m:cells", densityService.getKeyCells(EDensityTimeframe.MONTH_12));
    }
}

