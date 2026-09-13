/**
 * Servicio de consulta de DNI contra RENIEC, usando Decolecta
 * (https://decolecta.com) como proveedor.
 *
 * El token va SOLO en el backend (variable de entorno RENIEC_API_TOKEN)
 * — nunca se expone al frontend, así evitamos que alguien copie el
 * token del APK y agote la cuota de la cuenta.
 */

interface ReniecResponse {
  dni: string;
  nombres: string;
  apellidoPaterno: string;
  apellidoMaterno: string;
  nombreCompleto: string;
}

export class ReniecError extends Error {
  status: number;
  constructor(message: string, status = 400) {
    super(message);
    this.status = status;
  }
}

export async function consultarDni(dni: string): Promise<ReniecResponse> {
  if (!/^\d{8}$/.test(dni)) {
    throw new ReniecError('El DNI debe tener 8 dígitos numéricos.', 422);
  }

  const token = process.env.RENIEC_API_TOKEN;
  if (!token) {
    throw new ReniecError(
      'El servicio de verificación de DNI no está configurado (falta RENIEC_API_TOKEN en el backend).',
      500,
    );
  }

  // Decolecta: https://decolecta.com/products/reniec
  const url = `https://api.decolecta.com/v1/reniec/dni?numero=${dni}`;

  let resp: Response;
  try {
    resp = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
  } catch (e) {
    throw new ReniecError('No se pudo conectar con el servicio de RENIEC. Intenta de nuevo.', 502);
  }

  if (resp.status === 401 || resp.status === 403) {
    throw new ReniecError('El token de Decolecta no es válido o venció. Revisa RENIEC_API_TOKEN.', 500);
  }
  if (resp.status === 404) {
    throw new ReniecError('No encontramos ese DNI en RENIEC. Verifica el número.', 404);
  }
  if (!resp.ok) {
    throw new ReniecError('El servicio de RENIEC no respondió correctamente. Intenta más tarde.', 502);
  }

  const data: any = await resp.json();

  // Decolecta devuelve: { first_last_name, second_last_name, names, full_name, document_number }
  const nombres = data.names ?? data.nombres ?? '';
  const apellidoPaterno = data.first_last_name ?? data.apellidoPaterno ?? data.apellido_paterno ?? '';
  const apellidoMaterno = data.second_last_name ?? data.apellidoMaterno ?? data.apellido_materno ?? '';
  const nombreCompleto =
    data.full_name ??
    data.nombreCompleto ??
    data.nombre_completo ??
    `${nombres} ${apellidoPaterno} ${apellidoMaterno}`.trim();

  if (!nombreCompleto) {
    throw new ReniecError('No encontramos datos para ese DNI.', 404);
  }

  return { dni, nombres, apellidoPaterno, apellidoMaterno, nombreCompleto };
}
