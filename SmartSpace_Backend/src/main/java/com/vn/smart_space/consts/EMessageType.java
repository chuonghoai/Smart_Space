package com.vn.smart_space.consts;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum EMessageType {
    text, // Tin nhắn văn bản
    image, // Hình ảnh
    video, // Video
    file, // File đính kèm
    system; // Tin nhắn hệ thống (user joined, user left, etc.)

    @JsonCreator
    public static EMessageType fromString(String value) {
        if (value == null || value.trim().isEmpty()) {
            return text;
        }
        for (EMessageType type : values()) {
            if (type.name().equalsIgnoreCase(value.trim())) {
                return type;
            }
        }
        return text;
    }

    @JsonValue
    public String toValue() {
        return this.name();
    }
}
