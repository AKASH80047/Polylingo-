const express = require('express');
const router = express.Router();

// Real User-Scoped In-Memory Database Store (Empty by default)
let userFiles = [];

// Get all files for the authenticated user
router.get('/', (req, res) => {
  const userId = req.headers['x-user-id'] || 'usr_default';
  const { sort = 'newest', search = '' } = req.query;

  let result = userFiles.filter(f => f.userId === userId);

  if (search) {
    result = result.filter(f => f.name.toLowerCase().includes(search.toLowerCase()));
  }

  if (sort === 'newest') result.sort((a, b) => new Date(b.dateAdded) - new Date(a.dateAdded));
  if (sort === 'oldest') result.sort((a, b) => new Date(a.dateAdded) - new Date(b.dateAdded));
  if (sort === 'name') result.sort((a, b) => a.name.localeCompare(b.name));
  if (sort === 'size') result.sort((a, b) => b.sizeMb - a.sizeMb);

  res.json({ count: result.length, files: result });
});

// Download secure file
router.get('/:id/download', (req, res) => {
  const { id } = req.params;
  const userId = req.headers['x-user-id'] || 'usr_default';

  const file = userFiles.find(f => f.id === id);
  if (!file) {
    return res.status(404).json({ error: 'File not found' });
  }

  // Security Check: Ensure file belongs to authenticated user
  if (file.userId !== userId) {
    return res.status(403).json({ error: 'Access Denied: You do not have permission to access this file.' });
  }

  res.json({
    fileId: file.id,
    downloadUrl: `/api/files/stream/${file.id}?token=${file.downloadToken}`,
    name: file.name,
    format: file.format,
    sizeMb: file.sizeMb
  });
});

// Rename file
router.put('/:id/rename', (req, res) => {
  const { id } = req.params;
  const userId = req.headers['x-user-id'] || 'usr_default';
  const { newName } = req.body;

  const file = userFiles.find(f => f.id === id);
  if (!file) {
    return res.status(404).json({ error: 'File not found' });
  }

  if (file.userId !== userId) {
    return res.status(403).json({ error: 'Access Denied' });
  }

  file.name = newName;
  return res.json({ success: true, file });
});

// Delete file
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const userId = req.headers['x-user-id'] || 'usr_default';

  const fileIndex = userFiles.findIndex(f => f.id === id && f.userId === userId);
  if (fileIndex === -1) {
    return res.status(404).json({ error: 'File not found or unauthorized' });
  }

  userFiles.splice(fileIndex, 1);
  res.json({ success: true, message: 'File deleted successfully from private vault.' });
});

module.exports = router;
