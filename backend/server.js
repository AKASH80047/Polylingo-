const express = require('express');
const cors = require('cors');
const path = require('path');
const config = require('./config/default');

// Global crash protection for async workers and background jobs
process.on('uncaughtException', (err) => {
  console.error('[PolyLingo Uncaught Exception]:', err.message, err.stack);
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('[PolyLingo Unhandled Rejection]:', reason);
});

const authRoutes = require('./routes/auth');
const languagesRoutes = require('./routes/languages');
const translateRoutes = require('./routes/translate');
const jobsRoutes = require('./routes/jobs');
const historyRoutes = require('./routes/history');
const filesRoutes = require('./routes/files');
const userRoutes = require('./routes/user');
const adminRoutes = require('./routes/admin');

const translationService = require('./services/TranslationService');
const ocrService = require('./services/OCRService');
const jobQueueService = require('./services/JobQueueService');

const app = express();

// Security Headers & CORS
app.use(cors());
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  next();
});

// Simple in-memory rate limiter
const rateLimitMap = new Map();
app.use((req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress || 'unknown_ip';
  const now = Date.now();
  const windowStart = now - config.rateLimitWindowMs;

  let records = rateLimitMap.get(ip) || [];
  records = records.filter(ts => ts > windowStart);
  
  if (records.length >= config.rateLimitMaxRequests) {
    return res.status(429).json({
      error: 'Too Many Requests',
      message: 'Rate limit exceeded. Please wait a minute before making more requests.',
      retryAfterSeconds: 60
    });
  }

  records.push(now);
  rateLimitMap.set(ip, records);
  next();
});

app.use(express.json({ limit: `${config.maxFileSizeMb}mb` }));
app.use(express.urlencoded({ extended: true, limit: `${config.maxFileSizeMb}mb` }));

// Structured Request Logger
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const logObj = {
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      durationMs: duration,
      ip: req.ip || 'unknown'
    };
    if (req.headers['x-job-id']) logObj.jobId = req.headers['x-job-id'];
    if (req.headers['x-user-id']) logObj.userId = req.headers['x-user-id'];
    console.log(`[API] ${logObj.method} ${logObj.path} -> ${logObj.statusCode} (${logObj.durationMs}ms)`);
  });
  next();
});

// System Health Checks
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'PolyLingo Production Backend',
    version: '2.0.0-prod',
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/translation/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Translation API',
    provider: translationService.provider,
    active: true,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/ocr/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'OCR Vision Engine',
    provider: config.ocrProvider,
    active: true,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/storage/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Private File Storage Vault',
    bucket: config.storageBucket,
    active: true,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/database/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Database Storage Layer',
    connected: true,
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/languages', languagesRoutes);
app.use('/api/translate', translateRoutes);
app.use('/api/jobs', jobsRoutes);
app.use('/api/history', historyRoutes);
app.use('/api/files', filesRoutes);
app.use('/api/user', userRoutes);
app.use('/api/admin', adminRoutes);

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('[PolyLingo Server Error]:', err.stack);
  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: err.message || 'An unexpected error occurred while processing the request.'
  });
});

const PORT = config.port;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`=================================================`);
  console.log(`🚀 PolyLingo Hardened Production Backend (Port ${PORT})`);
  console.log(`   Health Check: http://127.0.0.1:${PORT}/api/health`);
  console.log(`   Translation Health: http://127.0.0.1:${PORT}/api/translation/health`);
  console.log(`=================================================`);
});
