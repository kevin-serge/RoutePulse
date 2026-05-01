-- ============================================================
-- ROUTEPULSE — Script SQL Supabase
-- Exécuter dans : Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. TABLE LIVRAISONS
DROP TABLE IF EXISTS livraisons;

CREATE TABLE livraisons (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client           TEXT NOT NULL,
  adresse          TEXT NOT NULL,
  statut           TEXT NOT NULL DEFAULT 'en_attente'
                     CHECK (statut IN ('en_attente','en_cours','a_reporter','annulee','livree')),
  livreur_id       INTEGER,
  photos           TEXT DEFAULT '[]',
  notes            TEXT,
  motif_annulation TEXT,
  creneau          TEXT,
  articles         TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TRIGGER updated_at automatique
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON livraisons;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON livraisons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. REALTIME (obligatoire pour startRealtimeSync)
ALTER PUBLICATION supabase_realtime ADD TABLE livraisons;

-- 4. RLS — accès ouvert (app locale gère ses propres utilisateurs)
ALTER TABLE livraisons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all" ON livraisons;
CREATE POLICY "allow_all" ON livraisons
  FOR ALL USING (true) WITH CHECK (true);
