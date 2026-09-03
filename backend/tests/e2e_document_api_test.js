const { PDFDocument, StandardFonts } = require('pdf-lib');
const pdfEngineService = require('../services/PdfEngineService');

async function createTestPdf() {
  const doc = await PDFDocument.create();
  const font = await doc.embedFont(StandardFonts.HelveticaBold);
  const p1 = doc.addPage([595.28, 841.89]);
  p1.drawText('CONFIDENTIAL NON-DISCLOSURE AGREEMENT', { x: 50, y: 780, size: 14, font });
  p1.drawText('Party A: PolyLingo Global Technologies Inc.', { x: 50, y: 740, size: 10, font });
  p1.drawText('Party B: Vertex Enterprise Solutions', { x: 50, y: 720, size: 10, font });
  p1.drawText('Term: Five (5) Years from Execution Date', { x: 50, y: 700, size: 10, font });
  const bytes = await doc.save();
  return Buffer.from(bytes);
}

async function testDocumentApi() {
  console.log('Testing End-to-End Document Translation API...');
  const pdfBuffer = await createTestPdf();

  const result = await pdfEngineService.processPdf(pdfBuffer, 'en', 'es');
  console.log('Result Page Count:', result.pageCount);
  console.log('Result Pages Length:', result.pages.length);
  console.log('Page 1 Type:', result.pages[0].pageType);
  console.log('Page 1 Translated Blocks:', result.pages[0].blocks.map(b => b.translated));
  console.log('Reconstructed PDF Base64 length:', result.pdfBytes.toString('base64').length);

  if (result.pageCount === 1 && result.pages.length === 1 && result.pdfBytes.length > 0) {
    console.log('✔ E2E PDF Pipeline Verification Successful!');
    process.exit(0);
  } else {
    console.error('❌ E2E PDF Pipeline Verification Failed!');
    process.exit(1);
  }
}

testDocumentApi();
