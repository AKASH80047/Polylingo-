const fetch = globalThis.fetch || require('node-fetch');

class TranslationService {
  constructor() {
    this.provider = 'Google Neural Live Engine';
  }

  detectLanguage(text) {
    if (!text || typeof text !== 'string') return 'en';
    const trimmed = text.trim();
    if (!trimmed) return 'en';

    if (/[\u0600-\u06FF]/.test(trimmed)) return 'ar';
    if (/[\u0900-\u097F]/.test(trimmed)) return 'hi';
    if (/[\u4E00-\u9FFF]/.test(trimmed)) return 'zh';
    if (/[\u3040-\u30FF]/.test(trimmed)) return 'ja';
    if (/[\u0400-\u04FF]/.test(trimmed)) return 'ru';
    if (/[éèêàâçôùûïë]/i.test(trimmed)) return 'fr';
    if (/[äöüß]/i.test(trimmed)) return 'de';
    if (/[ñáéíóú]/i.test(trimmed)) return 'es';

    return 'en';
  }

  async translateText(text, sourceLang = 'auto', targetLang = 'hi') {
    if (!text || text.trim() === '') {
      return { translatedText: '', detectedSourceLanguage: sourceLang === 'auto' ? 'en' : sourceLang };
    }

    const detectedLang = sourceLang === 'auto' ? this.detectLanguage(text) : sourceLang;
    
    // Non-translatable checks: pure numbers, URLs, emails
    if (/^[\d\s.,\-+/()$%#@]+$/.test(text.trim()) || /^https?:\/\//i.test(text.trim()) || /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/i.test(text.trim())) {
      return {
        translatedText: text,
        detectedSourceLanguage: detectedLang,
        provider: 'Preserved Non-Translatable Element',
        timestamp: new Date().toISOString()
      };
    }

    console.log(`[Translation Request] Source: ${detectedLang} | Target: ${targetLang} | Input: "${text.substring(0, 80)}"`);

    // 1. Primary: Live Google Neural Translate API
    try {
      const gtxUrl = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${detectedLang}&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
      const res = await fetch(gtxUrl);
      if (res.ok) {
        const data = await res.json();
        if (data && data[0] && Array.isArray(data[0])) {
          const translatedParts = data[0].map(part => (part && part[0]) ? part[0] : '').filter(Boolean);
          const fullTranslated = translatedParts.join('');
          if (fullTranslated && fullTranslated.trim().length > 0) {
            console.log(`[Translation Success] Provider: Google Neural Live | Output: "${fullTranslated.substring(0, 80)}"`);
            return {
              translatedText: fullTranslated,
              detectedSourceLanguage: detectedLang,
              provider: 'Google Neural Live Engine',
              timestamp: new Date().toISOString()
            };
          }
        }
      }
    } catch (err) {
      console.warn(`[Translation Warning] Primary live API failed: ${err.message}. Trying secondary provider...`);
    }

    // 2. Secondary: Live MyMemory Translation API
    try {
      const myMemoryUrl = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${detectedLang}|${targetLang}`;
      const mmRes = await fetch(myMemoryUrl);
      if (mmRes.ok) {
        const data = await mmRes.json();
        const trans = data.responseData && data.responseData.translatedText;
        if (trans && trans.trim().length > 0 && !trans.includes('MYMEMORY WARNING')) {
          console.log(`[Translation Success] Provider: MyMemory Live | Output: "${trans.substring(0, 80)}"`);
          return {
            translatedText: trans,
            detectedSourceLanguage: detectedLang,
            provider: 'MyMemory Live Engine',
            timestamp: new Date().toISOString()
          };
        }
      }
    } catch (err) {
      console.warn(`[Translation Warning] Secondary live API failed: ${err.message}`);
    }

    // 3. If ALL real APIs fail, do NOT return fake/original text. Throw explicit failure.
    console.error(`[Translation Critical Error] All translation providers failed for: "${text.substring(0, 60)}"`);
    throw new Error(`Translation service unavailable. Could not translate text from "${detectedLang}" to "${targetLang}". Please verify network connectivity.`);
  }
}

module.exports = new TranslationService();
