const { PDFDocument, rgb, StandardFonts, degrees } = require('pdf-lib');
const pdfEngineService = require('../services/PdfEngineService');
const translationService = require('../services/TranslationService');

async function createSamplePdf(type = 'multipage') {
  const pdfDoc = await PDFDocument.create();
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  if (type === 'multipage') {
    // 3 Page Document
    const p1 = pdfDoc.addPage([595.28, 841.89]); // A4 Portrait
    p1.drawText('Global Technical Services Agreement', { x: 50, y: 780, size: 16, font: fontBold });
    p1.drawText('This agreement is entered into between Acme Corporation and Beta Systems.', { x: 50, y: 740, size: 11, font });
    p1.drawText('Effective Date: 2026-08-25', { x: 50, y: 710, size: 10, font });
    p1.drawText('Contract Value: $150,000 USD', { x: 50, y: 680, size: 10, font });

    const p2 = pdfDoc.addPage([595.28, 841.89]);
    p2.drawText('Section 2: Scope of Work and Deliverables', { x: 50, y: 780, size: 14, font: fontBold });
    p2.drawText('The provider shall deliver real-time document analysis and AI translation pipelines.', { x: 50, y: 740, size: 11, font });
    p2.drawText('Milestone 1: Dynamic text extraction and OCR engine integration.', { x: 50, y: 710, size: 10, font });

    const p3 = pdfDoc.addPage([595.28, 841.89]);
    p3.drawText('Section 3: Signatures and Authorization', { x: 50, y: 780, size: 14, font: fontBold });
    p3.drawText('Authorized Signatory: John Doe, Chief Executive Officer', { x: 50, y: 740, size: 11, font });
    p3.drawText('Status: Approved and Legally Validated', { x: 50, y: 710, size: 10, font });
  } else if (type === 'invoice') {
    // Invoice Layout
    const p1 = pdfDoc.addPage([595.28, 841.89]);
    p1.drawText('COMMERCIAL INVOICE', { x: 50, y: 800, size: 18, font: fontBold });
    p1.drawText('Invoice Number: INV-2026-9042', { x: 50, y: 760, size: 10, font });
    p1.drawText('Billing To: Zenith International Logistics', { x: 50, y: 740, size: 10, font });
    p1.drawText('Item Description: High Performance Cloud Storage 10TB', { x: 50, y: 700, size: 10, font });
    p1.drawText('Unit Price: $450.00', { x: 50, y: 680, size: 10, font });
    p1.drawText('Subtotal: $4,500.00', { x: 50, y: 660, size: 10, font });
    p1.drawText('Total Amount Due: $4,850.00', { x: 50, y: 630, size: 11, font: fontBold });
  } else if (type === 'landscape') {
    // Landscape Presentation Slide [841.89 x 595.28]
    const p1 = pdfDoc.addPage([841.89, 595.28]);
    p1.drawText('Quarterly Business Strategy Presentation', { x: 60, y: 520, size: 20, font: fontBold });
    p1.drawText('Overview of global expansion metrics and customer satisfaction ratings.', { x: 60, y: 470, size: 12, font });
    p1.drawText('Key Metric: 99.8% System Uptime Across All Regions', { x: 60, y: 430, size: 11, font });
  } else if (type === 'scanned_empty_text') {
    // Empty text / image container (simulating scanned page)
    const p1 = pdfDoc.addPage([595.28, 841.89]);
    // Draw only a vector rectangle without standard text characters
    p1.drawRectangle({ x: 40, y: 40, width: 515, height: 760, borderColor: rgb(0.2, 0.2, 0.2), borderWidth: 2 });
  }

  const pdfBytes = await pdfDoc.save({ useObjectStreams: false });
  return Buffer.from(pdfBytes);
}

