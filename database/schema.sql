-- ============================================================
-- MoviCash — Esquema de base de datos para Supabase (PostgreSQL)
-- ============================================================
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- Supabase ya trae auth.users (tabla de autenticación).
-- Aquí creamos "usuarios" como perfil extendido 1-a-1 con auth.users.

-- ------------------------------------------------------------
-- EXTENSIONES
-- ------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. USUARIOS (perfil extendido de auth.users)
-- ------------------------------------------------------------
create table usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  dni text unique,
  telefono text unique not null,
  ubicacion text,                -- ej. "Tingo María, Huánuco"
  ocupacion text,                -- mototaxista, delivery, comerciante...
  moviscore_actual int default 500 check (moviscore_actual between 0 and 850),
  nivel_moviscore text default 'Nuevo',   -- Nuevo / Regular / Buen historial / Excelente
  credito_disponible_min numeric default 50,
  credito_disponible_max numeric default 200,
  fecha_registro timestamptz default now(),
  activo boolean default true
);

-- ------------------------------------------------------------
-- 2. CRÉDITOS
-- ------------------------------------------------------------
create table creditos (
  id uuid primary key default uuid_generate_v4(),
  usuario_id uuid references usuarios(id) on delete cascade not null,
  monto numeric not null check (monto between 50 and 500),
  motivo text,                    -- combustible / repuestos / mercadería / otros
  interes numeric,                -- 10% fijo del monto (elegido en el resumen de la solicitud)
  total_a_pagar numeric,          -- monto + interes
  saldo_pendiente numeric not null, -- para créditos nuevos, arranca igual a total_a_pagar
  pago_diario_sugerido numeric not null,
  dias_totales int not null,      -- plazo elegido por el usuario: 7 / 10 / 15 / 30
  dias_restantes int not null,
  fecha_inicio date default current_date,
  fecha_fin_estimada date,
  estado text default 'activo' check (estado in ('pendiente','activo','completado','moroso','cancelado')),
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 3. PAGOS DE CRÉDITO
-- ------------------------------------------------------------
create table pagos (
  id uuid primary key default uuid_generate_v4(),
  credito_id uuid references creditos(id) on delete cascade not null,
  usuario_id uuid references usuarios(id) on delete cascade not null,
  monto numeric not null check (monto >= 0),
  canal text default 'app' check (canal in ('app','agente')),
  fecha timestamptz default now()
);

-- ------------------------------------------------------------
-- 4. CÍRCULOS DE AHORRO (juntas digitales)
-- ------------------------------------------------------------
create table circulos_ahorro (
  id uuid primary key default uuid_generate_v4(),
  nombre text not null,
  gremio text,                    -- ej. "Mototaxistas de Tingo María"
  monto_por_turno numeric not null,
  frecuencia text default 'mensual' check (frecuencia in ('semanal','quincenal','mensual')),
  max_miembros int default 12,
  turno_actual int default 1,
  estado text default 'activo' check (estado in ('activo','completo','cancelado')),
  creado_por uuid references usuarios(id),
  created_at timestamptz default now()
);

create table miembros_circulo (
  id uuid primary key default uuid_generate_v4(),
  circulo_id uuid references circulos_ahorro(id) on delete cascade not null,
  usuario_id uuid references usuarios(id) on delete cascade not null,
  orden_turno int not null,
  estado text default 'activo' check (estado in ('activo','completado','retirado')),
  fecha_union timestamptz default now(),
  unique (circulo_id, usuario_id)
);

create table aportes_circulo (
  id uuid primary key default uuid_generate_v4(),
  circulo_id uuid references circulos_ahorro(id) on delete cascade not null,
  usuario_id uuid references usuarios(id) on delete cascade not null,
  monto numeric not null,
  turno int not null,
  fecha timestamptz default now()
);

-- ------------------------------------------------------------
-- 5. MOVISCORE — historial versionado
-- ------------------------------------------------------------
create table moviscore_historial (
  id uuid primary key default uuid_generate_v4(),
  usuario_id uuid references usuarios(id) on delete cascade not null,
  score int not null,
  variacion int,                  -- +10 / -15 etc.
  evento text,                    -- "pago_puntual" / "credito_completado" / "aporte_circulo" / "atraso"
  fecha timestamptz default now()
);

-- ------------------------------------------------------------
-- 6. COMERCIOS AFILIADOS (agentes)
-- ------------------------------------------------------------
create table comercios_afiliados (
  id uuid primary key default uuid_generate_v4(),
  nombre text not null,
  tipo text,                      -- bodega, grifo, etc.
  ubicacion text,
  comision_pct numeric default 1.0,
  activo boolean default true
);

-- ------------------------------------------------------------
-- 7. MARKETPLACE (cajas / cooperativas aliadas)
-- ------------------------------------------------------------
create table entidades_marketplace (
  id uuid primary key default uuid_generate_v4(),
  nombre text not null,
  tipo text,                      -- caja municipal, cooperativa, fintech
  comision_origen_pct numeric default 3.0,
  activo boolean default true
);

create table solicitudes_marketplace (
  id uuid primary key default uuid_generate_v4(),
  usuario_id uuid references usuarios(id) on delete cascade not null,
  entidad_id uuid references entidades_marketplace(id) not null,
  monto_solicitado numeric not null,
  moviscore_al_momento int,
  estado text default 'enviada' check (estado in ('enviada','en_revision','aprobada','rechazada')),
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- ÍNDICES ÚTILES
-- ------------------------------------------------------------
create index idx_creditos_usuario on creditos(usuario_id);
create index idx_pagos_credito on pagos(credito_id);
create index idx_miembros_circulo_usuario on miembros_circulo(usuario_id);
create index idx_moviscore_usuario on moviscore_historial(usuario_id, fecha desc);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Cada usuario solo ve/edita su propia información.
-- Las operaciones sensibles (crear crédito, mover MoviScore)
-- se hacen desde el backend con la service_role key, que
-- se salta RLS de forma controlada.
-- ============================================================
alter table usuarios enable row level security;
alter table creditos enable row level security;
alter table pagos enable row level security;
alter table circulos_ahorro enable row level security;
alter table miembros_circulo enable row level security;
alter table aportes_circulo enable row level security;
alter table moviscore_historial enable row level security;
alter table solicitudes_marketplace enable row level security;

create policy "usuarios ven su propio perfil"
  on usuarios for select using (auth.uid() = id);
create policy "usuarios editan su propio perfil"
  on usuarios for update using (auth.uid() = id);

create policy "usuarios ven sus propios creditos"
  on creditos for select using (auth.uid() = usuario_id);

create policy "usuarios ven sus propios pagos"
  on pagos for select using (auth.uid() = usuario_id);

create policy "usuarios ven circulos donde participan"
  on circulos_ahorro for select using (
    id in (select circulo_id from miembros_circulo where usuario_id = auth.uid())
  );

create policy "usuarios ven su membresia"
  on miembros_circulo for select using (auth.uid() = usuario_id);

create policy "usuarios ven sus aportes"
  on aportes_circulo for select using (auth.uid() = usuario_id);

create policy "usuarios ven su historial moviscore"
  on moviscore_historial for select using (auth.uid() = usuario_id);

create policy "usuarios ven sus solicitudes marketplace"
  on solicitudes_marketplace for select using (auth.uid() = usuario_id);

-- Nota: los INSERT/UPDATE de creditos, pagos, moviscore, etc. NO tienen
-- policy para el rol "authenticated" a propósito: eso obliga a que toda
-- lógica de negocio (dar un crédito, sumar un pago, mover el score)
-- pase por el backend con la service_role key, evitando que el usuario
-- manipule su propio saldo o score desde el cliente.
