const express = require('express');
const router = express.Router();
const { readCollection } = require('../data/store');

router.get('/', async (req, res) => {
    const { period = 'weekly' } = req.query;

    try {
        const [activities, users] = await Promise.all([
            readCollection('activities'),
            readCollection('users')
        ]);

        const leaderboard = users
            .map((user) => {
                const userActivities = activities.filter((activity) => activity.userId === user.id);
                const totalDistance = userActivities.reduce((sum, activity) => sum + activity.distance, 0);

                return {
                    username: user.username,
                    totalDistance,
                    totalActivities: userActivities.length
                };
            })
            .filter((entry) => entry.totalActivities > 0)
            .sort((left, right) => right.totalDistance - left.totalDistance)
            .map((entry, index) => ({
                rank: index + 1,
                ...entry
            }));

        res.json({ period, entries: leaderboard });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load leaderboard' });
    }
});

module.exports = router;
