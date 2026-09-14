-- Ejecutar en Supabase SQL Editor (agrega el campo para la foto de perfil)
alter table usuarios add column if not exists foto_perfil_path text;

-- Bucket de Storage para las fotos de perfil (público: se muestra en la
-- app, a diferencia del bucket "kyc-documents" que es privado)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Cada usuario solo puede subir/reemplazar su propia foto dentro del bucket
create policy "usuarios suben su propia foto de perfil"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "usuarios reemplazan su propia foto de perfil"
  on storage.objects for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- El bucket es público, así que cualquiera con el link puede ver la foto
-- (necesario para que se muestre dentro de la app)
create policy "cualquiera puede ver las fotos de perfil"
  on storage.objects for select
  using (bucket_id = 'avatars');
