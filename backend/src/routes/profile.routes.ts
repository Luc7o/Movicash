import { Router } from 'express';
import { z } from 'zod';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { obtenerPerfil, actualizarPerfil, crearPerfil, guardarFotoDni, guardarFotoPerfil } from '../services/profile.service';

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
  telefono: z.string().optional(),
  correo: z.string().optional(),
  ubicacion: z.string().optional(),
  ocupacion: z.string().optional(),
});

router.post('/', async (req: AuthedRequest, res) => {
  const parsed = crearSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    // El correo real de contacto lo escribe el usuario en el formulario
    // (campo "correo"). El correo técnico que usa Supabase Auth para
    // iniciar sesión (el sintético <dni>@dni.movicash.pe) no se guarda
    // como "el correo del usuario" en la tabla, para no confundirlo.
    const perfil = await crearPerfil(req.userId!, parsed.data.correo ?? '', parsed.data);
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
  telefono: z.string().optional(),
  correo: z.string().optional(),
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

const fotoPerfilSchema = z.object({ storagePath: z.string().min(1) });

router.post('/foto', async (req: AuthedRequest, res) => {
  const parsed = fotoPerfilSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  try {
    res.json(await guardarFotoPerfil(req.userId!, parsed.data.storagePath));
  } catch (e: any) {
    res.status(400).json({ error: e.message });
  }
});

export default router;
