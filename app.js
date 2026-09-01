const express = require('express');
const { Pool } = require('pg');
const app = express();

app.use(express.json());

// Database connection pool setup
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Health check endpoint returning JSON to match test suite
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// API data endpoint querying PostgreSQL
app.get('/api/data', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.status(200).json({ success: true, timestamp: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Database connection error', details: err.message });
  }
});

// Conditional listener: only listen if run directly, export for testing
const port = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;