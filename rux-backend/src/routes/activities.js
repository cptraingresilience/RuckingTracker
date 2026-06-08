const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Submit Activity
router.post('/', authenticateToken, (req, res) => {
    const { title, distance, duration, pace } = req.body;
    
    if (!title || !distance || !duration || !pace) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // TODO: Save to database
    res.status(201).json({
        message: 'Activity submitted',
        activity: {
            id: 'activity-123',
            title,
            distance,
            duration,
            pace,
            createdAt: new Date()
        }
    });
});

// Get Activities
router.get('/', authenticateToken, (req, res) => {
    // TODO: Fetch from database
    res.json({
        activities: [],
        pagination: { page: 1, limit: 20, total: 0 }
    });
});

// Get Single Activity
router.get('/:activityId', authenticateToken, (req, res) => {
    res.json({
        activity: {
            id: req.params.activityId,
            title: 'Sample Activity',
            distance: 5.2
        }
    });
});

// Delete Activity
router.delete('/:activityId', authenticateToken, (req, res) => {
    res.json({ message: 'Activity deleted' });
});

module.exports = router;
