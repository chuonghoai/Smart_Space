package com.vn.smart_space.service.sms;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class EsmsSmsServiceTest {

    @Test
    void stripsVietnameseMarksForNonUnicodeSms() {
        assertEquals("Nguyen Van Duc muon them ban. Ma xac nhan: 123456",
                EsmsSmsService.stripVietnameseMarks("Nguyễn Văn Đức muốn thêm bạn. Mã xác nhận: 123456"));
        assertEquals("", EsmsSmsService.stripVietnameseMarks(null));
    }

    @Test
    void disabledModeDoesNotCallProvider() {
        EsmsSmsService service = new EsmsSmsService(false, "http://127.0.0.1:1", "", "", "", "2", true, false, 1000);
        assertTrue(service.send("84912345678", "SmartSpace: test"));
    }
}
