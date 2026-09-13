-- Ejecutar en Supabase SQL Editor (agrega el campo para KYC básico)
alter table usuarios add column if not exists dni_foto_path text;

-- Bucket de Storage para las fotos de DNI (privado, no público)
insert into storage.buckets (id, name, public)
values ('kyc-documents', 'kyc-documents', false)
on conflict (id) do nothing;

-- Cada usuario solo puede subir/ver su propia carpeta dentro del bucket
create policy "usuarios suben su propio dni"
  on storage.objects for insert
  with check (bucket_id = 'kyc-documents' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "usuarios ven su propio dni"
  on storage.objects for select
  using (bucket_id = 'kyc-documents' and (storage.foldername(name))[1] = auth.uid()::text);
