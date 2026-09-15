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
3. Ve a **Authentication > Providers** y activa **Email**. El login de MoviCash usa **DNI peruano verificado con RENIEC**: en el registro, el DNI se valida contra RENIEC (proxy a Decolecta) y se crea internamente una cuenta de Supabase Auth con email sintético `<dni>@dni.movicash.pe` + la contraseña que elige el usuario — no hace falta configurar un proveedor SMS.
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
- `GET  /api/reniec/:dni` — consulta RENIEC (nombre completo) para verificar el DNI en el registro
- `POST /api/creditos` — solicitar crédito `{ monto, motivo, plazoDias }` (`plazoDias` es uno de 7 / 10 / 15 / 30; el interés es fijo del 10% y se calcula en el backend)
- `GET  /api/creditos/activo` — crédito en curso
- `GET  /api/creditos/historial` — historial de créditos
- `POST /api/creditos/pago` — registrar pago diario `{ creditoId, monto }`
- `GET  /api/moviscore` — score actual + historial + crédito disponible
- `GET  /api/circulos/mios` — mis círculos de ahorro (incluye conteo de miembros)
- `GET  /api/circulos/mis-aportes` — mis aportes a círculos
- `GET  /api/circulos/disponibles` — círculos abiertos para unirse
- `POST /api/circulos` — crear círculo `{ nombre, gremio, montoPorTurno }`
- `POST /api/circulos/:id/unirse` — unirse a un círculo
- `POST /api/circulos/:id/aportar` — aportar a un círculo `{ monto }`
- `GET  /api/marketplace/entidades` — cajas/cooperativas aliadas
- `GET  /api/marketplace/mis-solicitudes` — mis solicitudes al marketplace
- `POST /api/marketplace/solicitudes` — enviar solicitud a una entidad `{ entidadId, monto }`
- `GET  /api/perfil` — datos del usuario
- `POST /api/perfil` / `PUT /api/perfil` — crear/actualizar datos del usuario
- `POST /api/perfil/dni` — guardar referencia a la foto de DNI subida a `kyc-documents` `{ storagePath }`
- `POST /api/perfil/foto` — guardar referencia a la foto de perfil subida a `avatars` `{ storagePath }`

Todas las rutas (excepto `/health` y `/api/reniec/:dni`) requieren el header:
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
   │  (1) Registro/login con DNI verificado vía RENIEC -> contra Supabase Auth
   │      (email sintético <dni>@dni.movicash.pe + contraseña)
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
- El pase visual de diseño ya cubre las 12 pantallas principales: Splash, Inicio, MoviScore, Mi crédito, Solicitar crédito, Perfil, Mis datos, Comunidad, Círculos, Movimientos, Marketplace, Configuración y Ayuda.

## 6. Próximos pasos sugeridos

- Conectar una pasarela de pagos real (Culqi/Niubiz) o interoperabilidad con
  Yape/Plin para el cobro/desembolso de dinero real.
- Agregar notificaciones push (Firebase Cloud Messaging) para recordar el
  pago diario.
- Endurecer el motor de MoviScore con más señales (atrasos, frecuencia de uso).
- El APK actual está firmado con la key de **debug** de Flutter — antes de
  publicar en Play Store hay que generar un keystore propio y firmar en
  modo release real.
