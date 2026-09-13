import { supabaseAdmin } from '../supabaseClient';

export async function obtenerPerfil(usuarioId: string) {
  const { data, error } = await supabaseAdmin
    .from('usuarios')
    .select('*')
    .eq('id', usuarioId)
    .maybeSingle();
  if (error) throw error;
  return data; // null si el usuario todavía no completó su registro
}

/**
 * Crea la fila del usuario en la tabla "usuarios" la primera vez que
 * inicia sesión. Las políticas RLS bloquean el INSERT desde el cliente
 * a propósito, así que esto SIEMPRE pasa por el backend con la
 * service_role key.
 */
export async function crearPerfil(usuarioId: string, telefono: string, campos: {
  nombre: string;
  dni?: string;
  ubicacion?: string;
  ocupacion?: string;
}) {
  const { data, error } = await supabaseAdmin
    .from('usuarios')
    .upsert({
      id: usuarioId,
      telefono,
      nombre: campos.nombre,
      dni: campos.dni,
      ubicacion: campos.ubicacion,
      ocupacion: campos.ocupacion,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

interface ActualizarPerfilInput {
  usuarioId: string;
  nombre?: string;
  ubicacion?: string;
  ocupacion?: string;
  dni?: string;
}

export async function actualizarPerfil({ usuarioId, ...campos }: ActualizarPerfilInput) {
  const cambios: Record<string, any> = {};
  if (campos.nombre !== undefined) cambios.nombre = campos.nombre;
  if (campos.ubicacion !== undefined) cambios.ubicacion = campos.ubicacion;
  if (campos.ocupacion !== undefined) cambios.ocupacion = campos.ocupacion;
  if (campos.dni !== undefined) cambios.dni = campos.dni;

  const { data, error } = await supabaseAdmin
    .from('usuarios')
    .update(cambios)
    .eq('id', usuarioId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

/**
 * Guarda la referencia a la foto de DNI que el usuario subió a
 * Supabase Storage (bucket "kyc-documents"). Solo guardamos la RUTA,
 * no la hacemos pública — se sirve luego con una URL firmada temporal.
 */
export async function guardarFotoDni(usuarioId: string, storagePath: string) {
  const { error } = await supabaseAdmin
    .from('usuarios')
    .update({ dni_foto_path: storagePath })
    .eq('id', usuarioId);
  if (error) throw error;
  return { ok: true };
}
