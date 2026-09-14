import { Router } from 'express';
import { z } from 'zod';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import {
  solicitarCredito,
  registrarPago,
  obtenerCreditoActivo,
  obtenerHistorialCreditos,
} from '../services/credits.service';

const router = Router();
router.use(requireAuth);

const PLAZOS_VALIDOS = [7, 10, 15, 30] as const;

const solicitarSchema = z.object({
  monto: z.number().min(50).max(500),
  motivo: z.string().min(1),
  plazoDias: z.number().refine((v) => (PLAZOS_VALIDOS as readonly number[]).includes(v), {
    message: `El plazo debe ser uno de: ${PLAZOS_VALIDOS.join(', ')} días`,
  }),
});

// POST /api/creditos  -> solicitar un crédito nuevo
router.post('/', async (req: AuthedRequest, res) => {
  const parsed = solicitarSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  try {
    const credito = await solicitarCredito({
      usuarioId: req.userId!,
      monto: parsed.data.monto,
      motivo: parsed.data.motivo,
      plazoDias: parsed.data.plazoDias,
    });
    res.status(201).json(credito);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

// GET /api/creditos/activo -> el crédito en curso (pantalla "Mi crédito")
router.get('/activo', async (req: AuthedRequest, res) => {
  try {
    const credito = await obtenerCreditoActivo(req.userId!);
    res.json(credito);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

// GET /api/creditos/historial -> pantalla "Movimientos > Créditos"
router.get('/historial', async (req: AuthedRequest, res) => {
  try {
    const historial = await obtenerHistorialCreditos(req.userId!);
    res.json(historial);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const pagoSchema = z.object({
  creditoId: z.string().uuid(),
  monto: z.number().min(0),
  canal: z.enum(['app', 'agente']).optional(),
});

// POST /api/creditos/pago -> registrar el pago diario
router.post('/pago', async (req: AuthedRequest, res) => {
  const parsed = pagoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  try {
    const credito = await registrarPago({
      usuarioId: req.userId!,
      creditoId: parsed.data.creditoId,
      monto: parsed.data.monto,
      canal: parsed.data.canal,
    });
    res.json(credito);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

export default router;
