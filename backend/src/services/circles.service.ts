import { supabaseAdmin } from '../supabaseClient';
import { registrarEventoMoviscore } from './moviscore.service';

interface CrearCirculoInput {
  usuarioId: string;
  nombre: string;
  gremio: string;
  montoPorTurno: number;
  maxMiembros?: number;
}

export async function crearCirculo({ usuarioId, nombre, gremio, montoPorTurno, maxMiembros = 12 }: CrearCirculoInput) {
  const { data: circulo, error } = await supabaseAdmin
    .from('circulos_ahorro')
    .insert({
      nombre,
      gremio,
      monto_por_turno: montoPorTurno,
      max_miembros: maxMiembros,
      creado_por: usuarioId,
    })
    .select()
    .single();
  if (error) throw error;

  // El creador entra automáticamente como primer miembro
  await unirseACirculo({ usuarioId, circuloId: circulo.id });
  return circulo;
}

interface UnirseInput {
  usuarioId: string;
  circuloId: string;
}

export async function unirseACirculo({ usuarioId, circuloId }: UnirseInput) {
  const { count, error: errCount } = await supabaseAdmin
    .from('miembros_circulo')
    .select('*', { count: 'exact', head: true })
    .eq('circulo_id', circuloId);
  if (errCount) throw errCount;

  const { data: circulo, error: errCirculo } = await supabaseAdmin
    .from('circulos_ahorro')
    .select('max_miembros')
    .eq('id', circuloId)
    .single();
  if (errCirculo || !circulo) throw new Error('Círculo no encontrado');

  if ((count ?? 0) >= circulo.max_miembros) {
    throw new Error('Este círculo ya está completo');
  }

  const orden = (count ?? 0) + 1;

  const { data, error } = await supabaseAdmin
    .from('miembros_circulo')
    .insert({ circulo_id: circuloId, usuario_id: usuarioId, orden_turno: orden })
    .select()
    .single();
  if (error) throw error;
  return data;
}

interface AportarInput {
  usuarioId: string;
  circuloId: string;
  monto: number;
}

export async function registrarAporte({ usuarioId, circuloId, monto }: AportarInput) {
  const { data: circulo, error: errCirculo } = await supabaseAdmin
    .from('circulos_ahorro')
    .select('turno_actual')
    .eq('id', circuloId)
    .single();
  if (errCirculo || !circulo) throw new Error('Círculo no encontrado');

  const { data, error } = await supabaseAdmin
    .from('aportes_circulo')
    .insert({
      circulo_id: circuloId,
      usuario_id: usuarioId,
      monto,
      turno: circulo.turno_actual,
    })
    .select()
    .single();
  if (error) throw error;

  // Aportar a un círculo también construye MoviScore: es "ahorro
  // demostrado", una de las señales que se ve en "Tu progreso".
  await registrarEventoMoviscore(usuarioId, 'aporte_circulo', 3);

  return data;
}

export async function misCirculos(usuarioId: string) {
  const { data, error } = await supabaseAdmin
    .from('miembros_circulo')
    .select('*, circulos_ahorro(*, miembros_circulo(count))')
    .eq('usuario_id', usuarioId);
  if (error) throw error;
  return data;
}

export async function misAportes(usuarioId: string) {
  const { data, error } = await supabaseAdmin
    .from('aportes_circulo')
    .select('*, circulos_ahorro(nombre, gremio)')
    .eq('usuario_id', usuarioId)
    .order('fecha', { ascending: false });
  if (error) throw error;
  return data;
}

export async function circulosDisponibles() {
  const { data, error } = await supabaseAdmin
    .from('circulos_ahorro')
    .select('*, miembros_circulo(count)')
    .eq('estado', 'activo');
  if (error) throw error;
  return data;
}
