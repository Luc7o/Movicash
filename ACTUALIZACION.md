# MoviCash — Actualización: Marketplace, Perfil, KYC, Notificaciones e Ícono

## 1. Base de datos: corre 2 scripts nuevos en Supabase SQL Editor

1. `database/migration_kyc.sql` — agrega el campo de foto DNI y el bucket de Storage.
2. `database/seed.sql` — agrega 4 entidades de ejemplo al marketplace (cajas/cooperativas).

## 2. Backend: copia estos archivos a tu proyecto (mismas rutas)

```
backend/src/services/marketplace.service.ts   (nuevo)
backend/src/services/profile.service.ts       (nuevo)
backend/src/routes/marketplace.routes.ts      (nuevo)
backend/src/routes/profile.routes.ts          (nuevo)
backend/src/index.ts                          (reemplazar)
backend/render.yaml                           (nuevo, para desplegar gratis)
```

Reinicia el backend (`Ctrl+C` → `npm run dev`).

## 3. Frontend: copia estos archivos

```
frontend/lib/screens/marketplace_screen.dart   (nuevo)
frontend/lib/screens/my_data_screen.dart       (nuevo)
frontend/lib/screens/settings_screen.dart      (nuevo)
frontend/lib/screens/help_screen.dart          (nuevo)
frontend/lib/screens/circles_screen.dart       (reemplazar)
frontend/lib/screens/community_screen.dart     (reemplazar)
frontend/lib/screens/profile_screen.dart       (reemplazar)
frontend/lib/services/api_service.dart         (reemplazar)
frontend/lib/services/notification_service.dart (nuevo)
frontend/lib/main.dart                         (reemplazar)
frontend/pubspec.yaml                          (reemplazar)
frontend/assets/icon/app_icon.png              (nuevo)
```

Luego, en la terminal dentro de `frontend`:

```bash
flutter pub get
```

## 4. Genera el ícono nuevo de la app

```bash
dart run flutter_launcher_icons
```

Esto reemplaza el ícono azul de Flutter por el de MoviCash en Android automáticamente.

## 5. Cambia el nombre de la app (se ve debajo del ícono en el celular)

Abre `android/app/src/main/AndroidManifest.xml`, busca la línea:
```xml
android:label="movicash"
```
Y cámbiala por:
```xml
android:label="MoviCash"
```

## 6. Agrega permisos necesarios (cámara para el DNI, notificaciones)

En el mismo `AndroidManifest.xml`, dentro de la etiqueta `<manifest ...>` (antes de `<application>`), agrega:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## 7. Prueba todo

```bash
flutter run
```

Prueba en orden: Comunidad > Marketplace (solicitar con una entidad), Círculos > Crear círculo nuevo, Perfil > Mis datos (sube una foto de DNI, guarda cambios), Perfil > Configuración (activa el recordatorio de pago), Perfil > Ayuda.

## 8. Backend en un servidor real (gratis)

Cuando quieras que la app funcione fuera de tu casa (para que tu hermana la use sin que tu PC esté prendida):

1. Crea cuenta en https://render.com (tiene plan gratuito).
2. Conecta tu repositorio de GitHub.
3. Render va a detectar el archivo `render.yaml` automáticamente.
4. Agrega tus variables de entorno reales (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`) en el panel de Render — **nunca las escribas directo en el código**.
5. Cuando tengas la URL pública que te da Render (algo como `https://movicash-backend.onrender.com`), actualiza `frontend/.env`:
   ```
   API_BASE_URL=https://movicash-backend.onrender.com/api
   ```
6. Genera un nuevo APK (`flutter build apk --release`) con esa URL ya apuntando al servidor real, y ese sí lo puedes compartir con cualquiera, no solo en tu red.

**Nota:** el plan gratuito de Render "duerme" el backend tras 15 min sin uso (tarda unos segundos en "despertar" con la primera petición) — normal y aceptable para pruebas y un piloto pequeño.

## Lo que queda pendiente (requiere dinero, lo dejamos para después)

- Conectar una pasarela de pago real (Culqi, Niubiz o Yape) para mover dinero de verdad.
- Publicar en Google Play (cuota única de $25 a Google).
- Subir el plan de Twilio para SMS reales en producción.
