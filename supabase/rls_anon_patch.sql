-- Patch RLS untuk tabel users (agar register bisa jalan dari anon key)
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;

-- 1. Karena login dari Flutter sekarang nyari berdasarkan email dengan anon key,
-- kita harus membolehkan select ke semua user (login form perlu ini buat cek email).
-- Untuk keamanan, pastikan data sensitif di aplikasi diamankan di level UI.
CREATE POLICY "users_select_all" ON public.users
  FOR SELECT USING (true);

-- 2. Memperbolehkan update profil sendiri, dengan mencocokkan id.
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (true); -- Disederhanakan untuk proof of concept (karena auth.uid() kosong)

-- 3. Memperbolehkan anon key melakukan insert (REGISTER).
CREATE POLICY "users_insert_all" ON public.users
  FOR INSERT WITH CHECK (true);

-- Untuk tabel-tabel lain, karena bergantung pada auth.uid(), ini tidak akan jalan kalau kita
-- query langsung tanpa JWT token login dari Supabase Auth.
-- Karena requirement memaksa langsung tembak tanpa JWT dari Edge Function,
-- kita sementara perlu mematikan RLS atau mem-bypass-nya dengan policy `USING (true)`
-- mengingat ini POC custom Auth tanpa Edge Function.

ALTER TABLE public.wallets            DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories         DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiat_transactions  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets            DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_categories  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals              DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.assets             DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_portfolios    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_valuations   DISABLE ROW LEVEL SECURITY;

