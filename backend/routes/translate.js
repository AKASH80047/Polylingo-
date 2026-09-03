const express = require('express');
const router = express.Router();
const multer = require('multer');
const crypto = require('crypto');
const translationService = require('../services/TranslationService');
const pdfEngineService = require('../services/PdfEngineService');
const docxEngineService = require('../services/DocxEngineService');
const xlsxEngineService = require('../services/XlsxEngineService');
const pptxEngineService = require('../services/PptxEngineService');
const imageEngineService = require('../services/ImageEngineService');
const jobQueueService = require('../services/JobQueueService');

const upload = multer({ limits: { fileSize: 50 * 1024 * 1024 } }); // 50MB limit

// Health check endpoint for translation provider
router.get('/health', (req, res) => {
  return res.json({
    status: 'healthy',
    provider: translationService.provider,
    active: true,
    timestamp: new Date().toISOString()
  });
});

// Live Test endpoint for development validation
router.post('/test', async (req, res) => {
  try {
    const { text = 'Hello, how are you?', source = 'en', target = 'hi' } = req.body;
    const result = await translationService.translateText(text, source, target);
    return res.json({
      status: 'success',
      requestedSource: source,
      requestedTarget: target,
      originalText: text,
      translatedText: result.translatedText,
      provider: result.provider
    });
  } catch (err) {
    return res.status(502).json({
      status: 'failed',
      error: 'Live Translation API test failed',
      details: err.message
    });
  }
});

// Instant Text Translation
router.post('/text', async (req, res) => {
  try {
    const { text, sourceLanguage = 'auto', targetLanguage = 'hi' } = req.body;
    if (!text || text.trim() === '') {
      return res.status(400).json({ error: 'Text content is required' });
    }

    const result = await translationService.translateText(text, sourceLanguage, targetLanguage);
    return res.json(result);
  } catch (err) {
    return res.status(502).json({ error: 'Translation failed', details: err.message });
  }
});

