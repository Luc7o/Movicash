import { Router } from 'express';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { obtenerMoviscore } from '../services/moviscore.service';

const router = Router();
router.use(requireAuth);

// GET /api/moviscore -> pantalla "MoviScore" (720, Buen historial, progreso)
router.get('/', async (req: AuthedRequest, res) => {
  try {
    res.json(await obtenerMoviscore(req.userId!));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

export default router;
