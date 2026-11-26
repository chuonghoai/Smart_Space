package com.vn.smart_space.utils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

class PhoneNumberUtilsTest {

    @Test
    void normalizesCommonVietnameseMobileFormats() {
        assertEquals("84912345678", PhoneNumberUtils.normalizeVnMobile("0912345678"));
        assertEquals("84912345678", PhoneNumberUtils.normalizeVnMobile("+84912345678"));
        assertEquals("84912345678", PhoneNumberUtils.normalizeVnMobile("84912345678"));
        assertEquals("84912345678", PhoneNumberUtils.normalizeVnMobile("091 234-5678"));
        assertEquals("84312345678", PhoneNumberUtils.normalizeVnMobile("(031) 234.5678"));
    }

    @Test
    void rejectsLandlinesAndMalformedNumbers() {
        assertNull(PhoneNumberUtils.normalizeVnMobile(null));
        assertNull(PhoneNumberUtils.normalizeVnMobile(""));
        assertNull(PhoneNumberUtils.normalizeVnMobile("0212345678"));
        assertNull(PhoneNumberUtils.normalizeVnMobile("091234567"));
        assertNull(PhoneNumberUtils.normalizeVnMobile("09123456789"));
        assertNull(PhoneNumberUtils.normalizeVnMobile("09123abc78"));
    }

    @Test
    void formatsNormalizedNumberForDisplay() {
        assertEquals("0912345678", PhoneNumberUtils.toLocalFormat("84912345678"));
        assertNull(PhoneNumberUtils.toLocalFormat(null));
    }
}
