package com.vn.smart_space.configuration.websocket;

import java.security.Principal;

import org.springframework.security.authentication.AbstractAuthenticationToken;

/**
 * Wrapper around an existing {@link AbstractAuthenticationToken} that overrides
 * {@link #getName()} to return the application-level userId instead of the JWT subject (email).
 * <p>
 * Spring's {@code convertAndSendToUser()} routes messages by matching
 * {@code principal.getName()} against the first argument. Since all call-sites pass
 * {@code user.getId()} (a UUID), the principal must also report the same value.
 */
public class UserIdAuthenticationToken implements Principal {

    private final AbstractAuthenticationToken delegate;
    private final String userId;

    public UserIdAuthenticationToken(AbstractAuthenticationToken delegate, String userId) {
        this.delegate = delegate;
        this.userId = userId;
    }

    @Override
    public String getName() {
        return userId;
    }

    public AbstractAuthenticationToken getDelegate() {
        return delegate;
    }
}
