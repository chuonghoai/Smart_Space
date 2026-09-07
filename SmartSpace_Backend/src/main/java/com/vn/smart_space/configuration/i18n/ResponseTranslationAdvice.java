package com.vn.smart_space.configuration.i18n;

import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.service.i18n.MessageService;

import lombok.RequiredArgsConstructor;

@RestControllerAdvice
@RequiredArgsConstructor
public class ResponseTranslationAdvice implements ResponseBodyAdvice<Object> {

    private final MessageService messageService;

    @Override
    public boolean supports(MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType) {
        return true;
    }

    @Override
    public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType,
            Class<? extends HttpMessageConverter<?>> selectedConverterType, ServerHttpRequest request,
            ServerHttpResponse response) {

        if (body instanceof ApiResponse) {
            ApiResponse apiResponse = (ApiResponse) body;
            if (apiResponse.getMessage() != null) {
                // Translate the message using MessageService
                apiResponse.setMessage(messageService.get(apiResponse.getMessage()));
            }
        }
        return body;
    }
}
