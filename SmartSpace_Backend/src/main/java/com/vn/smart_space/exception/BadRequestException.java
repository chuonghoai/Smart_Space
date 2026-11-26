package com.vn.smart_space.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class BadRequestException extends RuntimeException {
    private final Object[] args;

    public BadRequestException(String message) {
        super(message);
        this.args = null;
    }

    public BadRequestException(String message, Object... args) {
        super(message);
        this.args = args;
    }

    public Object[] getArgs() {
        return args;
    }
}
