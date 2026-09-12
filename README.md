# MoviCash — Proyecto base (Backend + Frontend + Supabase)

Estructura:
```
movicash/
  database/schema.sql     -> script SQL para Supabase
  backend/                -> API en Node.js + Express + TypeScript
  frontend/                -> App en Flutter
```

## 1. Configurar Supabase (5 min)

1. Crea un proyecto en https://supabase.com
2. Ve a **SQL Editor** y pega todo el contenido de `database/schema.sql`. Ejecútalo.
3. Ve a **Authentication > Providers** y activa **Phone** (necesitas configurar un proveedor SMS como Twilio, o usar el modo de pruebas de Supabase para desarrollo).
4. Ve a **Project Settings > API** y copia:
   - `Project URL`
   - `anon public key` (va en el frontend)
   - `service_role key` (va SOLO en el backend, nunca la subas a git)

## 2. Levantar el backend

```bash
cd backend
cp .env.example .env
# edita .env con tu SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY
npm install
npm run dev
```

Esto levanta la API en `http://localhost:4000`. Prueba con:
```bash
curl http://localhost:4000/health
```

Endpoints principales:
- `POST /api/creditos` — solicitar crédito `{ monto, motivo }`
- `GET  /api/creditos/activo` — crédito en curso
- `POST /api/creditos/pago` — registrar pago diario `{ creditoId, monto }`
- `GET  /api/moviscore` — score actual + historial
- `GET  /api/circulos/mios` — mis círculos de ahorro
- `POST /api/circulos` — crear círculo `{ nombre, gremio, montoPorTurno }`
- `POST /api/circulos/:id/aportar` — aportar a un círculo `{ monto }`

Todas las rutas (excepto `/health`) requieren el header:
`Authorization: Bearer <access_token_de_supabase>`

## 3. Levantar el frontend (Flutter)

Requisitos: tener Flutter SDK instalado (https://flutter.dev) — esto NO se puede instalar en este entorno de chat, así que corre estos pasos en tu propia máquina o en Android Studio/VS Code.

```bash
cd frontend
cp .env.example .env
# edita .env con tu SUPABASE_URL, SUPABASE_ANON_KEY y API_BASE_URL
flutter pub get
flutter run
```

Si pruebas en un emulador Android y tu backend corre en tu máquina (`localhost`), usa
`API_BASE_URL=http://10.0.2.2:4000/api` en vez de `localhost` (así accede el emulador
a tu máquina host).

## 4. Flujo de datos (resumen)

```
App Flutter
   │  (1) Login con OTP por teléfono -> directo contra Supabase Auth
   │  (2) Lecturas simples (perfil propio) -> directo contra Supabase (protegido por RLS)
   │  (3) Acciones de negocio (pedir crédito, pagar, aportar a círculo)
   ▼        -> siempre pasan por el backend, nunca directo a la tabla
Backend Node/Express
   │  Usa la service_role key de Supabase (se salta RLS de forma controlada)
   │  Aplica las reglas: plan de pago diario, cálculo de MoviScore, cupos de círculo
   ▼
Supabase (Postgres + RLS)
```

Este diseño evita que un usuario pueda, por ejemplo, escribir directo en la tabla
`creditos` desde la app y subirse su propio MoviScore — toda esa lógica vive
solo en el backend.

## 5. Próximos pasos sugeridos

- Conectar una pasarela de pagos real (Culqi/Niubiz) o interoperabilidad con
  Yape/Plin para el cobro/desembolso de dinero real.
- Agregar Supabase Storage para fotos de DNI (verificación KYC básica).
- Agregar notificaciones push (Firebase Cloud Messaging) para recordar el
  pago diario.
- Endurecer el motor de MoviScore con más señales (atrasos, frecuencia de uso).
