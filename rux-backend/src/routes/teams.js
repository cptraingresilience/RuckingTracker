const express = require('express');
const { randomUUID } = require('crypto');
const { authenticateToken } = require('../middleware/auth');
const { readCollection, updateCollection } = require('../data/store');
const router = express.Router();

router.get('/', async (req, res) => {
    try {
        const teams = await readCollection('teams');
        res.json({ teams });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load teams' });
    }
});

// Create Team
router.post('/', authenticateToken, async (req, res) => {
    const { name } = req.body;
    
    if (!name) {
        return res.status(400).json({ error: 'Team name required' });
    }

    try {
        const team = {
            id: randomUUID(),
            name: name.trim(),
            members: [],
            createdAt: new Date().toISOString()
        };

        await updateCollection('teams', async (teams) => [...teams, team]);

        res.status(201).json({
            message: 'Team created',
            team
        });
    } catch (error) {
        res.status(500).json({ error: 'Unable to create team' });
    }
});

// Join Team
router.post('/:teamId/join', authenticateToken, async (req, res) => {
    try {
        let updatedTeam;

        await updateCollection('teams', async (teams) => {
            const teamIndex = teams.findIndex((team) => team.id === req.params.teamId);

            if (teamIndex === -1) {
                const missingTeamError = new Error('team-not-found');
                missingTeamError.code = 'TEAM_NOT_FOUND';
                throw missingTeamError;
            }

            const members = Array.isArray(teams[teamIndex].members) ? [...teams[teamIndex].members] : [];
            if (!members.includes(req.user.userId)) {
                members.push(req.user.userId);
            }

            updatedTeam = { ...teams[teamIndex], members };
            const nextTeams = [...teams];
            nextTeams[teamIndex] = updatedTeam;
            return nextTeams;
        });

        res.json({ message: 'Joined team successfully', team: updatedTeam });
    } catch (error) {
        if (error.code === 'TEAM_NOT_FOUND') {
            return res.status(404).json({ error: 'Team not found' });
        }

        res.status(500).json({ error: 'Unable to join team' });
    }
});

// Get Team
router.get('/:teamId', authenticateToken, async (req, res) => {
    try {
        const teams = await readCollection('teams');
        const team = teams.find((item) => item.id === req.params.teamId);

        if (!team) {
            return res.status(404).json({ error: 'Team not found' });
        }

        res.json({ team });
    } catch (error) {
        res.status(500).json({ error: 'Unable to load team' });
    }
});

module.exports = router;
