import { supabaseAdmin } from '../supabaseClient';
import { registrarEventoMoviscore } from './moviscore.service';

interface SolicitarCreditoInput {
  usuarioId: string;
  monto: number;
  motivo: string;
  plazoDias: number;
}

/** Tasa de interés fija que se muestra en el resumen de la solicitud. */
const TASA_INTERES = 0.10;

const PLAZOS_VALIDOS = [7, 10, 15, 30];

/**
 * Calcula el resumen del crédito con el plazo que eligió el usuario:
 * interés fijo del 10%, total a pagar y cuota diaria sugerida
 * (total / plazo). El plazo ya no se infiere del monto — lo decide
 * el usuario en la pantalla "Solicitar crédito".
 */
function calcularResumenCredito(monto: number, plazoDias: number) {
  const interes = Number((monto * TASA_INTERES).toFixed(2));
  const totalAPagar = Number((monto + interes).toFixed(2));
  const pagoDiario = Number((totalAPagar / plazoDias).toFixed(2));
  return { interes, totalAPagar, pagoDiario };
}

export async function solicitarCredito({ usuarioId, monto, motivo, plazoDias }: SolicitarCreditoInput) {
  if (monto < 50 || monto > 500) {
    throw new Error('El monto debe estar entre S/ 50 y S/ 500');
  }
  if (!PLAZOS_VALIDOS.includes(plazoDias)) {
    throw new Error(`El plazo debe ser uno de: ${PLAZOS_VALIDOS.join(', ')} días`);
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

  const { interes, totalAPagar, pagoDiario } = calcularResumenCredito(monto, plazoDias);
  const fechaFin = new Date();
  fechaFin.setDate(fechaFin.getDate() + plazoDias);

  const { data, error } = await supabaseAdmin
    .from('creditos')
    .insert({
      usuario_id: usuarioId,
      monto,
      motivo,
      interes,
      total_a_pagar: totalAPagar,
      saldo_pendiente: totalAPagar,
      pago_diario_sugerido: pagoDiario,
      dias_totales: plazoDias,
      dias_restantes: plazoDias,
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