// DIRECT DOCUMENT TRANSLATION ENDPOINT (Core Direct Flow)
// Receives actual file bytes, translates via real Neural Engine, returns translated result
router.post('/document', upload.single('file'), async (req, res) => {
  const startTime = Date.now();
  try {
    const file = req.file;
    if (!file || !file.buffer || file.buffer.length === 0) {
      return res.status(400).json({ success: false, error: 'No valid file uploaded' });
    }

    const {
      sourceLanguage = 'auto',
      targetLanguage = 'hi',
      jobId = 'job_' + Date.now() + '_' + crypto.randomBytes(4).toString('hex'),
      requestId = 'req_' + Date.now()
    } = req.body;

    const fileName = file.originalname || 'document.pdf';
    const mimeType = file.mimetype || 'application/pdf';
    const fileBuffer = file.buffer;
    const contentHash = crypto.createHash('sha256').update(fileBuffer).digest('hex');

    console.log(`[Document Translation Request] File: "${fileName}" (${(fileBuffer.length / (1024 * 1024)).toFixed(2)} MB) | Source: ${sourceLanguage} -> Target: ${targetLanguage} | Job ID: ${jobId}`);

    // Router by file type
    const lowerName = fileName.toLowerCase();
    let resultPayload = {};

    if (lowerName.endsWith('.pdf') || mimeType === 'application/pdf') {
      const pdfRes = await pdfEngineService.processPdf(fileBuffer, sourceLanguage, targetLanguage);
      resultPayload = {
        fileType: 'pdf',
        pageCount: pdfRes.pageCount,
        pages: pdfRes.pages,
        originalSizeMb: pdfRes.originalSizeMb,
        translatedSizeMb: pdfRes.translatedSizeMb,
        pdfBase64: pdfRes.pdfBytes.toString('base64')
      };
    } else if (lowerName.endsWith('.docx') || mimeType.includes('word')) {
      const docxRes = await docxEngineService.processDocx(fileBuffer, sourceLanguage, targetLanguage);
      resultPayload = {
        fileType: 'docx',
        ...docxRes
      };
    } else if (lowerName.endsWith('.xlsx') || mimeType.includes('sheet') || mimeType.includes('excel')) {
      const xlsxRes = await xlsxEngineService.processXlsx(fileBuffer, sourceLanguage, targetLanguage);
      resultPayload = {
        fileType: 'xlsx',
        ...xlsxRes
      };
    } else if (lowerName.endsWith('.pptx') || lowerName.endsWith('.ppt') || mimeType.includes('presentation') || mimeType.includes('powerpoint')) {
      const pptxRes = await pptxEngineService.processPptx(fileBuffer, sourceLanguage, targetLanguage);
      resultPayload = {
        fileType: 'pptx',
        ...pptxRes
      };
    } else if (mimeType.startsWith('image/') || lowerName.endsWith('.png') || lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.webp')) {
      const imgRes = await imageEngineService.processImage(fileBuffer, sourceLanguage, targetLanguage, mimeType);
      resultPayload = {
        fileType: 'image',
        ...imgRes
      };
    } else {
      // Plain text document
      let rawText = fileBuffer.toString('utf8');
      // If binary header detected in unknown format, avoid translating raw binary junk
      if (rawText.startsWith('PK\x03\x04') || fileBuffer.slice(0, 4).toString('hex') === '504b0304') {
        throw new Error('Unsupported compressed binary document format. Please upload PDF, DOCX, XLSX, PPTX, or Image.');
      }
      const textRes = await translationService.translateText(rawText, sourceLanguage, targetLanguage);
      resultPayload = {
        fileType: 'text',
        originalText: rawText,
        translatedText: textRes.translatedText,
        pageCount: 1
      };
    }

    const duration = Date.now() - startTime;
    console.log(`[Document Translation Completed] Job ID: ${jobId} in ${duration}ms`);

    return res.json({
      success: true,
      jobId: jobId,
      requestId: requestId,
      contentHash: contentHash,
      fileName: fileName,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      durationMs: duration,
      timestamp: new Date().toISOString(),
      ...resultPayload
    });
  } catch (err) {
    console.error(`[Document Translation Error]: ${err.message}`);
    return res.status(502).json({
      success: false,
      error: 'Document Translation Failed',
      details: err.message
    });
  }
});

// PDF Translation Async Job Endpoint
router.post('/pdf', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file || !file.buffer || file.buffer.length === 0) {
      return res.status(400).json({ error: 'A valid PDF file upload is required' });
    }
    const { sourceLanguage = 'auto', targetLanguage = 'hi', compression = 'balanced' } = req.body;

    const fileName = file.originalname || 'Document.pdf';
    const fileBuffer = file.buffer;
    const fileSizeMb = parseFloat((fileBuffer.length / (1024 * 1024)).toFixed(2)) || 0.1;

    const job = jobQueueService.createJob('pdf', fileName, fileSizeMb, sourceLanguage, targetLanguage, 1);

    setTimeout(async () => {
      try {
        jobQueueService.updateProgress(job.id, 20, 'File uploaded & validated');
        jobQueueService.updateProgress(job.id, 50, 'Translating document via Live Neural API');
        
        const pdfResult = await pdfEngineService.processPdf(
          fileBuffer,
          sourceLanguage,
          targetLanguage,
          compression,
          (percent, msg) => {
            jobQueueService.updateProgress(job.id, percent, msg);
          }
        );

        jobQueueService.updateJob(job.id, {
          status: 'Completed',
          progress: 100,
          currentStep: 'Translation completed successfully!',
          result: {
            pdfBase64: pdfResult.pdfBytes.toString('base64'),
            pageCount: pdfResult.pageCount,
            originalSizeMb: pdfResult.originalSizeMb,
            translatedSizeMb: pdfResult.translatedSizeMb,
            pages: pdfResult.pages
          }
        });
      } catch (err) {
        jobQueueService.updateJob(job.id, { status: 'Failed', error: err.message });
      }
    }, 50);

    return res.json({
      jobId: job.id,
      status: job.status,
      message: 'PDF translation job queued successfully'
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to initiate PDF translation', details: err.message });
  }
});

module.exports = router;
