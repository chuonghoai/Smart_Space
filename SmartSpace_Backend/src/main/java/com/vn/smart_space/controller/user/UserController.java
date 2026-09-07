package com.vn.smart_space.controller.user;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.consts.ESupportedLanguage;
import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.user.UpdateLanguageRequest;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.service.user.IUserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Slf4j
public class UserController {

    private final IUserService userService;

    @PatchMapping("/language")
    public ResponseEntity<ApiResponse> updateLanguage(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid UpdateLanguageRequest request) {
        
        if (!ESupportedLanguage.isSupported(request.getLanguage())) {
            throw new BadRequestException("Language is not supported");
        }

        String userId = jwt.getClaim("userId").toString();
        userService.updateLanguage(userId, request.getLanguage());
        
        return ResponseEntity.ok(ApiResponse.success("user.language.update.success", null));
    }

}
