const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Create Team
router.post('/', authenticateToken, (req, res) => {
    const { name } = req.body;
    
    if (!name) {
        return res.status(400).json({ error: 'Team name required' });
    }
    
    res.status(201).json({
        message: 'Team created',
        team: { id: 'team-123', name, createdAt: new Date() }
    });
});

// Join Team
router.post('/:teamId/join', authenticateToken, (req, res) => {
    res.json({ message: 'Joined team successfully' });
});

// Get Team
router.get('/:teamId', authenticateToken, (req, res) => {
    res.json({
        team: {
            id: req.params.teamId,
            name: 'Team Name',
            members: []
        }
    });
});

module.exports = router;
