const devFallbackAccessSecret = 'rucking-tracker-dev-access-secret-local-only';
const devFallbackRefreshSecret = 'rucking-tracker-dev-refresh-secret-local-only';
const minimumProductionSecretLength = 32;

const isProduction = () => process.env.NODE_ENV === 'production';

const readSecret = (...keys) => {
    for (const key of keys) {
        const value = process.env[key]?.trim();
        if (value) {
            return value;
        }
    }

    return null;
};

const assertProductionSecret = (name, value) => {
    if (value.length < minimumProductionSecretLength) {
        throw new Error(`${name} must be at least ${minimumProductionSecretLength} characters in production`);
    }
};

const resolveAccessSecret = () => {
    const configuredSecret = readSecret('JWT_SECRET', 'AUTH_SECRET');

    if (!configuredSecret) {
        if (isProduction()) {
            throw new Error('Missing required auth secret: JWT_SECRET');
        }

        return devFallbackAccessSecret;
    }

    if (isProduction()) {
        assertProductionSecret('JWT_SECRET', configuredSecret);
    }

    return configuredSecret;
};

const resolveRefreshSecret = (accessSecret) => {
    const configuredSecret = readSecret('JWT_REFRESH_SECRET', 'AUTH_REFRESH_SECRET');

    if (!configuredSecret) {
        if (isProduction()) {
            throw new Error('Missing required auth secret: JWT_REFRESH_SECRET');
        }

        return devFallbackRefreshSecret;
    }

    if (isProduction()) {
        assertProductionSecret('JWT_REFRESH_SECRET', configuredSecret);
        if (configuredSecret === accessSecret) {
            throw new Error('JWT_REFRESH_SECRET must differ from JWT_SECRET in production');
        }
    }

    return configuredSecret;
};

const getAuthSecrets = () => {
    const accessSecret = resolveAccessSecret();
    const refreshSecret = resolveRefreshSecret(accessSecret);

    return { accessSecret, refreshSecret };
};

module.exports = { getAuthSecrets };
