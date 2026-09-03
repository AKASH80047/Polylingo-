const ocrService = require('./OCRService');
const translationService = require('./TranslationService');

class ImageEngineService {
  /**
   * Process and translate an uploaded image
   * @param {Buffer} buffer - Image buffer
   * @param {string} sourceLang - Source language code or 'auto'
   * @param {string} targetLang - Target language code
   * @param {string} mimeType - Image mime type
   */
  async processImage(buffer, sourceLang = 'auto', targetLang = 'hi', mimeType = 'image/png') {
    // 1. Run real OCR extraction to detect text and bounding boxes
    const ocrResult = await ocrService.extractTextFromBuffer(buffer, mimeType, { sourceLanguage: sourceLang });
    
    const detectedSourceLang = ocrResult.detectedSourceLanguage || sourceLang || 'auto';
    const originalText = ocrResult.fullText || '';
    
    // 2. Translate extracted text regions
    const translatedRegions = [];
    for (const region of ocrResult.regions) {
      if (region.text && region.text.trim().length > 0) {
        try {
          const trans = await translationService.translateText(region.text, detectedSourceLang, targetLang);
          translatedRegions.push({
            ...region,
            translatedText: trans.translatedText || region.text
          });
        } catch (e) {
          translatedRegions.push({
            ...region,
            translatedText: region.text
          });
        }
      }
    }

    // 3. Translate full text
    let fullTranslated = '';
    if (originalText.trim().length > 0) {
      try {
        const fullTransRes = await translationService.translateText(originalText, detectedSourceLang, targetLang);
        fullTranslated = fullTransRes.translatedText || '';
      } catch (err) {
        fullTranslated = translatedRegions.map(r => r.translatedText).join('\n');
      }
    }

    return {
      originalText: originalText,
      translatedText: fullTranslated,
      detectedSourceLanguage: detectedSourceLang,
      targetLanguage: targetLang,
      regions: translatedRegions,
      confidence: ocrResult.confidence,
      imageBase64: buffer.toString('base64'),
      mimeType: mimeType
    };
  }
}

module.exports = new ImageEngineService();
