module.exports = {
  port: process.env.PORT || 5000,
  translationProvider: process.env.TRANSLATION_PROVIDER || 'google-neural-live',
  translationApiUrl: process.env.TRANSLATION_API_URL || 'https://translate.googleapis.com',
  translationApiKey: process.env.TRANSLATION_API_KEY || '',
  ocrProvider: process.env.OCR_PROVIDER || 'neural-vision-ocr',
  ocrApiUrl: process.env.OCR_API_URL || '',
  ocrApiKey: process.env.OCR_API_KEY || '',
  databaseUrl: process.env.DATABASE_URL || 'sqlite://polylingo_prod.db',
  storageBucket: process.env.STORAGE_BUCKET || 'polylingo-secure-vault',
  jwtSecret: process.env.JWT_SECRET || 'polylingo_secure_jwt_production_key_2026',
  
  // Production Configurable Limits
  maxFileSizeMb: parseInt(process.env.MAX_FILE_SIZE_MB || '50', 10),
  maxPdfPages: parseInt(process.env.MAX_PDF_PAGES || '100', 10),
  maxImageSizeMb: parseInt(process.env.MAX_IMAGE_SIZE_MB || '25', 10),
  maxDocumentSizeMb: parseInt(process.env.MAX_DOCUMENT_SIZE_MB || '50', 10),
  
  // Security & Rate Limiting
  rateLimitWindowMs: 60 * 1000, // 1 minute
  rateLimitMaxRequests: 120,    // 120 requests/min
  tempDir: './temp_processing'
};
