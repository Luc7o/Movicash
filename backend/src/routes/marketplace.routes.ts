import { Router } from 'express';
import { z } from 'zod';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import {
  entidadesDisponibles,
  solicitarEnMarketplace,
  misSolicitudesMarketplace,
} from '../services/marketplace.service';

const router = Router();
router.use(requireAuth);

router.get('/entidades', async (_req, res) => {
  try {
    res.json(await entidadesDisponibles());
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

router.get('/mis-solicitudes', async (req: AuthedRequest, res) => {
  try {
    res.json(await misSolicitudesMarketplace(req.userId!));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const solicitarSchema = z.object({
  entidadId: z.string().uuid(),
  monto: z.number().positive(),
});

router.post('/solicitudes', async (req: AuthedRequest, res) => {
  const parsed = solicitarSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    const solicitud = await solicitarEnMarketplace({
      usuarioId: req.userId!,
      entidadId: parsed.data.entidadId,
      monto: parsed.data.monto,
    });
    res.status(201).json(solicitud);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

export default router;
