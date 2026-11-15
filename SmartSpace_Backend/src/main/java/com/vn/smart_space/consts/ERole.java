package com.vn.smart_space.consts;

public enum ERole {
    admin,
    staff,
    client;

    public boolean isSelfRegistrable() {
        return this == client;
    }
}
