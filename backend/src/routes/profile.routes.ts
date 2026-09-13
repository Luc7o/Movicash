import { Router } from 'express';
import { z } from 'zod';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { obtenerPerfil, actualizarPerfil, crearPerfil, guardarFotoDni } from '../services/profile.service';
import { supabaseAdmin } from '../supabaseClient';

const router = Router();
router.use(requireAuth);

router.get('/', async (req: AuthedRequest, res) => {
  try {
    const perfil = await obtenerPerfil(req.userId!);
    res.json(perfil); // puede ser null: significa que el usuario aún no se registró del todo
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const crearSchema = z.object({
  nombre: z.string().min(1),
  dni: z.string().optional(),
  ubicacion: z.string().optional(),
  ocupacion: z.string().optional(),
});

router.post('/', async (req: AuthedRequest, res) => {
  const parsed = crearSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    const { data: authUser } = await supabaseAdmin.auth.admin.getUserById(req.userId!);
    const email = authUser?.user?.email ?? '';
    const perfil = await crearPerfil(req.userId!, email, parsed.data);
    res.status(201).json(perfil);
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const actualizarSchema = z.object({
  nombre: z.string().min(1).optional(),
  ubicacion: z.string().optional(),
  ocupacion: z.string().optional(),
  dni: z.string().optional(),
});

router.put('/', async (req: AuthedRequest, res) => {
  const parsed = actualizarSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    res.json(await actualizarPerfil({ usuarioId: req.userId!, ...parsed.data }));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

const dniSchema = z.object({ storagePath: z.string().min(1) });

router.post('/dni', async (req: AuthedRequest, res) => {
  const parsed = dniSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    res.json(await guardarFotoDni(req.userId!, parsed.data.storagePath));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

export default router;
