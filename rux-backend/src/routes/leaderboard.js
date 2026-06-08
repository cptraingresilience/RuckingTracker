const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
    const { period = 'weekly' } = req.query;
    
    // TODO: Fetch from database
    res.json({
        period,
        entries: [
            { rank: 1, username: 'runner1', totalDistance: 150, totalActivities: 12 },
            { rank: 2, username: 'runner2', totalDistance: 128, totalActivities: 10 }
        ]
    });
});

module.exports = router;
