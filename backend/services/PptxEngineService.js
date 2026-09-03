const AdmZip = require('adm-zip');
const translationService = require('./TranslationService');

class PptxEngineService {
  /**
   * Process and translate a PowerPoint PPTX presentation file
   * @param {Buffer} buffer - PPTX binary buffer
   * @param {string} sourceLang - Source language code or 'auto'
   * @param {string} targetLang - Target language code
   * @returns {Promise<Object>}
   */
  async processPptx(buffer, sourceLang = 'auto', targetLang = 'hi') {
    const zip = new AdmZip(buffer);
    const zipEntries = zip.getEntries();
    
    const slideEntries = zipEntries.filter(e => e.entryName.startsWith('ppt/slides/slide') && e.entryName.endsWith('.xml'));
    console.log(`[PPTX] Found ${slideEntries.length} slide(s) in PowerPoint presentation`);

    const slideSummaries = [];
    const allExtractedLines = [];
    const textReplacementMap = new Map();

    for (let i = 0; i < slideEntries.length; i++) {
      const entry = slideEntries[i];
      const xmlContent = zip.readAsText(entry);
      
      // Match all text nodes <a:t>...</a:t>
      const textMatches = xmlContent.match(/<a:t(?:\s+[^>]*)?>([\s\S]*?)<\/a:t>/g) || [];
      const slideTexts = [];

      for (const tag of textMatches) {
        const textContent = tag.replace(/<[^>]+>/g, '').trim();
        if (textContent.length > 0 && !textContent.match(/^[\d\s.,\-+]+$/)) {
          slideTexts.push(textContent);
          if (!textReplacementMap.has(textContent)) {
            textReplacementMap.set(textContent, '');
          }
        }
      }

      allExtractedLines.push(`--- Slide ${i + 1} ---`);
      allExtractedLines.push(...slideTexts);

      slideSummaries.push({
        slideNumber: i + 1,
        texts: slideTexts
      });
    }

    // Translate unique text items in parallel batches
    const uniqueKeys = Array.from(textReplacementMap.keys());
    console.log(`[PPTX] Translating ${uniqueKeys.length} unique text phrase(s) across ${slideEntries.length} slides into ${targetLang}...`);

    const BATCH_SIZE = 8;
    for (let i = 0; i < uniqueKeys.length; i += BATCH_SIZE) {
      const batch = uniqueKeys.slice(i, i + BATCH_SIZE);
      await Promise.all(batch.map(async (text) => {
        try {
          const res = await translationService.translateText(text, sourceLang, targetLang);
          textReplacementMap.set(text, res.translatedText || text);
        } catch (e) {
          textReplacementMap.set(text, text);
        }
      }));
    }

    // Reconstruct translated slides in PPTX zip
    for (const entry of slideEntries) {
      let xmlContent = zip.readAsText(entry);
      xmlContent = xmlContent.replace(/<a:t(?:\s+[^>]*)?>([\s\S]*?)<\/a:t>/g, (match, textVal) => {
        const trimmed = (textVal || '').trim();
        const translated = textReplacementMap.get(trimmed);
        if (translated) {
          return `<a:t>${translated}</a:t>`;
        }
        return match;
      });
      zip.updateFile(entry.entryName, Buffer.from(xmlContent, 'utf8'));
    }

    const translatedPptxBuffer = zip.toBuffer();
    const fullOriginal = allExtractedLines.join('\n');
    const fullTranslated = allExtractedLines.map(line => {
      if (line.startsWith('--- Slide')) return line;
      return textReplacementMap.get(line) || line;
    }).join('\n');

    return {
      format: 'pptx',
      slideCount: slideEntries.length,
      originalText: fullOriginal,
      translatedText: fullTranslated,
      pptxBase64: translatedPptxBuffer.toString('base64'),
      targetLanguage: targetLang
    };
  }
}

module.exports = new PptxEngineService();
