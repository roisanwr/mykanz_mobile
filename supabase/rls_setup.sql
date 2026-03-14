-- ============================================================
-- MYKANZ MOBILE — RLS (Row Level Security) Setup Script
-- Jalankan script ini di Supabase SQL Editor
--
-- Cara kerja:
-- JWT dari Edge Function "login" berisi claim { sub: user_id }
-- Supabase mengenali claim "sub" sebagai auth.uid()
-- Policy di bawah memfilter baris berdasarkan auth.uid()
-- ============================================================


-- ============================================================
-- HELPER: Aktifkan RLS di semua tabel sekaligus
-- ============================================================
ALTER TABLE public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiat_transactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assets             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_portfolios    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_valuations   ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 1. TABEL USERS
-- User hanya bisa baca & update data dirinya sendiri
-- ============================================================
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;

CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (id = auth.uid());

-- INSERT di-handle oleh Edge Function "register" pakai service_role
-- Tidak perlu policy INSERT untuk anon/authenticated


-- ============================================================
-- 2. TABEL WALLETS
-- ============================================================
DROP POLICY IF EXISTS "wallets_all_own" ON public.wallets;

CREATE POLICY "wallets_all_own" ON public.wallets
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 3. TABEL CATEGORIES
-- ============================================================
DROP POLICY IF EXISTS "categories_all_own" ON public.categories;

CREATE POLICY "categories_all_own" ON public.categories
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 4. TABEL FIAT_TRANSACTIONS
-- ============================================================
DROP POLICY IF EXISTS "fiat_transactions_all_own" ON public.fiat_transactions;

CREATE POLICY "fiat_transactions_all_own" ON public.fiat_transactions
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 5. TABEL BUDGETS
-- ============================================================
DROP POLICY IF EXISTS "budgets_all_own" ON public.budgets;

CREATE POLICY "budgets_all_own" ON public.budgets
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 6. TABEL BUDGET_CATEGORIES
-- Akses via JOIN budget — user hanya bisa akses milik budgetnya
-- ============================================================
DROP POLICY IF EXISTS "budget_categories_all_own" ON public.budget_categories;

CREATE POLICY "budget_categories_all_own" ON public.budget_categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.budgets b
      WHERE b.id = budget_id AND b.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.budgets b
      WHERE b.id = budget_id AND b.user_id = auth.uid()
    )
  );


-- ============================================================
-- 7. TABEL GOALS
-- ============================================================
DROP POLICY IF EXISTS "goals_all_own" ON public.goals;

CREATE POLICY "goals_all_own" ON public.goals
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 8. TABEL ASSETS
-- Assets bisa: (a) global (user_id IS NULL) - read only
--              (b) milik user sendiri - full CRUD
-- ============================================================
DROP POLICY IF EXISTS "assets_select_global_or_own" ON public.assets;
DROP POLICY IF EXISTS "assets_insert_own" ON public.assets;
DROP POLICY IF EXISTS "assets_update_own" ON public.assets;
DROP POLICY IF EXISTS "assets_delete_own" ON public.assets;

CREATE POLICY "assets_select_global_or_own" ON public.assets
  FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "assets_insert_own" ON public.assets
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "assets_update_own" ON public.assets
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "assets_delete_own" ON public.assets
  FOR DELETE USING (user_id = auth.uid());


-- ============================================================
-- 9. TABEL USER_PORTFOLIOS
-- ============================================================
DROP POLICY IF EXISTS "user_portfolios_all_own" ON public.user_portfolios;

CREATE POLICY "user_portfolios_all_own" ON public.user_portfolios
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 10. TABEL ASSET_TRANSACTIONS
-- ============================================================
DROP POLICY IF EXISTS "asset_transactions_all_own" ON public.asset_transactions;

CREATE POLICY "asset_transactions_all_own" ON public.asset_transactions
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- 11. TABEL ASSET_VALUATIONS
-- Read: semua user bisa baca (harga aset bersifat publik)
-- Write: hanya assets milik user sendiri yg bisa diupdate
-- ============================================================
DROP POLICY IF EXISTS "asset_valuations_select_all" ON public.asset_valuations;
DROP POLICY IF EXISTS "asset_valuations_insert_own_asset" ON public.asset_valuations;

CREATE POLICY "asset_valuations_select_all" ON public.asset_valuations
  FOR SELECT USING (true);

CREATE POLICY "asset_valuations_insert_own_asset" ON public.asset_valuations
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.assets a
      WHERE a.id = asset_id AND a.user_id = auth.uid()
    )
  );


-- ============================================================
-- 12. VIEWS — Grant akses read ke role "authenticated"
-- Views otomatis mewarisi RLS dari tabel induknya
-- Tapi tetap perlu di-grant agar bisa di-query
-- ============================================================
GRANT SELECT ON public.wallet_balances              TO authenticated;
GRANT SELECT ON public.latest_asset_prices          TO authenticated;
GRANT SELECT ON public.user_asset_value_by_currency TO authenticated;


-- ============================================================
-- SELESAI!
-- Cek status RLS dengan query ini:
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE schemaname = 'public' ORDER BY tablename;
-- ============================================================
