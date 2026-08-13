const express = require('express');
const { randomUUID } = require('crypto');
const { authenticateToken } = require('../middleware/auth');
const { readCollection, updateCollection } = require('../data/store');
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
        const parsed = parseActivity(req.body, req.user.userId);

        if (parsed.error) {
            return res.status(400).json({ error: parsed.error });
        }

        await updateCollection('activities', async (activities) => {
            if (activities.some((activity) => activity.id === parsed.value.id && activity.userId === req.user.userId)) {
                const duplicateActivityError = new Error('duplicate-activity');
                duplicateActivityError.code = 'DUPLICATE_ACTIVITY';
                throw duplicateActivityError;
            }

            return [...activities, parsed.value];
        });

        res.status(201).json({
            message: 'Activity submitted',
            activity: parsed.value
        });
    } catch (error) {
        if (error.code === 'DUPLICATE_ACTIVITY') {
            return res.status(409).json({ error: 'Activity already exists' });
        }

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
        let updatedActivity;

        await updateCollection('activities', async (activities) => {
            const index = activities.findIndex(
                (item) => item.id === req.params.activityId && item.userId === req.user.userId
            );

            if (index === -1) {
                const missingActivityError = new Error('activity-not-found');
                missingActivityError.code = 'ACTIVITY_NOT_FOUND';
                throw missingActivityError;
            }

            const parsed = parseActivity(
                { ...req.body, id: req.params.activityId },
                req.user.userId,
                activities[index]
            );

            if (parsed.error) {
                const invalidActivityError = new Error(parsed.error);
                invalidActivityError.code = 'INVALID_ACTIVITY';
                throw invalidActivityError;
            }

            updatedActivity = parsed.value;
            const nextActivities = [...activities];
            nextActivities[index] = parsed.value;
            return nextActivities;
        });

        res.json({
            message: 'Activity updated',
            activity: updatedActivity
        });
    } catch (error) {
        if (error.code === 'ACTIVITY_NOT_FOUND') {
            return res.status(404).json({ error: 'Activity not found' });
        }

        if (error.code === 'INVALID_ACTIVITY') {
            return res.status(400).json({ error: error.message });
        }

        res.status(500).json({ error: 'Unable to update activity' });
    }
});

// Delete Activity
router.delete('/:activityId', authenticateToken, async (req, res) => {
    try {
        await updateCollection('activities', async (activities) => {
            const remainingActivities = activities.filter(
                (item) => !(item.id === req.params.activityId && item.userId === req.user.userId)
            );

            if (remainingActivities.length === activities.length) {
                const missingActivityError = new Error('activity-not-found');
                missingActivityError.code = 'ACTIVITY_NOT_FOUND';
                throw missingActivityError;
            }

            return remainingActivities;
        });

        res.json({ message: 'Activity deleted' });
    } catch (error) {
        if (error.code === 'ACTIVITY_NOT_FOUND') {
            return res.status(404).json({ error: 'Activity not found' });
        }

        res.status(500).json({ error: 'Unable to delete activity' });
    }
});

module.exports = router;
