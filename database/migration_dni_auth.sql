-- Ejecutar en Supabase SQL Editor
-- Cambiamos el identificador principal de registro de "teléfono" / solo
-- email a DNI + contraseña (verificado contra RENIEC al registrarse).
-- El correo que se guarda ahora es el correo "sintético" (<dni>@dni.movicash.pe)
-- que usa Supabase Auth internamente — no se le pide correo real al usuario.

-- ------------------------------------------------------------------
-- PASO 0 (obligatorio si ya tienes filas de prueba con dni = NULL):
-- Postgres no deja poner NOT NULL mientras existan filas nulas.
-- Elige UNA de las dos opciones de abajo:
-- ------------------------------------------------------------------

-- Opción A: son usuarios de prueba, bórralos (recomendado en desarrollo).
-- delete from usuarios where dni is null;

-- Opción B: son usuarios reales que quieres conservar, dales un DNI
-- temporal único para no romper nada (luego les pides que lo
-- actualicen en "Mis datos"). Comenta esta línea si usas la Opción A.
update usuarios
set dni = 'PENDIENTE-' || id::text
where dni is null;

-- ------------------------------------------------------------------
-- PASO 1: ahora sí, el DNI pasa a ser obligatorio.
-- (ya es "unique" desde schema.sql, aquí solo lo hacemos NOT NULL)
-- ------------------------------------------------------------------
alter table usuarios alter column dni set not null;

-- ------------------------------------------------------------------
-- PASO 2: el teléfono queda totalmente opcional (ya no se usa para
-- autenticarse).
-- ------------------------------------------------------------------
alter table usuarios alter column telefono drop not null;
