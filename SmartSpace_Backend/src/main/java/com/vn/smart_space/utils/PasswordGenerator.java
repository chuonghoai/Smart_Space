package com.vn.smart_space.utils;

import java.security.SecureRandom;

public final class PasswordGenerator {

    private static final String PW_UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    private static final String PW_LOWER = "abcdefghijkmnopqrstuvwxyz";
    private static final String PW_DIGIT = "23456789";
    private static final String PW_SPECIAL = "!@#$^()_";
    private static final String PW_ALL = PW_UPPER + PW_LOWER + PW_DIGIT + PW_SPECIAL;
    private static final int DEFAULT_LENGTH = 10;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private PasswordGenerator() {
    }

    public static String generateRandomPassword() {
        char[] chars = new char[DEFAULT_LENGTH];
        chars[0] = PW_UPPER.charAt(SECURE_RANDOM.nextInt(PW_UPPER.length()));
        chars[1] = PW_LOWER.charAt(SECURE_RANDOM.nextInt(PW_LOWER.length()));
        chars[2] = PW_DIGIT.charAt(SECURE_RANDOM.nextInt(PW_DIGIT.length()));
        chars[3] = PW_SPECIAL.charAt(SECURE_RANDOM.nextInt(PW_SPECIAL.length()));
        for (int i = 4; i < DEFAULT_LENGTH; i++) {
            chars[i] = PW_ALL.charAt(SECURE_RANDOM.nextInt(PW_ALL.length()));
        }
        for (int i = DEFAULT_LENGTH - 1; i > 0; i--) {
            int j = SECURE_RANDOM.nextInt(i + 1);
            char tmp = chars[i];
            chars[i] = chars[j];
            chars[j] = tmp;
        }
        return new String(chars);
    }
}

