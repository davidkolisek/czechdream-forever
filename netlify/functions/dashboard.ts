import type { Handler } from '@netlify/functions'
import { database } from './db'
const empty = { activePlayers: 0, totalLevels: 0, deaths: 0, playedHours: 0, characters: [], events: [] }
export const handler: Handler = async () => {
  if (!database) return { statusCode: 200, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' }, body: JSON.stringify(empty) }
  try { const [stats] = await database`select count(distinct player) as players, coalesce(sum(level),0) as levels, coalesce(sum(deaths),0) as deaths, coalesce(sum(played_hours),0) as hours from characters`; const characters = await database`select name, player as owner, class, level, 'offline' as status from characters order by level desc, name`; const events = await database`select type, coalesce(payload->>'title',type) as title, coalesce(payload->>'detail','') as detail from events order by occurred_at desc limit 20`; return { statusCode: 200, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' }, body: JSON.stringify({ activePlayers:Number(stats.players), totalLevels:Number(stats.levels), deaths:Number(stats.deaths), playedHours:Number(stats.hours), characters, events }) } } catch (error) { console.error(error); return { statusCode: 200, body: JSON.stringify(empty) } }
}
