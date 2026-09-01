const express = require('express');
const { Pool } = require('pg');
const app = express();

// The environment variables will be injected via your CI/CD or ECS task definition
const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: 5432,
});

// Health check endpoint for your AWS Load Balancer
app.get('/health', (req, res) => res.status(200).send('OK'));

// Database connection test endpoint
app.get('/api/data', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server running on port ${port}`));