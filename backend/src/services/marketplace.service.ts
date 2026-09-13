import { supabaseAdmin } from '../supabaseClient';

export async function entidadesDisponibles() {
  const { data, error } = await supabaseAdmin
    .from('entidades_marketplace')
    .select('*')
    .eq('activo', true);
  if (error) throw error;
  return data;
}

interface SolicitarInput {
  usuarioId: string;
  entidadId: string;
  monto: number;
}

export async function solicitarEnMarketplace({ usuarioId, entidadId, monto }: SolicitarInput) {
  const { data: usuario, error: errUsuario } = await supabaseAdmin
    .from('usuarios')
    .select('moviscore_actual')
    .eq('id', usuarioId)
    .single();
  if (errUsuario || !usuario) throw new Error('Usuario no encontrado');

  const { data, error } = await supabaseAdmin
    .from('solicitudes_marketplace')
    .insert({
      usuario_id: usuarioId,
      entidad_id: entidadId,
      monto_solicitado: monto,
      moviscore_al_momento: usuario.moviscore_actual,
    })
    .select('*, entidades_marketplace(nombre, tipo)')
    .single();
  if (error) throw error;
  return data;
}

export async function misSolicitudesMarketplace(usuarioId: string) {
  const { data, error } = await supabaseAdmin
    .from('solicitudes_marketplace')
    .select('*, entidades_marketplace(nombre, tipo)')
    .eq('usuario_id', usuarioId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}
