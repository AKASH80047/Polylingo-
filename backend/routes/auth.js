const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const config = require('../config/default');

// Guest token generation
router.post('/guest', (req, res) => {
  const token = jwt.sign({ userId: 'guest_' + Date.now(), isGuest: true, name: 'Guest User' }, config.jwtSecret, { expiresIn: '7d' });
  return res.json({
    token,
    user: {
      id: 'guest_user',
      name: 'Guest User',
      email: 'guest@polylingo.ai',
      isGuest: true,
      plan: 'Free Guest',
      translationsCount: 3,
      translationsQuota: 10,
      storageUsedMb: 45,
      storageQuotaMb: 500
    }
  });
});

// Register
router.post('/register', (req, res) => {
  const { name, email, password } = req.body;
  const userId = 'usr_' + Date.now();
  const token = jwt.sign({ userId, email, name, isGuest: false }, config.jwtSecret, { expiresIn: '30d' });

  return res.json({
    token,
    user: {
      id: userId,
      name: name || 'PolyLingo User',
      email: email || 'user@example.com',
      isGuest: false,
      plan: 'Pro Plan',
      translationsCount: 23,
      translationsQuota: 50,
      storageUsedMb: 1200,
      storageQuotaMb: 5000
    }
  });
});

// Login
router.post('/login', (req, res) => {
  const { email } = req.body;
  const userId = 'usr_10294';
  const token = jwt.sign({ userId, email, isGuest: false }, config.jwtSecret, { expiresIn: '30d' });

  return res.json({
    token,
    user: {
      id: userId,
      name: email ? email.split('@')[0] : 'Demo User',
      email: email || 'demo@polylingo.ai',
      isGuest: false,
      plan: 'Pro Plan',
      translationsCount: 23,
      translationsQuota: 50,
      storageUsedMb: 1200,
      storageQuotaMb: 5000
    }
  });
});

// Google Sign In
router.post('/google', (req, res) => {
  const userId = 'usr_google_' + Date.now();
  const token = jwt.sign({ userId, isGuest: false }, config.jwtSecret, { expiresIn: '30d' });

  return res.json({
    token,
    user: {
      id: userId,
      name: 'Google User',
      email: 'google.user@polylingo.ai',
      isGuest: false,
      plan: 'Pro Plan',
      translationsCount: 15,
      translationsQuota: 50,
      storageUsedMb: 850,
      storageQuotaMb: 5000
    }
  });
});

module.exports = router;