async function runUniversalPdfTests() {
  console.log(`================================================================`);
  console.log(`🧪 RUNNING UNIVERSAL PDF TRANSLATION PIPELINE TESTS`);
  console.log(`================================================================\n`);

  let passCount = 0;
  let failCount = 0;

  async function test(name, fn) {
    try {
      console.log(`▶ [TEST] ${name}`);
      await fn();
      console.log(`✔ [PASS] ${name}\n`);
      passCount++;
    } catch (err) {
      console.error(`❌ [FAIL] ${name}: ${err.message}\n`);
      failCount++;
    }
  }

  // TEST 1: Multi-page document test (3 pages, preserving count and order)
  await test('Multi-page (3 Pages) Document Extraction & Translation', async () => {
    const buffer = await createSamplePdf('multipage');
    const res = await pdfEngineService.processPdf(buffer, 'en', 'hi');

    if (res.pageCount !== 3) throw new Error(`Expected 3 pages, got ${res.pageCount}`);
    if (res.pages.length !== 3) throw new Error(`Expected 3 page structures, got ${res.pages.length}`);
    if (!res.pdfBytes || res.pdfBytes.length < 100) throw new Error('Invalid output PDF bytes');
    
    // Check that pages are ordered 1, 2, 3
    if (res.pages[0].page !== 1 || res.pages[1].page !== 2 || res.pages[2].page !== 3) {
      throw new Error('Page order was not preserved');
    }

    // Verify translated content returned
    const p1Trans = res.pages[0].translatedText;
    console.log(`   Page 1 Translated Preview: "${p1Trans.substring(0, 70)}..."`);
    if (!p1Trans || p1Trans.trim().length === 0) throw new Error('Page 1 translated text is empty');
  });

  // TEST 2: Commercial Invoice Structure Test
  await test('Commercial Invoice with Key-Value and Structured Fields', async () => {
    const buffer = await createSamplePdf('invoice');
    const res = await pdfEngineService.processPdf(buffer, 'en', 'es');

    if (res.pageCount !== 1) throw new Error(`Expected 1 page, got ${res.pageCount}`);
    const blocks = res.pages[0].blocks;
    if (!blocks || blocks.length < 4) throw new Error(`Expected >= 4 structured blocks, got ${blocks.length}`);

    console.log(`   Invoice Translated Blocks: ${blocks.length}`);
    blocks.forEach(b => {
      console.log(`     - [${b.id}] Orig: "${b.original}" -> Trans: "${b.translated}"`);
    });
  });

  // TEST 3: Landscape PDF Dimensions Preservation Test
  await test('Landscape Custom Dimensions Preservation', async () => {
    const buffer = await createSamplePdf('landscape');
    const res = await pdfEngineService.processPdf(buffer, 'en', 'fr');

    const page1 = res.pages[0];
    if (page1.orientation !== 'landscape') throw new Error(`Expected landscape, got ${page1.orientation}`);
    if (page1.width <= page1.height) throw new Error(`Expected width > height for landscape page`);
    console.log(`   Preserved Dimensions: ${page1.width} x ${page1.height} (${page1.orientation})`);
  });

  // TEST 4: Scanned / Image-Only PDF Route to OCR
  await test('Scanned / Non-selectable Text Page Routed to OCR', async () => {
    const buffer = await createSamplePdf('scanned_empty_text');
    const res = await pdfEngineService.processPdf(buffer, 'en', 'de');

    const page1 = res.pages[0];
    if (page1.pageType !== 'SCANNED_PAGE' && !page1.ocrRequired) {
      throw new Error(`Expected SCANNED_PAGE classification, got ${page1.pageType}`);
    }
    console.log(`   Successfully Classified: ${page1.pageType} (OCR Required: ${page1.ocrRequired})`);
  });

  // TEST 5: Corrupted PDF Rejection Test
  await test('Corrupted / Invalid PDF Rejection with Explicit Error', async () => {
    const corruptBuffer = Buffer.from('This is not a PDF at all, just plain invalid corrupt bytes.');
    let threw = false;
    try {
      await pdfEngineService.processPdf(corruptBuffer, 'en', 'hi');
    } catch (err) {
      threw = true;
      if (!err.message.includes('valid PDF') && !err.message.includes('could not be read')) {
        throw new Error(`Expected invalid PDF error message, got: ${err.message}`);
      }
      console.log(`   Caught Expected Error: "${err.message}"`);
    }
    if (!threw) throw new Error('Expected processPdf to throw error for corrupt PDF');
  });

  console.log(`================================================================`);
  console.log(`📊 TEST RESULTS: ${passCount} PASSED, ${failCount} FAILED`);
  console.log(`================================================================`);

  if (failCount > 0) {
    process.exit(1);
  }
}

runUniversalPdfTests();
