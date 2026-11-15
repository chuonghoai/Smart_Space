package com.vn.smart_space.consts;

/** Trạng thái đề xuất khóa tài khoản người dùng. */
public enum EAccountLockRequestStatus {
    pending,
    approved,
    rejected,
    cancelled,
    expired;

    public boolean isResolved() {
        return this != pending;
    }
}
