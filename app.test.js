const request = require('supertest');
const app = require('./app'); // Assuming your express app is exported from app.js

describe('API Endpoints', () => {
  test('GET /health should return 200 OK', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'healthy');
  });

  test('GET /api/data should return data successfully', async () => {
    const response = await request(app).get('/api/data');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body) || typeof response.body === 'object').toBe(true);
  });
});