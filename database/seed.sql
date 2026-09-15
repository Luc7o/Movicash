-- Datos de ejemplo para el marketplace de MoviCash
-- Ejecutar en Supabase SQL Editor DESPUÉS de schema.sql

insert into entidades_marketplace (nombre, tipo, comision_origen_pct) values
  ('Caja Municipal Huancayo', 'Caja municipal', 3.0),
  ('Caja Los Andes', 'Caja municipal', 2.5),
  ('Cooperativa Abaco', 'Cooperativa', 2.0),
  ('Compartamos Financiera', 'Financiera', 3.5)
on conflict do nothing;

-- ------------------------------------------------------------
-- Círculos de ahorro / comunidades de ejemplo
-- Estos aparecen en "Círculos disponibles" para que un usuario nuevo
-- vea gremios reales de trabajadores informales y pueda unirse.
-- creado_por queda en null (círculo "oficial" de MoviCash, no de un usuario).
-- ------------------------------------------------------------
insert into circulos_ahorro (nombre, gremio, monto_por_turno, frecuencia, max_miembros, estado) values
  ('Junta Mototaxistas Huancayo Centro', 'Mototaxistas', 30, 'semanal', 10, 'activo'),
  ('Círculo Delivery Rappi & PedidosYa', 'Repartidores de delivery', 25, 'semanal', 12, 'activo'),
  ('Ahorro Comerciantes Mercado Mayorista', 'Comerciantes ambulantes', 50, 'quincenal', 8, 'activo'),
  ('Junta Taxistas El Tambo', 'Taxistas', 40, 'quincenal', 10, 'activo'),
  ('Círculo Costureras y Confeccionistas', 'Textiles y confección', 35, 'mensual', 12, 'activo'),
  ('Ahorro Construcción Civil Independiente', 'Construcción civil', 60, 'mensual', 8, 'activo'),
  ('Junta Vendedores de Abarrotes', 'Comercio de abarrotes', 45, 'quincenal', 10, 'activo'),
  ('Círculo Trabajadoras del Hogar', 'Trabajo doméstico', 20, 'semanal', 12, 'activo')
on conflict do nothing;
