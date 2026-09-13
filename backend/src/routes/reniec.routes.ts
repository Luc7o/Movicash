import { Router } from 'express';
import { consultarDni, ReniecError } from '../services/reniec.service';

const router = Router();

/**
 * GET /api/reniec/:dni
 *
 * A propósito NO exige `requireAuth`: se usa durante el registro, antes
 * de que exista una cuenta/sesión. Para evitar abuso, se podría añadir
 * más adelante un rate-limit por IP (por ejemplo con `express-rate-limit`).
 */
router.get('/:dni', async (req, res) => {
  try {
    const datos = await consultarDni(req.params.dni);
    res.json(datos);
  } catch (e) {
    if (e instanceof ReniecError) {
      return res.status(e.status).json({ error: e.message });
    }
    res.status(500).json({ error: 'Error inesperado consultando RENIEC.' });
  }
});

export default router;
