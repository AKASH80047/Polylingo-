const crypto = require('crypto');

class JobQueueService {
  constructor() {
    this.jobs = new Map();
  }

  createJob(type, fileName, fileSize, sourceLang, targetLang, totalPages = 1) {
    const jobId = 'job_' + crypto.randomBytes(8).toString('hex');
    const job = {
      id: jobId,
      type: type, // 'pdf', 'image', 'docx', 'xlsx', 'scan'
      fileName: fileName,
      fileSize: fileSize,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      status: 'Uploading',
      progress: 0,
      currentStep: 'Initializing background job...',
      pageCount: totalPages,
      currentPage: 1,
      steps: [
        { label: 'File uploaded & validated', status: 'pending' },
        { label: 'Text extracted & OCR scan', status: 'pending' },
        { label: 'Language detected', status: 'pending' },
        { label: 'Translation completed', status: 'pending' },
        { label: 'Document rebuilt & compressed', status: 'pending' }
      ],
      result: null,
      error: null,
      createdAt: new Date().toISOString(),
      completedAt: null
    };

    this.jobs.set(jobId, job);
    return job;
  }

  getJob(jobId) {
    return this.jobs.get(jobId) || null;
  }

  updateJob(jobId, updates) {
    const job = this.jobs.get(jobId);
    if (!job) return null;

    Object.assign(job, updates);
    this.jobs.set(jobId, job);
    return job;
  }

  updateProgress(jobId, progressPercent, stepMessage, currentPage = 1) {
    const job = this.jobs.get(jobId);
    if (!job) return null;

    job.progress = Math.min(100, Math.max(0, progressPercent));
    job.currentStep = stepMessage;
    job.currentPage = currentPage;

    // Update step checkmarks based on progress threshold
    if (progressPercent >= 20) job.steps[0].status = 'completed';
    if (progressPercent >= 40) job.steps[1].status = 'completed';
    if (progressPercent >= 60) job.steps[2].status = 'completed';
    if (progressPercent >= 80) job.steps[3].status = 'completed';
    if (progressPercent >= 100) {
      job.steps[4].status = 'completed';
      job.status = 'Completed';
      job.completedAt = new Date().toISOString();
    } else {
      job.status = 'Processing';
    }

    this.jobs.set(jobId, job);
    return job;
  }
}

module.exports = new JobQueueService();
