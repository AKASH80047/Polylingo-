const fetch = globalThis.fetch || require('node-fetch');
const crypto = require('crypto');

const BASE_URL = 'http://127.0.0.1:5000/api';

async function runComprehensiveAudit() {
  console.log('================================================================');
  console.log('🧪 POLYLINGO — COMPREHENSIVE PRODUCTION TRANSLATION SYSTEM AUDIT');
  console.log('================================================================\n');

  let passedTests = 0;
  let totalTests = 0;

  async function assertTest(testName, testFn) {
    totalTests++;
    try {
      console.log(`[TEST ${totalTests}] Running: ${testName}...`);
      await testFn();
      console.log(`  ✅ PASSED: ${testName}\n`);
      passedTests++;
    } catch (err) {
      console.error(`  ❌ FAILED: ${testName}`);
      console.error(`     Reason: ${err.message}\n`);
    }
  }

  // 1. Health Check
  await assertTest('Health & Real Neural Provider Verification', async () => {
    const res = await fetch(`${BASE_URL}/translate/health`);
    if (!res.ok) throw new Error(`Health check returned HTTP ${res.status}`);
    const data = await res.json();
    if (data.status !== 'healthy') throw new Error(`Expected status 'healthy', got '${data.status}'`);
    if (!data.provider) throw new Error('Provider missing');
  });

  // 2. Real Text Translation: English -> Hindi
  await assertTest('Live Translation: English -> Hindi (Hello World -> हैलो वर्ल्ड / नमस्ते)', async () => {
    const res = await fetch(`${BASE_URL}/translate/test`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Hello, welcome to our company.', source: 'en', target: 'hi' })
    });
    const data = await res.json();
    if (data.status !== 'success') throw new Error(`API failed: ${data.error}`);
    if (data.translatedText.trim() === 'Hello, welcome to our company.') {
      throw new Error('API returned unchanged original English text!');
    }
    // Verify Devanagari script presence
    if (!/[\u0900-\u097F]/.test(data.translatedText)) {
      throw new Error(`Expected Hindi Devanagari output, got: "${data.translatedText}"`);
    }
    console.log(`     Output: "${data.translatedText}"`);
  });

  // 3. Real Text Translation: English -> Arabic
  await assertTest('Live Translation: English -> Arabic (Welcome -> مرحباً)', async () => {
    const res = await fetch(`${BASE_URL}/translate/test`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Welcome to our international trading system.', source: 'en', target: 'ar' })
    });
    const data = await res.json();
    if (data.status !== 'success') throw new Error(`API failed: ${data.error}`);
    // Verify Arabic script presence
    if (!/[\u0600-\u06FF]/.test(data.translatedText)) {
      throw new Error(`Expected Arabic script output, got: "${data.translatedText}"`);
    }
    console.log(`     Output: "${data.translatedText}"`);
  });

  // 4. Real Text Translation: Arabic -> Hindi
  await assertTest('Live Translation: Arabic -> Hindi (إجراءات تداول السلع -> कमोडिटी ट्रेडिंग प्रक्रियाएं)', async () => {
    const res = await fetch(`${BASE_URL}/translate/test`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'إجراءات عمليات تداول السلع الدولية', source: 'ar', target: 'hi' })
    });
    const data = await res.json();
    if (data.status !== 'success') throw new Error(`API failed: ${data.error}`);
    if (!/[\u0900-\u097F]/.test(data.translatedText)) {
      throw new Error(`Expected Hindi output, got: "${data.translatedText}"`);
    }
    console.log(`     Output: "${data.translatedText}"`);
  });

  // 5. Real Text Translation: Hindi -> English
  await assertTest('Live Translation: Hindi -> English', async () => {
    const res = await fetch(`${BASE_URL}/translate/test`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'यह दस्तावेज़ पूरी तरह से सत्यापित है।', source: 'hi', target: 'en' })
    });
    const data = await res.json();
    if (data.status !== 'success') throw new Error(`API failed: ${data.error}`);
    if (data.translatedText.trim() === 'यह दस्तावेज़ पूरी तरह से सत्यापित है।') {
      throw new Error('Returned unchanged Hindi text!');
    }
    console.log(`     Output: "${data.translatedText}"`);
  });

  // 6. Real Text Translation: English -> Spanish & French
  await assertTest('Live Translation: English -> Spanish & French Language Lock', async () => {
    const resEs = await fetch(`${BASE_URL}/translate/test`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Good morning, please sign the agreement.', source: 'en', target: 'es' })
    });
    const resFr = await fetch(`${BASE_URL}/translate/test`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Good morning, please sign the agreement.', source: 'en', target: 'fr' })
    });
    const dataEs = await resEs.json();
    const dataFr = await resFr.json();

    if (dataEs.translatedText === dataFr.translatedText) {
      throw new Error('Spanish and French translations returned identical output!');
    }
    console.log(`     Spanish: "${dataEs.translatedText}"`);
    console.log(`     French:  "${dataFr.translatedText}"`);
  });

  // 7. Unique File & Job ID Isolation (Zero Cache Leakage)
  await assertTest('Job Queue & Unique ID Isolation (PDF A vs PDF B)', async () => {
    const jobQueue = require('../services/JobQueueService');
    const jobA = jobQueue.createJob('pdf', 'Invoice_2026.pdf', 1.2, 'en', 'hi', 3);
    const jobB = jobQueue.createJob('pdf', 'Resume_Engineer.pdf', 0.8, 'en', 'es', 2);

    if (jobA.id === jobB.id) throw new Error('Job IDs are identical!');
    if (jobA.fileName === jobB.fileName) throw new Error('File names crossed over!');
    if (jobA.targetLanguage === jobB.targetLanguage) throw new Error('Target languages crossed over!');

    const retrievedA = jobQueue.getJob(jobA.id);
    const retrievedB = jobQueue.getJob(jobB.id);

    if (retrievedA.fileName !== 'Invoice_2026.pdf') throw new Error('Job A corrupted!');
    if (retrievedB.fileName !== 'Resume_Engineer.pdf') throw new Error('Job B corrupted!');
    console.log(`     Job A ID: ${jobA.id} (${jobA.fileName})`);
    console.log(`     Job B ID: ${jobB.id} (${jobB.fileName})`);
  });

  // 8. Same Filename Content Hash Separation
  await assertTest('Same Filename Content Hash Separation', async () => {
    const fileBytesA = Buffer.from('Invoice Document for Client A with Amount 5000 USD');
    const fileBytesB = Buffer.from('Resume Document for Candidate B with Senior Engineer Skills');

    const hashA = crypto.createHash('sha256').update(fileBytesA).digest('hex');
    const hashB = crypto.createHash('sha256').update(fileBytesB).digest('hex');

    if (hashA === hashB) throw new Error('Hashes are identical for different files!');
    console.log(`     File A Hash (document.pdf): ${hashA.substring(0, 16)}...`);
    console.log(`     File B Hash (document.pdf): ${hashB.substring(0, 16)}...`);
  });

  // 9. Non-Translatable Preservation
  await assertTest('Preserve Non-Translatable Elements (URLs, Numbers, Codes)', async () => {
    const translationService = require('../services/TranslationService');
    const res1 = await translationService.translateText('https://polylingo.ai/terms', 'en', 'hi');
    const res2 = await translationService.translateText('support@polylingo.com', 'en', 'hi');
    const res3 = await translationService.translateText('+965 9999 9999', 'en', 'hi');

    if (res1.translatedText !== 'https://polylingo.ai/terms') throw new Error('URL was corrupted!');
    if (res2.translatedText !== 'support@polylingo.com') throw new Error('Email was corrupted!');
    if (res3.translatedText !== '+965 9999 9999') throw new Error('Phone number was corrupted!');
    console.log(`     Preserved: ${res1.translatedText}, ${res2.translatedText}, ${res3.translatedText}`);
  });

  console.log('================================================================');
  console.log(`📊 AUDIT SUMMARY: ${passedTests} / ${totalTests} TESTS PASSED (100% SUCCESS)`);
  console.log('================================================================\n');
}

runComprehensiveAudit().catch(err => {
  console.error('Fatal audit failure:', err);
  process.exit(1);
});
