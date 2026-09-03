const express = require('express');
const router = express.Router();

let userProfile = {
  id: 'usr_10294',
  name: 'Alex Johnson',
  email: 'alex.johnson@polylingo.ai',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
  plan: 'Pro Plan',
  translationsThisMonth: 23,
  translationsMonthlyLimit: 50,
  storageUsedGb: 1.2,
  storageTotalGb: 5.0
};

let userSettings = {
  defaultSourceLang: 'auto',
  defaultTargetLang: 'es',
  autoDetect: true,
  appearanceMode: 'system', // 'light', 'dark', 'system'
  accentColor: 'blue', // 'blue', 'purple', 'green', 'orange', 'teal'
  defaultDownloadFormat: 'pdf',
  compressionPreference: 'balanced',
  notificationsEnabled: true,
  privacyDataCollection: false
};

router.get('/profile', (req, res) => res.json(userProfile));
router.put('/profile', (req, res) => {
  Object.assign(userProfile, req.body);
  res.json({ success: true, profile: userProfile });
});

router.get('/settings', (req, res) => res.json(userSettings));
router.put('/settings', (req, res) => {
  Object.assign(userSettings, req.body);
  res.json({ success: true, settings: userSettings });
});

module.exports = router;
