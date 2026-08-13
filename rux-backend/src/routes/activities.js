const express = require('express');
const { randomUUID } = require('crypto');
const { authenticateToken } = require('../middleware/auth');
const { readCollection, writeCollection } = require('../data/store');
const router = express.Router();

const parseActivity = (body, currentUserId, existingActivity = {}) => {
    const title = body.title?.trim();
    const distance = Number(body.distance);
    const duration = Number(body.duration);
    const startedAt = body.startedAt;
    const endedAt = body.endedAt || null;
    const pace = Number.isFinite(Number(body.pace)) && Number(body.pace) > 0
        ? Number(body.pace)
        : duration > 0 && distance > 0
            ? duration / 60 / distance
            : 0;
    const packWeight = body.packWeight == null || body.packWeight === ''
        ? null
        : Number(body.packWeight);

    if (!title || !Number.isFinite(distance) || distance <= 0 || !Number.isFinite(duration) || duration <= 0 || !startedAt) {
        return { error: 'Missing or invalid required fields' };
    }

    return {
        value: {
            id: body.id || existingActivity.id || randomUUID(),
            userId: currentUserId,
            title,
            notes: body.notes?.trim() || '',
            distance,
            duration,
            pace,
            packWeight,
            startedAt,
            endedAt,
            createdAt: existingActivity.createdAt || new Date().toISOString(),
            updatedAt: new Date().toISOString()
        }
    };
};

// Submit Activity
router.post('/', authenticateToken, async (req, res) => {
    try {
        const activities = await readCollection('activities');
        const parsed = parseActivity(req.body, req.user.userId);

        if (parsed.error) {
            return res.status(400).json({ error: parsed.error });
        }

        if (activities.some((activity) => activity.id === parsed.value.id && activity.userId === req.user.userId)) {
            return res.status(409).json({ error: 'Activity already exists' });
        }

        activities.push(parsed.value);
        await writeCollection('activities', activities);

        res.status(201).json({
            message: 'Activity submitted',
            activity: parsed.value
        });
    } catch (error) {
        res.status(500).json({ error: 'Unable to save activity' });
    }
});

// Get Activities
router.get('/', authenticateToken, async (req, res) => {
    try {
        const activities = await readCollection('activities');
        const userActivities = activities
            .filter((activity) => activity.userId === req.user.userId)
            .sort((left, right) => new Date(right.startedAt) - new Date(left.startedAt));

        res.json({ activities: userActivities });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load activities' });
    }
});

router.get('/stats/summary', authenticateToken, async (req, res) => {
    try {
        const activities = await readCollection('activities');
        const userActivities = activities.filter((activity) => activity.userId === req.user.userId);
        const totalDistance = userActivities.reduce((sum, activity) => sum + activity.distance, 0);
        const totalDuration = userActivities.reduce((sum, activity) => sum + activity.duration, 0);

        res.json({
            totalActivities: userActivities.length,
            totalDistance,
            totalDuration
        });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load stats' });
    }
});

// Get Single Activity
router.get('/:activityId', authenticateToken, async (req, res) => {
    try {
        const activities = await readCollection('activities');
        const activity = activities.find(
            (item) => item.id === req.params.activityId && item.userId === req.user.userId
        );

        if (!activity) {
            return res.status(404).json({ error: 'Activity not found' });
        }

        res.json({ activity });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load activity' });
    }
});

// Update Activity
router.put('/:activityId', authenticateToken, async (req, res) => {
    try {
        const activities = await readCollection('activities');
        const index = activities.findIndex(
            (item) => item.id === req.params.activityId && item.userId === req.user.userId
        );

        if (index === -1) {
            return res.status(404).json({ error: 'Activity not found' });
        }

        const parsed = parseActivity(
            { ...req.body, id: req.params.activityId },
            req.user.userId,
            activities[index]
        );

        if (parsed.error) {
            return res.status(400).json({ error: parsed.error });
        }

        activities[index] = parsed.value;
        await writeCollection('activities', activities);

        res.json({
            message: 'Activity updated',
            activity: parsed.value
        });
    } catch (error) {
        res.status(500).json({ error: 'Unable to update activity' });
    }
});

// Delete Activity
router.delete('/:activityId', authenticateToken, async (req, res) => {
    try {
        const activities = await readCollection('activities');
        const remainingActivities = activities.filter(
            (item) => !(item.id === req.params.activityId && item.userId === req.user.userId)
        );

        if (remainingActivities.length === activities.length) {
            return res.status(404).json({ error: 'Activity not found' });
        }

        await writeCollection('activities', remainingActivities);

        res.json({ message: 'Activity deleted' });
    } catch (error) {
        res.status(500).json({ error: 'Unable to delete activity' });
    }
});

module.exports = router;
