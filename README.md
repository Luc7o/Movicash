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
2. Ve a **SQL Editor** y ejecuta, en este orden, el contenido de:
   1. `database/schema.sql` — esquema base
   2. `database/migration_kyc.sql` — foto de DNI (bucket privado `kyc-documents`)
   3. `database/migration_plazo_interes.sql` — plazo de pago elegible + interés (10%) y total a pagar en `creditos`
   4. `database/migration_avatar.sql` — foto de perfil (bucket público `avatars`)
   5. `database/seed.sql` — datos de ejemplo para el marketplace
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
- `POST /api/creditos` — solicitar crédito `{ monto, motivo, plazoDias }` (`plazoDias` es uno de 7 / 10 / 15 / 30; el interés es fijo del 10% y se calcula en el backend)
- `GET  /api/creditos/activo` — crédito en curso
- `GET  /api/creditos/historial` — historial de créditos
- `POST /api/creditos/pago` — registrar pago diario `{ creditoId, monto }`
- `GET  /api/moviscore` — score actual + historial + crédito disponible
- `GET  /api/circulos/mios` — mis círculos de ahorro
- `GET  /api/circulos/mis-aportes` — mis aportes a círculos
- `GET  /api/circulos/disponibles` — círculos abiertos para unirse
- `POST /api/circulos` — crear círculo `{ nombre, gremio, montoPorTurno }`
- `POST /api/circulos/:id/unirse` — unirse a un círculo
- `POST /api/circulos/:id/aportar` — aportar a un círculo `{ monto }`
- `GET  /api/perfil` — datos del usuario
- `POST /api/perfil` / `PUT /api/perfil` — crear/actualizar datos del usuario
- `POST /api/perfil/dni` — guardar referencia a la foto de DNI subida a `kyc-documents` `{ storagePath }`
- `POST /api/perfil/foto` — guardar referencia a la foto de perfil subida a `avatars` `{ storagePath }`

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

## 5. Estado del despliegue

- El backend ya está desplegado en **Render** (`render.yaml` incluido en la raíz del proyecto).
- El frontend se está probando con un APK de release generado manualmente (aún no está en una tienda de apps).

## 6. Próximos pasos sugeridos

- Conectar una pasarela de pagos real (Culqi/Niubiz) o interoperabilidad con
  Yape/Plin para el cobro/desembolso de dinero real.
- Agregar notificaciones push (Firebase Cloud Messaging) para recordar el
  pago diario.
- Endurecer el motor de MoviScore con más señales (atrasos, frecuencia de uso).
- Salir del modo de pruebas de OTP de Supabase (actualmente usa un número de
  prueba con código fijo `123456` por las restricciones de la cuenta trial de Twilio).
