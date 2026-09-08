const jwt = require('jsonwebtoken');
const { getAuthSecrets, jwtVerificationOptions } = require('../utils/authConfig');

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }
    
    try {
        const { accessSecret } = getAuthSecrets();
        const decoded = jwt.verify(token, accessSecret, jwtVerificationOptions);
        if (decoded.tokenType !== 'access') {
            throw new Error('Invalid access token type');
        }
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(403).json({ error: 'Invalid token' });
    }
};

module.exports = { authenticateToken };
