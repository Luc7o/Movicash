import { supabaseAdmin } from '../supabaseClient';
import { registrarEventoMoviscore } from './moviscore.service';

interface SolicitarCreditoInput {
  usuarioId: string;
  monto: number;
  motivo: string;
}

/**
 * Calcula un plan de pago diario simple: monto / N días.
 * N se ajusta según el monto (montos más altos -> más días para
 * que la cuota diaria se mantenga baja, como pide el modelo de negocio).
 */
function calcularPlanDePago(monto: number) {
  let dias: number;
  if (monto <= 100) dias = 20;
  else if (monto <= 250) dias = 30;
  else dias = 45;

  const pagoDiario = Math.ceil(monto / dias);
  return { dias, pagoDiario };
}

export async function solicitarCredito({ usuarioId, monto, motivo }: SolicitarCreditoInput) {
  if (monto < 50 || monto > 500) {
    throw new Error('El monto debe estar entre S/ 50 y S/ 500');
  }

  // Regla simple de elegibilidad: no permitir un 2do crédito activo
  const { data: creditosActivos, error: errActivos } = await supabaseAdmin
    .from('creditos')
    .select('id')
    .eq('usuario_id', usuarioId)
    .eq('estado', 'activo');

  if (errActivos) throw errActivos;
  if (creditosActivos && creditosActivos.length > 0) {
    throw new Error('Ya tienes un crédito activo. Termina de pagarlo para solicitar otro.');
  }

  const { dias, pagoDiario } = calcularPlanDePago(monto);
  const fechaFin = new Date();
  fechaFin.setDate(fechaFin.getDate() + dias);

  const { data, error } = await supabaseAdmin
    .from('creditos')
    .insert({
      usuario_id: usuarioId,
      monto,
      motivo,
      saldo_pendiente: monto,
      pago_diario_sugerido: pagoDiario,
      dias_totales: dias,
      dias_restantes: dias,
      fecha_fin_estimada: fechaFin.toISOString().split('T')[0],
      estado: 'activo',
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

interface RegistrarPagoInput {
  usuarioId: string;
  creditoId: string;
  monto: number;
  canal?: 'app' | 'agente';
}

/**
 * Registra un pago diario. Si el usuario paga menos (o nada) un día,
 * el sistema simplemente recalcula días_restantes en base al saldo —
 * así se respeta la promesa de "si un día no generas ingresos, pagas
 * menos o nada ese día".
 */
export async function registrarPago({ usuarioId, creditoId, monto, canal = 'app' }: RegistrarPagoInput) {
  const { data: credito, error: errCredito } = await supabaseAdmin
    .from('creditos')
    .select('*')
    .eq('id', creditoId)
    .eq('usuario_id', usuarioId)
    .single();

  if (errCredito || !credito) throw new Error('Crédito no encontrado');
  if (credito.estado !== 'activo') throw new Error('Este crédito no está activo');

  const nuevoSaldo = Math.max(0, Number(credito.saldo_pendiente) - monto);
  const nuevoEstado = nuevoSaldo === 0 ? 'completado' : 'activo';
  const diasRestantes = Math.max(
    0,
    Math.ceil(nuevoSaldo / Number(credito.pago_diario_sugerido))
  );

  const { error: errInsertPago } = await supabaseAdmin.from('pagos').insert({
    credito_id: creditoId,
    usuario_id: usuarioId,
    monto,
    canal,
  });
  if (errInsertPago) throw errInsertPago;

  const { data: creditoActualizado, error: errUpdate } = await supabaseAdmin
    .from('creditos')
    .update({
      saldo_pendiente: nuevoSaldo,
      dias_restantes: diasRestantes,
      estado: nuevoEstado,
    })
    .eq('id', creditoId)
    .select()
    .single();

  if (errUpdate) throw errUpdate;

  // Cada pago puntual (>0) suma puntos de MoviScore; completar el
  // crédito entero suma un bono extra.
  if (monto > 0) {
    await registrarEventoMoviscore(usuarioId, 'pago_puntual', 5);
  }
  if (nuevoEstado === 'completado') {
    await registrarEventoMoviscore(usuarioId, 'credito_completado', 25);
  }

  return creditoActualizado;
}

export async function obtenerCreditoActivo(usuarioId: string) {
  const { data, error } = await supabaseAdmin
    .from('creditos')
    .select('*')
    .eq('usuario_id', usuarioId)
    .eq('estado', 'activo')
    .maybeSingle();

  if (error) throw error;
  return data;
}

export async function obtenerHistorialCreditos(usuarioId: string) {
  const { data, error } = await supabaseAdmin
    .from('creditos')
    .select('*, pagos(*)')
    .eq('usuario_id', usuarioId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}
