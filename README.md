# Capstone Project 404 - Sistem Inventaris & Surat Karoseri Ambulans

Tim 404, Program Asah 2026 (Dicoding x GoTo). Klien: CV Indojaya Mandiri Kurnia.

## Struktur
- `frontend/`  : React + Vite + supabase-js
- `supabase/`  : schema.sql dan seed.sql
- `docs/`      : wireframe dan catatan

## Alur git
- `main` hanya berisi hasil yang sudah di-merge lewat Pull Request.
- Kerja di branch: `feat/...`, `fix/...`, `docs/...`.

## Setup frontend
1. `cd frontend`
2. Salin `.env.example` jadi `.env`, isi URL dan publishable key Supabase.
3. `npm install` lalu `npm run dev`

Jangan pernah commit `.env` atau secret/service_role key.