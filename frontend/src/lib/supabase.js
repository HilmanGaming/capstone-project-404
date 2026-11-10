import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_KEY

if (!url || !key) {
  throw new Error('Isi VITE_SUPABASE_URL dan VITE_SUPABASE_KEY di .env.local, lalu restart npm run dev')
}

// Hanya publishable key di sini. Jangan pernah pakai secret/service_role di frontend.
export const supabase = createClient(url, key)