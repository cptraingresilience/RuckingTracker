const express = require('express');
const router = express.Router();
const { readCollection } = require('../data/store');

const filterActivitiesForPeriod = (activities, period) => {
    if (period === 'all') {
        return activities;
    }

    const now = new Date();
    const startDate = new Date(now);

    if (period === 'monthly') {
        startDate.setDate(now.getDate() - 30);
    } else {
        startDate.setDate(now.getDate() - 7);
    }

    return activities.filter((activity) => new Date(activity.startedAt) >= startDate);
};

router.get('/', async (req, res) => {
    const { period = 'weekly', teamId } = req.query;

    try {
        const [activities, users, teams] = await Promise.all([
            readCollection('activities'),
            readCollection('users'),
            readCollection('teams')
        ]);

        let team = null;
        let memberIds = null;

        if (teamId) {
            team = teams.find((candidate) => candidate.id === teamId);

            if (!team) {
                return res.status(404).json({ error: 'Team not found' });
            }

            memberIds = new Set(Array.isArray(team.members) ? team.members : []);
        }

        const leaderboard = users
            .filter((user) => !memberIds || memberIds.has(user.id))
            .map((user) => {
                const userActivities = filterActivitiesForPeriod(
                    activities.filter((activity) => activity.userId === user.id),
                    period
                );
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

        res.json({
            period,
            teamId: team?.id ?? null,
            teamName: team?.name ?? null,
            entries: leaderboard
        });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load leaderboard' });
    }
});

module.exports = router;
