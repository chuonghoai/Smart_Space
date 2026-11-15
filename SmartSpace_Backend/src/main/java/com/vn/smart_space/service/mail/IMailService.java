package com.vn.smart_space.service.mail;

public interface IMailService {

    void sendOtpEmail(String toEmail, String otp);

    /**
     * Gửi email HTML chào mừng kèm thông tin đăng nhập cho nhân viên mới.
     *
     * @param positionName tên chức vụ, null/rỗng → không hiển thị
     * @param language     "vi" | "en" (mặc định vi)
     */
    void sendStaffCredentialsEmail(String toEmail, String fullName, String rawPassword,
            String positionName, String language);

    /**
     * Gửi email HTML thông tin đăng nhập cho quản trị viên mới (Admin Portal).
     *
     * @param language "vi" | "en" (mặc định vi)
     */
    void sendAdminCredentialsEmail(String toEmail, String fullName, String rawPassword, String language);

}
