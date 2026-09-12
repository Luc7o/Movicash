import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../supabaseClient';

// Extendemos Request para adjuntar el usuario autenticado
export interface AuthedRequest extends Request {
  userId?: string;
}

/**
 * La app Flutter inicia sesión directo contra Supabase Auth (OTP por
 * teléfono) y guarda el access_token. Cada request al backend manda
 * ese token en el header Authorization. Aquí lo validamos contra
 * Supabase y sacamos el userId real — así el backend nunca confía
 * en un usuario_id que venga suelto en el body.
 */
export async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Falta el token de autenticación' });
  }

  const token = authHeader.replace('Bearer ', '');
  const { data, error } = await supabaseAdmin.auth.getUser(token);

  if (error || !data.user) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }

  req.userId = data.user.id;
  next();
}
