package com.vn.smart_space.consts;

public enum ESupportedLanguage {
    vi,
    en;

    public static boolean isSupported(String lang) {
        if (lang == null || lang.isBlank()) {
            return false;
        }
        for (ESupportedLanguage language : values()) {
            if (language.name().equalsIgnoreCase(lang)) {
                return true;
            }
        }
        return false;
    }
}
