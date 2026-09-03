const express = require('express');
const router = express.Router();

// Real production history storage (Empty by default)
let historyItems = [];

router.get('/', (req, res) => {
  const userId = req.headers['x-user-id'] || 'usr_default';
  const { type, search } = req.query;

  let result = historyItems.filter(item => item.userId === userId || !item.userId);

  if (type && type !== 'all') {
    result = result.filter(item => item.type.toLowerCase() === type.toLowerCase());
  }

  if (search) {
    const query = search.toLowerCase();
    result = result.filter(item => 
      item.fileName.toLowerCase().includes(query) ||
      item.sourceLanguage.toLowerCase().includes(query) ||
      item.targetLanguage.toLowerCase().includes(query)
    );
  }

  res.json({ count: result.length, history: result });
});

router.post('/', (req, res) => {
  const userId = req.headers['x-user-id'] || 'usr_default';
  const item = {
    id: 'hist_' + Date.now(),
    userId: userId,
    ...req.body,
    timestamp: new Date().toISOString()
  };
  historyItems.unshift(item);
  res.json({ success: true, item });
});

router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const userId = req.headers['x-user-id'] || 'usr_default';
  historyItems = historyItems.filter(item => !(item.id === id && (item.userId === userId || !item.userId)));
  res.json({ success: true, message: 'History item deleted' });
});

module.exports = router;
