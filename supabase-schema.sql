-- MTX Advisor — Schema Supabase
-- Execute no SQL Editor do Supabase: https://supabase.com/dashboard/project/ejnzrlgqjszkrgrpugzn/sql

-- ============================================================
-- LÍDERES
-- ============================================================
CREATE TABLE IF NOT EXISTS leaders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  pass TEXT NOT NULL,
  area TEXT,
  color TEXT DEFAULT '#0076BD',
  title TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  whatsapp TEXT DEFAULT '',
  photo TEXT,
  photo_history JSONB DEFAULT '[]',
  photo_updated_at TIMESTAMPTZ,
  photo_updated_by TEXT,
  anamnese_done BOOLEAN DEFAULT false,
  anamnese_answers JSONB,
  anamnese_progress JSONB,
  profile JSONB,
  must_change_pw BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- USUÁRIOS ADMIN
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  pass TEXT NOT NULL,
  area TEXT DEFAULT 'CEO',
  color TEXT DEFAULT '#0076BD',
  anamnese_done BOOLEAN DEFAULT false,
  must_change_pw BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SESSÕES DE 1:1
-- ============================================================
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  leader_id TEXT NOT NULL REFERENCES leaders(id) ON DELETE CASCADE,
  conducted_by TEXT NOT NULL,
  date TEXT,
  date_iso TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  data JSONB NOT NULL DEFAULT '{}',
  recording JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS sessions_leader_id_idx ON sessions(leader_id);
CREATE INDEX IF NOT EXISTS sessions_date_iso_idx ON sessions(date_iso DESC);

-- ============================================================
-- PLANOS DE AÇÃO
-- ============================================================
CREATE TABLE IF NOT EXISTS action_items (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,
  deadline TEXT,
  priority TEXT DEFAULT 'Média',
  indicator TEXT DEFAULT '',
  support TEXT DEFAULT '',
  leader_id TEXT NOT NULL REFERENCES leaders(id) ON DELETE CASCADE,
  session_id TEXT REFERENCES sessions(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','done','partial','not_done')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS action_items_leader_id_idx ON action_items(leader_id);
CREATE INDEX IF NOT EXISTS action_items_status_idx ON action_items(status);

-- ============================================================
-- ALERTAS
-- ============================================================
CREATE TABLE IF NOT EXISTS alerts (
  id TEXT PRIMARY KEY,
  leader_id TEXT REFERENCES leaders(id) ON DELETE CASCADE,
  session_id TEXT REFERENCES sessions(id) ON DELETE SET NULL,
  level TEXT DEFAULT 'info',
  criticality TEXT DEFAULT 'Informativo',
  signals JSONB DEFAULT '[]',
  title TEXT NOT NULL,
  body TEXT DEFAULT '',
  suggestion TEXT DEFAULT '',
  date TEXT,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS alerts_leader_id_idx ON alerts(leader_id);
CREATE INDEX IF NOT EXISTS alerts_read_idx ON alerts(read);

-- ============================================================
-- REUNIÕES AGENDADAS
-- ============================================================
CREATE TABLE IF NOT EXISTS scheduled_meetings (
  id TEXT PRIMARY KEY,
  leader_id TEXT NOT NULL REFERENCES leaders(id) ON DELETE CASCADE,
  leader_name TEXT,
  leader_email TEXT,
  date TEXT NOT NULL,
  time_start TEXT,
  time_end TEXT,
  duration INTEGER DEFAULT 60,
  meeting_type TEXT DEFAULT '1on1_regular',
  agenda TEXT DEFAULT '',
  message TEXT DEFAULT '',
  teams_link TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled','completed','cancelled')),
  created_by TEXT,
  reminder_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS scheduled_meetings_leader_id_idx ON scheduled_meetings(leader_id);
CREATE INDEX IF NOT EXISTS scheduled_meetings_date_idx ON scheduled_meetings(date);

-- ============================================================
-- NOTIFICAÇÕES
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT DEFAULT '',
  meta JSONB DEFAULT '{}',
  recipient_id TEXT,
  recipient_email TEXT,
  ts TIMESTAMPTZ DEFAULT NOW(),
  read BOOLEAN DEFAULT false,
  channel TEXT DEFAULT 'system',
  status TEXT DEFAULT 'pending',
  created_by TEXT DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS notifications_recipient_id_idx ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS notifications_read_idx ON notifications(read);

-- ============================================================
-- CHAT
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  from_user TEXT NOT NULL,
  from_name TEXT,
  is_admin BOOLEAN DEFAULT false,
  to_leader_id TEXT REFERENCES leaders(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  ts TIMESTAMPTZ DEFAULT NOW(),
  read BOOLEAN DEFAULT false,
  priority TEXT DEFAULT 'normal'
);
CREATE INDEX IF NOT EXISTS chat_messages_to_leader_id_idx ON chat_messages(to_leader_id);

-- ============================================================
-- CEO KNOWLEDGE BASE (itens da base cognitiva)
-- ============================================================
CREATE TABLE IF NOT EXISTS ceo_items (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  type TEXT DEFAULT 'item',
  category TEXT DEFAULT 'items',
  content JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- KV STORE (store JSON completo — abordagem atual do app)
-- ============================================================
CREATE TABLE IF NOT EXISTS kv_store (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Permite acesso público via anon key (app usa autenticação própria)
-- ============================================================
ALTER TABLE leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE action_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ceo_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE kv_store ENABLE ROW LEVEL SECURITY;

-- Políticas: acesso total via anon key (app controla permissões internamente)
CREATE POLICY "anon_all_leaders" ON leaders FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_users" ON users FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_sessions" ON sessions FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_actions" ON action_items FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_alerts" ON alerts FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_meetings" ON scheduled_meetings FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_notifications" ON notifications FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_chat" ON chat_messages FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_ceo" ON ceo_items FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_kv" ON kv_store FOR ALL TO anon USING (true) WITH CHECK (true);
