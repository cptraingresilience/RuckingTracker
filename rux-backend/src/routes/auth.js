const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const { randomUUID } = require('crypto');
const router = express.Router();
const { readCollection, updateCollection } = require('../data/store');
const { getAuthSecrets } = require('../utils/authConfig');

const signupSchema = Joi.object({
    email: Joi.string().trim().email().required(),
    password: Joi.string().min(6).required(),
    username: Joi.string().trim().min(1).max(50).required()
});

const signinSchema = Joi.object({
    email: Joi.string().trim().email().required(),
    password: Joi.string().min(1).required()
});

const refreshSchema = Joi.object({
    refreshToken: Joi.string().trim().min(1).required()
});

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

const validateBody = (schema, body) => {
    const { error, value } = schema.validate(body, {
        abortEarly: true,
        stripUnknown: true
    });

    if (error) {
        return { error: error.details[0].message.replace(/"/g, '') };
    }

    return { value };
};

const serializeUser = (user) => ({
    id: user.id,
    email: user.email,
    username: user.username,
    fullName: user.fullName ?? null
});

const createAuthPayload = (user, message) => ({
    message,
    ...generateTokens(user.id, user.email),
    user: serializeUser(user)
});

router.post('/signup', async (req, res) => {
    const validation = validateBody(signupSchema, req.body);
    if (validation.error) {
        return res.status(400).json({ error: validation.error });
    }

    const { email, password, username } = validation.value;

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
                fullName: null,
                passwordHash,
                createdAt: new Date().toISOString()
            };

            return [...users, createdUser];
        });

        res.status(201).json(createAuthPayload(createdUser, 'Signup successful'));
    } catch (error) {
        if (error.code === 'DUPLICATE_USER') {
            return res.status(409).json({ error: 'An account with this email already exists' });
        }

        res.status(500).json({ error: 'Unable to create account' });
    }
});

router.post('/signin', async (req, res) => {
    const validation = validateBody(signinSchema, req.body);
    if (validation.error) {
        return res.status(400).json({ error: validation.error });
    }

    const { email, password } = validation.value;

    try {
        const users = await readCollection('users');
        const normalizedEmail = normalizeEmail(email);
        const user = users.find((candidate) => candidate.email === normalizedEmail);

        if (!user || !user.passwordHash) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const isValidPassword = await bcrypt.compare(password, user.passwordHash);
        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        res.json(createAuthPayload(user, 'Signin successful'));
    } catch (error) {
        res.status(500).json({ error: 'Unable to sign in' });
    }
});

router.post('/refresh', async (req, res) => {
    const validation = validateBody(refreshSchema, req.body);
    if (validation.error) {
        return res.status(400).json({ error: validation.error });
    }

    const { refreshToken } = validation.value;

    try {
        const { refreshSecret } = getAuthSecrets();
        const decoded = jwt.verify(refreshToken, refreshSecret);
        const users = await readCollection('users');
        const user = users.find((candidate) => candidate.id === decoded.userId && candidate.email === decoded.email);

        if (!user) {
            return res.status(401).json({ error: 'Invalid refresh token' });
        }

        const { accessToken, refreshToken: newRefreshToken } = generateTokens(user.id, user.email);
        res.json({ accessToken, refreshToken: newRefreshToken });
    } catch (error) {
        res.status(401).json({ error: 'Invalid refresh token' });
    }
});

module.exports = router;
