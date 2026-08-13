const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');
const router = express.Router();
const { readCollection, updateCollection } = require('../data/store');
const { getAuthSecrets } = require('../utils/authConfig');

const generateTokens = (userId, email) => {
    const { accessSecret, refreshSecret } = getAuthSecrets();
    const accessToken = jwt.sign(
        { userId, email },
        accessSecret,
        { expiresIn: '15m' }
    );
    const refreshToken = jwt.sign(
        { userId, email },
        refreshSecret,
        { expiresIn: '7d' }
    );
    return { accessToken, refreshToken };
};

const normalizeEmail = (email) => email.trim().toLowerCase();

// Sign Up
router.post('/signup', async (req, res) => {
    const { email, password, username } = req.body;
    
    if (!email || !password || !username) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        const normalizedEmail = normalizeEmail(email);
        const trimmedUsername = username.trim();
        const passwordHash = await bcrypt.hash(password, 10);
        let createdUser;

        await updateCollection('users', async (users) => {
            if (users.some((user) => user.email === normalizedEmail)) {
                const duplicateUserError = new Error('duplicate-user');
                duplicateUserError.code = 'DUPLICATE_USER';
                throw duplicateUserError;
            }

            createdUser = {
                id: randomUUID(),
                email: normalizedEmail,
                username: trimmedUsername,
                passwordHash,
                createdAt: new Date().toISOString()
            };

            return [...users, createdUser];
        });

        const { accessToken, refreshToken } = generateTokens(createdUser.id, createdUser.email);

        res.status(201).json({
            message: 'Signup successful',
            accessToken,
            refreshToken,
            user: {
                id: createdUser.id,
                email: createdUser.email,
                username: createdUser.username
            }
        });
    } catch (error) {
        if (error.code === 'DUPLICATE_USER') {
            return res.status(409).json({ error: 'An account with this email already exists' });
        }

        res.status(500).json({ error: 'Unable to create account' });
    }
});

// Sign In
router.post('/signin', async (req, res) => {
    const { email, password } = req.body;
    
    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password required' });
    }

    try {
        const users = await readCollection('users');
        const normalizedEmail = normalizeEmail(email);
        const user = users.find((candidate) => candidate.email === normalizedEmail);

        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const isValidPassword = await bcrypt.compare(password, user.passwordHash);
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const { accessToken, refreshToken } = generateTokens(user.id, user.email);

        res.json({
            message: 'Signin successful',
            accessToken,
            refreshToken,
            user: {
                id: user.id,
                email: user.email,
                username: user.username
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Unable to sign in' });
    }
});

// Refresh Token
router.post('/refresh', (req, res) => {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
        return res.status(400).json({ error: 'Refresh token required' });
    }
    
    try {
        const { refreshSecret } = getAuthSecrets();
        const decoded = jwt.verify(refreshToken, refreshSecret);
        const { accessToken, refreshToken: newRefresh } = generateTokens(decoded.userId, decoded.email);
        res.json({ accessToken, refreshToken: newRefresh });
    } catch (err) {
        res.status(401).json({ error: 'Invalid refresh token' });
    }
});

module.exports = router;
