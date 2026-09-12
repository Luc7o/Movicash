import { Router } from 'express';
import { z } from 'zod';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import {
  crearCirculo,
  unirseACirculo,
  registrarAporte,
  misCirculos,
  misAportes,
  circulosDisponibles,
} from '../services/circles.service';

const router = Router();
router.use(requireAuth);

router.get('/mios', async (req: AuthedRequest, res) => {
  try {
    res.json(await misCirculos(req.userId!));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

router.get('/mis-aportes', async (req: AuthedRequest, res) => {
  try {
    res.json(await misAportes(req.userId!));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

router.get('/disponibles', async (_req, res) => {
  try {
    res.json(await circulosDisponibles());
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const crearSchema = z.object({
  nombre: z.string().min(1),
  gremio: z.string().min(1),
  montoPorTurno: z.number().positive(),
  maxMiembros: z.number().int().positive().optional(),
});

router.post('/', async (req: AuthedRequest, res) => {
  const parsed = crearSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    const circulo = await crearCirculo({ usuarioId: req.userId!, ...parsed.data });
    res.status(201).json(circulo);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

router.post('/:id/unirse', async (req: AuthedRequest, res) => {
  try {
    const miembro = await unirseACirculo({ usuarioId: req.userId!, circuloId: req.params.id });
    res.status(201).json(miembro);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const aporteSchema = z.object({ monto: z.number().positive() });

router.post('/:id/aportar', async (req: AuthedRequest, res) => {
  const parsed = aporteSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    const aporte = await registrarAporte({
      usuarioId: req.userId!,
      circuloId: req.params.id,
      monto: parsed.data.monto,
    });
    res.status(201).json(aporte);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

export default router;
