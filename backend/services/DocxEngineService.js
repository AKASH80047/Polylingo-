const mammoth = require('mammoth');
const translationService = require('./TranslationService');

class DocxEngineService {
  async processDocx(buffer, sourceLang, targetLang) {
    let extractedText = '';
    let htmlOutput = '';
    try {
      const result = await mammoth.extractRawText({ buffer: buffer });
      extractedText = result.value || '';
      const htmlResult = await mammoth.convertToHtml({ buffer: buffer });
      htmlOutput = htmlResult.value || '';
    } catch (e) {
      console.warn('[DocxEngine] Warning reading docx:', e.message);
      extractedText = buffer.toString('utf8');
    }

    if (!extractedText || extractedText.trim().length === 0) {
      extractedText = 'Document parsed without text contents.';
    }

    const { translatedText, detectedSourceLanguage } = await translationService.translateText(
      extractedText,
      sourceLang,
      targetLang
    );

    const paragraphs = extractedText.split('\n').map(p => p.trim()).filter(Boolean);
    const translatedParagraphs = translatedText.split('\n').map(p => p.trim()).filter(Boolean);

    return {
      originalText: extractedText,
      translatedText: translatedText,
      detectedSourceLanguage: detectedSourceLanguage,
      paragraphCount: paragraphs.length || 1,
      paragraphs: paragraphs,
      translatedParagraphs: translatedParagraphs,
      format: 'docx'
    };
  }
}

module.exports = new DocxEngineService();
