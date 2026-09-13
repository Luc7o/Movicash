-- Ejecutar en Supabase SQL Editor
-- Cambiamos de autenticación por SMS (de pago) a email + contraseña (gratis)

alter table usuarios alter column telefono drop not null;
alter table usuarios add column if not exists email text;

-- Ya no es necesario que el telefono sea unico si ahora puede quedar vacio
alter table usuarios drop constraint if exists usuarios_telefono_key;
