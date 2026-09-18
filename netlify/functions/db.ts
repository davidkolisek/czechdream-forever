import { neon } from '@neondatabase/serverless'
export const database = process.env.DATABASE_URL ? neon(process.env.DATABASE_URL) : null
