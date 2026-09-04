# 🌐 PolyLingo — Universal AI Translation Platform

[![Live Demo](https://img.shields.io/badge/🚀_Live_Demo-Visit_PolyLingo-00B4D8?style=for-the-badge&logo=google-chrome&logoColor=white)](https://akash80047.github.io/Polylingo-/)
[![GitHub Pages](https://img.shields.io/badge/GitHub_Pages-Active-2ea44f?style=for-the-badge&logo=github)](https://akash80047.github.io/Polylingo-/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> **Translate Anything. Anywhere.**  
> High-fidelity Neural Translation for Texts, Multi-Page PDFs, In-Place Google Lens Images (OCR), Word (DOCX), Excel (XLSX), and Camera Documents.

---

## 🔗 Live Demo & Deployment
- **Live Web App**: [https://akash80047.github.io/Polylingo-/](https://akash80047.github.io/Polylingo-/)
- **Backend API**: Deployed via Vercel / Node Server

---

## 🚀 Key Features

- 📝 **Text Translator**: Real-time neural live translation, speech playback (TTS), copy, language auto-detection.
- 📄 **PDF Documents**: 25+ page digital & scanned PDF processing, layout preservation, **downloadable translated PDF**.
- 🖼️ **In-Place Image Translation (Google Lens Style)**: Replaces original text directly inside the image at exact spatial coordinates with dual language selection (Arabic, Hindi, Urdu, English, Asian, etc.).
- 📊 **PowerPoint (PPTX) & Word (DOCX)**: Complete slide & document translation with formatting preservation.
- 📈 **Excel (XLSX)**: Multi-sheet spreadsheet translation with formula (`=SUM`, `=AVERAGE`) retention.
- 📷 **Camera Document Scanner**: Real physical document scanning, auto-alignment, OCR extraction, and neural translation.

---

## 🛠️ Architecture & Tech Stack

- **Frontend**: Flutter 3.x (Web / Desktop / Mobile), Riverpod state management.
- **Backend API**: Node.js, Express, `pdf-lib`, `pdf-parse`, `exceljs`, `mammoth`, `adm-zip`, `tesseract.js`.
- **OCR Engine**: Multi-Script Cloud Vision OCR + Local Tesseract Neural Engine.
- **Translation Provider**: Dual-engine Google Neural & MyMemory Live API pipeline.

---

## 🏃 Getting Started

### Backend Setup
```bash
cd backend
npm install
npm start
```
*Backend server runs on `http://localhost:5000`.*

### Frontend Web Setup
```bash
flutter pub get
flutter run -d chrome
# Or build production web bundle:
flutter build web --release
```

---

## 📜 License
MIT License © 2026 PolyLingo Team
