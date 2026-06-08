const logger = {
    info: (msg, data = {}) => {
        console.log(JSON.stringify({
            timestamp: new Date().toISOString(),
            level: 'INFO',
            msg,
            ...data
        }));
    },
    error: (msg, data = {}) => {
        console.error(JSON.stringify({
            timestamp: new Date().toISOString(),
            level: 'ERROR',
            msg,
            ...data
        }));
    },
    warn: (msg, data = {}) => {
        console.warn(JSON.stringify({
            timestamp: new Date().toISOString(),
            level: 'WARN',
            msg,
            ...data
        }));
    }
};

module.exports = { logger };
