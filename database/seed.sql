-- Datos de ejemplo para el marketplace de MoviCash
-- Ejecutar en Supabase SQL Editor DESPUÉS de schema.sql

insert into entidades_marketplace (nombre, tipo, comision_origen_pct) values
  ('Caja Municipal Huancayo', 'Caja municipal', 3.0),
  ('Caja Los Andes', 'Caja municipal', 2.5),
  ('Cooperativa Abaco', 'Cooperativa', 2.0),
  ('Compartamos Financiera', 'Financiera', 3.5)
on conflict do nothing;
