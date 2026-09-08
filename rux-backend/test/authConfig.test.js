const test = require('node:test');
const assert = require('node:assert/strict');
const { getAuthSecrets } = require('../src/utils/authConfig');

const originalEnv = { ...process.env };

test.afterEach(() => {
    process.env = { ...originalEnv };
});

test('throws when auth secrets are missing', () => {
    delete process.env.JWT_SECRET;
    delete process.env.AUTH_SECRET;
    delete process.env.JWT_REFRESH_SECRET;
    delete process.env.AUTH_REFRESH_SECRET;

    assert.throws(
        () => getAuthSecrets(),
        /Missing required auth secret: JWT_SECRET/
    );
});

test('loads configured access and refresh secrets', () => {
    process.env.JWT_SECRET = 'access-secret-value';
    process.env.JWT_REFRESH_SECRET = 'refresh-secret-value';

    assert.deepEqual(getAuthSecrets(), {
        accessSecret: 'access-secret-value',
        refreshSecret: 'refresh-secret-value'
    });
});

test('requires distinct access and refresh secrets', () => {
    process.env.JWT_SECRET = 'same-secret';
    process.env.JWT_REFRESH_SECRET = 'same-secret';

    assert.throws(
        () => getAuthSecrets(),
        /JWT_REFRESH_SECRET must be different from JWT_SECRET/
    );
});
