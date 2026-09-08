const assert = require('node:assert/strict');
const test = require('node:test');
const jwt = require('jsonwebtoken');
const authRouter = require('../src/routes/auth');
const {
    getAuthSecrets,
    jwtOptions,
    jwtVerificationOptions
} = require('../src/utils/authConfig');

const originalAccessSecret = process.env.JWT_SECRET;
const originalRefreshSecret = process.env.JWT_REFRESH_SECRET;
const tokenClaims = ({ userId, email, tokenType, iss, aud }) => ({
    userId,
    email,
    tokenType,
    iss,
    aud
});

test.beforeEach(() => {
    process.env.JWT_SECRET = 'test-access-secret';
    process.env.JWT_REFRESH_SECRET = 'test-refresh-secret';
});

test.after(() => {
    if (originalAccessSecret === undefined) {
        delete process.env.JWT_SECRET;
    } else {
        process.env.JWT_SECRET = originalAccessSecret;
    }

    if (originalRefreshSecret === undefined) {
        delete process.env.JWT_REFRESH_SECRET;
    } else {
        process.env.JWT_REFRESH_SECRET = originalRefreshSecret;
    }
});

test('generates access and refresh tokens with their respective secrets', () => {
    const { accessSecret, refreshSecret } = getAuthSecrets();
    const { accessToken, refreshToken } = authRouter.generateTokens('user-1', 'user@example.com');
    const accessClaims = jwt.verify(accessToken, accessSecret, jwtVerificationOptions);
    const refreshClaims = authRouter.verifyRefreshToken(refreshToken);

    assert.deepEqual(
        tokenClaims(accessClaims),
        {
            userId: 'user-1',
            email: 'user@example.com',
            tokenType: 'access',
            iss: jwtOptions.issuer,
            aud: jwtOptions.audience
        }
    );
    assert.deepEqual(
        tokenClaims(refreshClaims),
        {
            userId: 'user-1',
            email: 'user@example.com',
            tokenType: 'refresh',
            iss: jwtOptions.issuer,
            aud: jwtOptions.audience
        }
    );
    assert.ok(Number.isInteger(accessClaims.iat));
    assert.ok(Number.isInteger(accessClaims.exp));
    assert.ok(Number.isInteger(refreshClaims.iat));
    assert.ok(Number.isInteger(refreshClaims.exp));
    assert.throws(() => jwt.verify(accessToken, refreshSecret, jwtVerificationOptions));
    assert.throws(() => jwt.verify(refreshToken, accessSecret, jwtVerificationOptions));
});

test('rejects tampered and non-refresh tokens during refresh verification', () => {
    const { refreshSecret } = getAuthSecrets();
    const { refreshToken } = authRouter.generateTokens('user-1', 'user@example.com');
    const tamperedToken = `${refreshToken.slice(0, -1)}${refreshToken.endsWith('a') ? 'b' : 'a'}`;
    const accessPurposeToken = jwt.sign(
        { userId: 'user-1', email: 'user@example.com', tokenType: 'access' },
        refreshSecret,
        { ...jwtOptions, expiresIn: '7d' }
    );

    assert.throws(() => authRouter.verifyRefreshToken(tamperedToken));
    assert.throws(() => authRouter.verifyRefreshToken(accessPurposeToken));
});
