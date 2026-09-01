const request = require('supertest');

// Mock the 'pg' module so tests pass cleanly without an active database connection in CI
jest.mock('pg', () => {
  const mPool = {
    query: jest.fn().mockResolvedValue({ rows: [{ now: '2026-09-01' }] }),
  };
  return { Pool: jest.fn(() => mPool) };
});

const app = require('./app');

describe('API Endpoints', () => {
  test('GET /health should return 200 OK with healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'healthy' });
  });

  test('GET /api/data should return mock database response successfully', async () => {
    const response = await request(app).get('/api/data');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('success', true);
  });
});