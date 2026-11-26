package com.vn.smart_space.service.sms;

public interface ISmsService {

    /**
     * Gửi một tin SMS. Nội dung phải khớp mẫu đã đăng ký với nhà cung cấp.
     *
     * @param phone số đã chuẩn hoá dạng 84xxxxxxxxx
     * @return true nếu nhà cung cấp nhận tin thành công
     */
    boolean send(String phone, String content);
}
