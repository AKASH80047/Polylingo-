const express = require('express');
const router = express.Router();
const jobQueueService = require('../services/JobQueueService');

router.get('/:id', (req, res) => {
  const jobId = req.params.id;
  const job = jobQueueService.getJob(jobId);

  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }

  return res.json(job);
});

module.exports = router;
