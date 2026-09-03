const ExcelJS = require('exceljs');
const translationService = require('./TranslationService');

class XlsxEngineService {
  async processXlsx(buffer, sourceLang = 'auto', targetLang = 'hi') {
    const workbook = new ExcelJS.Workbook();
    
    try {
      await workbook.xlsx.load(buffer);
    } catch (e) {
      console.warn('[XlsxEngine] Error loading workbook:', e.message);
      const sheet = workbook.addWorksheet('Sheet1');
      sheet.addRow(['Title', 'PolyLingo Excel Translation']);
    }

    const sheetSummaries = [];
    let totalCellsTranslated = 0;
    let formulasPreservedCount = 0;
    const translationTasks = [];
    const previewRows = [];

    for (const worksheet of workbook.worksheets) {
      worksheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
        row.eachCell({ includeEmpty: false }, (cell, colNumber) => {
          // Rule: NEVER translate formulas
          if (cell.formula || (typeof cell.value === 'string' && cell.value.trim().startsWith('='))) {
            formulasPreservedCount++;
            return;
          }

          if (typeof cell.value === 'string' && cell.value.trim().length > 0 && isNaN(Number(cell.value))) {
            const originalVal = cell.value;
            translationTasks.push(async () => {
              try {
                const translated = await translationService.translateText(originalVal, sourceLang, targetLang);
                cell.value = translated.translatedText;
                totalCellsTranslated++;
                if (previewRows.length < 20) {
                  previewRows.push({
                    sheet: worksheet.name,
                    row: rowNumber,
                    col: colNumber,
                    original: originalVal,
                    translated: translated.translatedText
                  });
                }
              } catch (e) {
                console.warn('[XlsxEngine] Cell translate notice:', e.message);
              }
            });
          }
        });
      });

      sheetSummaries.push({
        name: worksheet.name,
        rowCount: worksheet.rowCount,
        columnCount: worksheet.columnCount
      });
    }

    // Execute translation tasks in batches of 10
    const BATCH_SIZE = 10;
    for (let i = 0; i < translationTasks.length; i += BATCH_SIZE) {
      const batch = translationTasks.slice(i, i + BATCH_SIZE);
      await Promise.all(batch.map(fn => fn()));
    }

    const outputBuffer = await workbook.xlsx.writeBuffer();

    return {
      xlsxBase64: Buffer.from(outputBuffer).toString('base64'),
      sheets: sheetSummaries,
      previewRows: previewRows,
      totalCellsTranslated: totalCellsTranslated,
      formulasPreservedCount: formulasPreservedCount,
      targetLanguage: targetLang
    };
  }
}

module.exports = new XlsxEngineService();
