const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const { randomUUID } = require('crypto');
const router = express.Router();
const { readCollection, updateCollection } = require('../data/store');
const { getAuthSecrets } = require('../utils/authConfig');
const { verifySocialToken, SocialAuthError } = require('../utils/socialTokenVerifier');

const signupSchema = Joi.object({
    email: Joi.string().trim().email().required(),
    password: Joi.string().min(6).required(),
    username: Joi.string().trim().min(1).max(50).required()
});

const socialSchema = Joi.object({
    provider: Joi.string().valid('apple', 'google').required(),
    identityToken: Joi.string().trim().min(1).required(),
    // Apple only shares name/email on first authorization — both optional.
    username: Joi.string().trim().min(1).max(50).optional(),
    fullName: Joi.string().trim().max(100).allow(null, '').optional()
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

router.post('/social', async (req, res) => {
    const validation = validateBody(socialSchema, req.body);
    if (validation.error) {
        return res.status(400).json({ error: validation.error });
    }

    const { provider, identityToken, username, fullName } = validation.value;

    try {
        const verified = await verifySocialToken(provider, identityToken);
        let authUser;
        let created = false;

        await updateCollection('users', async (users) => {
            // 1. Returning social user: match on provider + stable provider user ID.
            const existingSocialUser = users.find(
                (candidate) => candidate.provider === verified.provider
                    && candidate.providerUserId === verified.providerUserId
            );
            if (existingSocialUser) {
                authUser = existingSocialUser;
                return users;
            }

            // 2. Account linking: an email/password account with the same
            //    verified email becomes usable through this provider too.
            if (verified.email) {
                const emailMatch = users.find((candidate) => candidate.email === verified.email);
                if (emailMatch) {
                    emailMatch.provider = verified.provider;
                    emailMatch.providerUserId = verified.providerUserId;
                    authUser = emailMatch;
                    return users;
                }
            }

            // 3. New user. Apple may withhold email after first authorization;
            //    fall back to a provider-scoped placeholder so the record stays unique.
            const email = verified.email
                ?? `${verified.provider}-${verified.providerUserId}@users.rux.local`;
            const fallbackUsername = verified.email
                ? verified.email.split('@')[0]
                : `rucker-${verified.providerUserId.slice(0, 8)}`;

            authUser = {
                id: randomUUID(),
                email,
                username: username?.trim() || fallbackUsername,
                fullName: fullName?.trim() || verified.fullName || null,
                passwordHash: null,
                provider: verified.provider,
                providerUserId: verified.providerUserId,
                createdAt: new Date().toISOString()
            };
            created = true;

            return [...users, authUser];
        });

        res.status(created ? 201 : 200).json(
            createAuthPayload(authUser, created ? 'Signup successful' : 'Signin successful')
        );
    } catch (error) {
        if (error instanceof SocialAuthError) {
            return res.status(error.statusCode).json({ error: error.message });
        }

        res.status(500).json({ error: 'Unable to sign in with social account' });
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
