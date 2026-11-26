package com.vn.smart_space.controller.emergency;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.emergency.EmergencyContactRequest;
import com.vn.smart_space.dto.request.emergency.ReorderEmergencyContactsRequest;
import com.vn.smart_space.service.emergency.IEmergencyContactService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Danh sách liên hệ khẩn cấp của cư dân và lời mời bảo hộ. */
@RestController
@RequestMapping("/emergency-contacts")
@PreAuthorize("hasRole('client')")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class EmergencyContactController {

    IEmergencyContactService contactService;

    @GetMapping
    public ResponseEntity<ApiResponse> listMine(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success", contactService.listMine(userId(jwt))));
    }

    @PostMapping
    public ResponseEntity<ApiResponse> create(@Valid @RequestBody EmergencyContactRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.created",
                contactService.create(userId(jwt), request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse> update(@PathVariable String id,
            @Valid @RequestBody EmergencyContactRequest request, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.updated",
                contactService.update(userId(jwt), id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        contactService.delete(userId(jwt), id);
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.deleted", null));
    }

    @PutMapping("/order")
    public ResponseEntity<ApiResponse> reorder(@Valid @RequestBody ReorderEmergencyContactsRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.reordered",
                contactService.reorder(userId(jwt), request)));
    }

    @GetMapping("/guardianships")
    public ResponseEntity<ApiResponse> listGuardianships(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                contactService.listGuardianships(userId(jwt))));
    }

    @PostMapping("/guardianships/{id}/accept")
    public ResponseEntity<ApiResponse> accept(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.invitation.accepted",
                contactService.acceptInvitation(userId(jwt), id)));
    }

    @PostMapping("/guardianships/{id}/reject")
    public ResponseEntity<ApiResponse> reject(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        contactService.rejectInvitation(userId(jwt), id);
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.invitation.rejected", null));
    }

    @DeleteMapping("/guardianships/{id}")
    public ResponseEntity<ApiResponse> revoke(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        contactService.revokeGuardianship(userId(jwt), id);
        return ResponseEntity.ok(ApiResponse.success("emergency_contact.guardianship.revoked", null));
    }

    private static String userId(Jwt jwt) {
        return jwt.getClaimAsString("userId");
    }
}
