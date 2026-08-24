import assert from 'node:assert/strict';
import test from 'node:test';
import { getResource, resourceConfig } from '../src/modules/resources/resource.config.js';

test('resource registry exposes requested life modules', () => {
  for (const slug of ['habits', 'expenses', 'study/subjects', 'tasks', 'ai/chat-history', 'dashboard-preferences']) {
    assert.ok(getResource(slug), `${slug} missing`);
  }
  assert.ok(Object.keys(resourceConfig).length >= 30);
});

