const express = require('express');
const cors = require('cors');

const materialsRouter = require('./routes/materials');
const categoriesRouter = require('./routes/categories');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const ms = Date.now() - start;
      process.stdout.write(`${req.method} ${req.originalUrl} -> ${res.statusCode} (${ms}ms)\n`);
    });
    next();
  });

  app.get('/health', (req, res) => res.json({ ok: true }));

  app.use('/api/materials', materialsRouter);
  app.use('/api/categories', categoriesRouter);

  app.use((err, req, res, next) => {
    const status = err.statusCode || 500;

    process.stderr.write('--- Request Error ---\n');
    process.stderr.write(`${req.method} ${req.originalUrl}\n`);
    if (err && err.message) process.stderr.write(`${err.message}\n`);
    if (err && err.stack) process.stderr.write(`${err.stack}\n`);
    process.stderr.write('---------------------\n');

    res.status(status).json({
      error: err.message || 'Internal Server Error',
    });
  });

  return app;
}

module.exports = { createApp };
