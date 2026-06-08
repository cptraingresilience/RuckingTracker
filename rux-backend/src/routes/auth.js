const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();

const generateTokens = (userId, email) => {
    const accessToken = jwt.sign(
        { userId, email },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
    );
    const refreshToken = jwt.sign(
        { userId, email },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: '7d' }
    );
    return { accessToken, refreshToken };
};

// Sign Up
router.post('/signup', (req, res) => {
    const { email, password, username } = req.body;
    
    if (!email || !password || !username) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // TODO: Hash password and save to database
    // For now, just generate tokens
    const { accessToken, refreshToken } = generateTokens('user-123', email);
    
    res.status(201).json({
        message: 'Signup successful',
        accessToken,
        refreshToken,
        user: {
            id: 'user-123',
            email,
            username
        }
    });
});

// Sign In
router.post('/signin', (req, res) => {
    const { email, password } = req.body;
    
    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password required' });
    }
    
    // TODO: Verify password from database
    // For now, just generate tokens
    const { accessToken, refreshToken } = generateTokens('user-123', email);
    
    res.json({
        message: 'Signin successful',
        accessToken,
        refreshToken,
        user: {
            id: 'user-123',
            email
        }
    });
});

// Refresh Token
router.post('/refresh', (req, res) => {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
        return res.status(400).json({ error: 'Refresh token required' });
    }
    
    try {
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const { accessToken, refreshToken: newRefresh } = generateTokens(decoded.userId, decoded.email);
        res.json({ accessToken, refreshToken: newRefresh });
    } catch (err) {
        res.status(401).json({ error: 'Invalid refresh token' });
    }
});

module.exports = router;
