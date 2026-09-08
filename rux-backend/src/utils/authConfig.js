const resolveSecret = (primaryKey, legacyKey) => {
    const configuredSecret = process.env[primaryKey] || process.env[legacyKey];

    if (typeof configuredSecret === 'string' && configuredSecret.trim().length > 0) {
        return configuredSecret.trim();
    }

    throw new Error(`Missing required auth secret: ${primaryKey}`);
};

const getAuthSecrets = () => {
    const accessSecret = resolveSecret('JWT_SECRET', 'AUTH_SECRET');
    const refreshSecret = resolveSecret('JWT_REFRESH_SECRET', 'AUTH_REFRESH_SECRET');

    if (accessSecret === refreshSecret) {
        throw new Error('JWT_REFRESH_SECRET must be different from JWT_SECRET');
    }

    return { accessSecret, refreshSecret };
};

module.exports = { getAuthSecrets };
