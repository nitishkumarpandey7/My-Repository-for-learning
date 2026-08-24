import assert from 'node:assert/strict';
import test from 'node:test';
import { runAi } from '../src/modules/ai/ai.service.js';

test('AI local fallback returns coaching text without paid provider keys', async () => {
  const response = await runAi({
    provider: 'local',
    messages: [{ role: 'user', content: 'I keep procrastinating on exam revision.' }]
  });

  assert.equal(response.provider, 'local');
  assert.match(response.content, /LifeOS plan/);
});

