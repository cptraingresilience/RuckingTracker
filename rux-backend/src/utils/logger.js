const redactedValue = '[REDACTED]';
const sensitiveKeyPattern = /(password|token|secret|authorization|api[-_]?key)/i;

const sanitizeLogData = (value) => {
    if (Array.isArray(value)) {
        return value.map(sanitizeLogData);
    }

    if (!value || typeof value !== 'object') {
        return value;
    }

    return Object.fromEntries(
        Object.entries(value).map(([key, nestedValue]) => {
            if (sensitiveKeyPattern.test(key)) {
                return [key, redactedValue];
            }

            return [key, sanitizeLogData(nestedValue)];
        })
    );
};

const logger = {
    info: (msg, data = {}) => {
        const safeData = sanitizeLogData(data);
        console.log(JSON.stringify({
            timestamp: new Date().toISOString(),
            level: 'INFO',
            msg,
            ...safeData
        }));
    },
    error: (msg, data = {}) => {
        const safeData = sanitizeLogData(data);
        console.error(JSON.stringify({
            timestamp: new Date().toISOString(),
            level: 'ERROR',
            msg,
            ...safeData
        }));
    },
    warn: (msg, data = {}) => {
        const safeData = sanitizeLogData(data);
        console.warn(JSON.stringify({
            timestamp: new Date().toISOString(),
            level: 'WARN',
            msg,
            ...safeData
        }));
    }
};

module.exports = { logger };
