import assert from 'node:assert/strict';
import test from 'node:test';
import request from 'supertest';
import { createApp } from '../src/app.js';

test('GET /health returns service metadata', async () => {
  const app = createApp();
  const response = await request(app).get('/health').expect(200);

  assert.equal(response.body.ok, true);
  assert.equal(response.body.service, 'LifeOS X API');
  assert.ok(response.body.timestamp);
});

