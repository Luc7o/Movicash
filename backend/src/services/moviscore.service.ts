import { supabaseAdmin } from '../supabaseClient';

const SCORE_MIN = 300;
const SCORE_MAX = 850;

function nivelPorScore(score: number) {
  if (score >= 750) return 'Excelente';
  if (score >= 650) return 'Buen historial';
  if (score >= 500) return 'Regular';
  return 'Nuevo';
}

/**
 * Registra un evento que mueve el MoviScore (pago puntual, crédito
 * completado, aporte a círculo, atraso, etc.) y actualiza el score
 * "actual" en el perfil del usuario. Queda todo versionado en
 * moviscore_historial para poder explicarle al usuario por qué subió
 * o bajó — igual que se ve en la pantalla "Tu progreso" del diseño.
 */
export async function registrarEventoMoviscore(
  usuarioId: string,
  evento: string,
  variacion: number
) {
  const { data: usuario, error: errUsuario } = await supabaseAdmin
    .from('usuarios')
    .select('moviscore_actual')
    .eq('id', usuarioId)
    .single();

  if (errUsuario || !usuario) throw new Error('Usuario no encontrado');

  const nuevoScore = Math.min(
    SCORE_MAX,
    Math.max(SCORE_MIN, Number(usuario.moviscore_actual) + variacion)
  );

  const { error: errHist } = await supabaseAdmin.from('moviscore_historial').insert({
    usuario_id: usuarioId,
    score: nuevoScore,
    variacion,
    evento,
  });
  if (errHist) throw errHist;

  const { error: errUpdate } = await supabaseAdmin
    .from('usuarios')
    .update({
      moviscore_actual: nuevoScore,
      nivel_moviscore: nivelPorScore(nuevoScore),
      // El crédito disponible sube con el score: así se materializa
      // la promesa de "mejores condiciones" del modelo de negocio.
      credito_disponible_max: Math.min(500, 200 + Math.floor((nuevoScore - 500) / 2)),
    })
    .eq('id', usuarioId);

  if (errUpdate) throw errUpdate;

  return nuevoScore;
}

export async function obtenerMoviscore(usuarioId: string) {
  const { data: usuario, error } = await supabaseAdmin
    .from('usuarios')
    .select('moviscore_actual, nivel_moviscore, credito_disponible_min, credito_disponible_max')
    .eq('id', usuarioId)
    .single();
  if (error) throw error;

  const { data: historial, error: errHist } = await supabaseAdmin
    .from('moviscore_historial')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha', { ascending: false })
    .limit(20);
  if (errHist) throw errHist;

  return { ...usuario, historial };
}
