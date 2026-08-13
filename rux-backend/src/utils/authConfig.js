const devFallbackSecret = 'rucking-tracker-dev-secret';

const resolveSecret = (primaryKey, legacyKey) => {
    const configuredSecret = process.env[primaryKey] || process.env[legacyKey];

    if (configuredSecret) {
        return configuredSecret;
    }

    if (process.env.NODE_ENV === 'production') {
        throw new Error(`Missing required auth secret: ${primaryKey}`);
    }

    return devFallbackSecret;
};

const getAuthSecrets = () => {
    const accessSecret = resolveSecret('JWT_SECRET', 'AUTH_SECRET');
    const refreshSecret =
        process.env.JWT_REFRESH_SECRET ||
        process.env.AUTH_REFRESH_SECRET ||
        `${accessSecret}-refresh`;

    return { accessSecret, refreshSecret };
};

module.exports = { getAuthSecrets };
