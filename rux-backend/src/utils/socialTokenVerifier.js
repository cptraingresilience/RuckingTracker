const { createRemoteJWKSet, jwtVerify } = require('jose');
const { OAuth2Client } = require('google-auth-library');
const { getSocialAuthConfig } = require('./authConfig');

// Apple rotates its signing keys; jose caches and refreshes this JWKS automatically.
const appleJwks = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));

class SocialAuthError extends Error {
    constructor(message, statusCode = 401) {
        super(message);
        this.name = 'SocialAuthError';
        this.statusCode = statusCode;
    }
}

const normalizeVerifiedEmail = (email) => (email ? email.trim().toLowerCase() : null);

/**
 * Verifies an Apple identity token (from Sign in with Apple on iOS).
 * Checks signature against Apple's public keys, issuer, expiry, and audience.
 */
async function verifyAppleToken(identityToken) {
    const { appleBundleId } = getSocialAuthConfig();

    let payload;
    try {
        ({ payload } = await jwtVerify(identityToken, appleJwks, {
            issuer: 'https://appleid.apple.com',
            audience: appleBundleId
        }));
    } catch {
        throw new SocialAuthError('Invalid Apple identity token');
    }

    if (!payload.sub) {
        throw new SocialAuthError('Apple identity token is missing a subject');
    }

    return {
        provider: 'apple',
        providerUserId: payload.sub,
        // Apple only includes email on the first authorization (or when using
        // a private relay address). Callers must tolerate null.
        email: normalizeVerifiedEmail(payload.email),
        fullName: null
    };
}

/**
 * Verifies a Google ID token (from GoogleSignIn on iOS).
 * google-auth-library checks signature, issuer, expiry, and audience.
 */
async function verifyGoogleToken(identityToken) {
    const { googleClientId } = getSocialAuthConfig();

    if (!googleClientId) {
        throw new SocialAuthError('Google sign-in is not configured on this server', 503);
    }

    let payload;
    try {
        const client = new OAuth2Client(googleClientId);
        const ticket = await client.verifyIdToken({
            idToken: identityToken,
            audience: googleClientId
        });
        payload = ticket.getPayload();
    } catch {
        throw new SocialAuthError('Invalid Google identity token');
    }

    if (!payload?.sub) {
        throw new SocialAuthError('Google identity token is missing a subject');
    }

    return {
        provider: 'google',
        providerUserId: payload.sub,
        email: normalizeVerifiedEmail(payload.email_verified ? payload.email : null),
        fullName: payload.name ?? null
    };
}

async function verifySocialToken(provider, identityToken) {
    if (provider === 'apple') {
        return verifyAppleToken(identityToken);
    }
    if (provider === 'google') {
        return verifyGoogleToken(identityToken);
    }
    throw new SocialAuthError('Unsupported provider', 400);
}

module.exports = { verifySocialToken, SocialAuthError };
