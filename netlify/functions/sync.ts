import type { Config, Handler } from '@netlify/functions'
type SyncPayload = { character?: Record<string, unknown>; stats?: Record<string, unknown>; events?: unknown[] }
export const handler: Handler = async (event) => {
  if (event.httpMethod !== 'POST') return { statusCode: 405, body: JSON.stringify({ error: 'POST required' }) }
  let payload: SyncPayload
  try { payload = JSON.parse(event.body || '{}') } catch { return { statusCode: 400, body: JSON.stringify({ error: 'Invalid JSON' }) } }
  return { statusCode: 200, headers: { 'content-type': 'application/json' }, body: JSON.stringify({ ok: true, acceptedEvents: payload.events?.length || 0, receivedAt: new Date().toISOString() }) }
}
export const config: Config = { path: '/api/sync' }
