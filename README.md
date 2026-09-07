# PetPulse — Guía de puesta en marcha

Este proyecto **ya tiene todo el código real** (Firebase Auth con verificación
de correo, Firestore, Storage, Google Maps, galería de fotos y chat en vivo).
Lo único que falta son pasos de configuración que **solo tú puedes hacer**
porque requieren tus propias cuentas (Google Cloud, Firebase). Sigue esto en
orden y en 30–45 minutos tendrás la app corriendo en tu celular.

## 0. Requisitos previos

- Tener [Flutter](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sin errores graves).
- Una cuenta de Google (para Firebase y Google Cloud).
- Node.js instalado (lo necesita la CLI de Firebase).

## 1. Generar las carpetas nativas del proyecto

Este paquete no incluye las carpetas `android/` e `ios/` (se generan según tu
entorno). Desde la carpeta `petpulse/`, ejecuta:

```bash
flutter create . --org com.tuempresa --project-name petpulse
flutter pub get
```

Esto crea `android/` e `ios/` sin tocar tu código en `lib/`.

## 2. Crear el proyecto en Firebase

1. Ve a [console.firebase.google.com](https://console.firebase.google.com) y crea un proyecto (ej. "PetPulse").
2. Dentro del proyecto, activa:
   - **Authentication** → pestaña "Sign-in method" → activa **Correo electrónico/contraseña**.
   - **Firestore Database** → "Crear base de datos" → modo producción.
   - **Storage** → "Comenzar" → modo producción.
3. Instala las herramientas de Firebase y conecta tu proyecto Flutter:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

`flutterfire configure` te va a preguntar qué proyecto de Firebase usar y para
qué plataformas (elige Android y iOS). Esto **reemplaza automáticamente**
`lib/firebase_options.dart` con tus claves reales. No lo edites a mano.

4. Sube las reglas de seguridad incluidas en este proyecto:

```bash
firebase deploy --only firestore:rules,storage:rules
```

(Los archivos `firestore.rules` y `storage.rules` ya están listos en la raíz del proyecto.)

## 2b. Si pruebas en Chrome/Web: configura CORS para Storage

**Si subes una foto (perfil, mascota o carnet) y la pantalla se queda
"cargando" para siempre**, es casi seguro este problema: el navegador
exige que el bucket de Storage tenga CORS configurado, o bloquea la
subida silenciosamente. En Android/iOS esto no pasa nunca. (Ya agregué un
timeout de 25s para que al menos te muestre el error en vez de girar para
siempre.)

Arreglo (una sola vez, con Google Cloud SDK instalado — `gcloud`/`gsutil`):

```bash
gcloud auth login
gsutil cors set cors.json gs://TU_PROJECT_ID.appspot.com
```

(El archivo `cors.json` ya viene incluido en la raíz de este proyecto.)
Reemplaza `TU_PROJECT_ID` por el ID de tu proyecto de Firebase (lo ves en
la consola de Firebase, arriba a la izquierda, o en
`lib/firebase_options.dart`).

Si no quieres lidiar con esto ahora, lo más simple es probar la app en un
**emulador o celular Android** (`flutter run` sin `-d chrome`): ahí no
existe el problema de CORS porque no es un navegador.

## 3. Ubicación (pendiente, sin Google Maps por ahora)

Para poder emular rápido sin depender de una API Key, la ubicación se
maneja por ahora con un simple campo de texto (ciudad/dirección) tanto en
el perfil del adoptante como al publicar una mascota. No necesitas hacer
nada aquí.

Cuando quieras activar el mapa real, el modelo (`UserProfile` y `Pet`) ya
tiene los campos `latitude`/`longitude` listos para usarse — solo hay que
volver a agregar `google_maps_flutter` al `pubspec.yaml`, restaurar un
selector de mapa, y seguir los pasos de API Key de Google Cloud que ya
conoces (Maps SDK for Android/iOS + Places API).

## 4. Permisos del dispositivo

Agrega estos permisos (necesarios para cámara, galería y ubicación):

**Android** — `android/app/src/main/AndroidManifest.xml` (fuera de `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```
También sube `minSdkVersion` a **21** o más en `android/app/build.gradle`.

**iOS** — `ios/Runner/Info.plist`, agrega:
```xml
<key>NSCameraUsageDescription</key>
<string>PetPulse necesita tu cámara para tomar fotos de perfil y mascotas.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PetPulse necesita tu galería para elegir fotos.</string>
```

## 5. Correr la app

```bash
flutter pub get
flutter run
```

Prueba el flujo completo: regístrate con un correo real → revisa tu bandeja
de entrada y confirma el enlace → completa tu perfil (foto obligatoria,
ubicación en el mapa) → explora o publica una mascota → envía/recibe una
solicitud → chatea en tiempo real.


## Estructura del proyecto

```
lib/
  main.dart                     # Firebase init + AuthGate (enrutamiento por rol/estado)
  firebase_options.dart         # Generado por flutterfire configure
  theme/app_theme.dart          # Paleta de colores y estilos globales
  models/models.dart            # UserProfile, Pet, AdoptionMatch, ChatMessage
  services/
    auth_service.dart           # Registro, login, verificación de correo real
    firestore_service.dart      # Perfiles, mascotas, matches, chat en tiempo real
    storage_service.dart        # Subida de fotos y documentos a Firebase Storage
  widgets/shared_widgets.dart   # Selector de foto/galería, badges, botones
  screens/
    auth/                       # Login, registro, verificación de correo
    onboarding/                 # Flujo multi-paso + selector de ubicación (Maps)
    adopter/                    # Explorar, matches, chats, perfil (adoptante)
    shelter/                    # Panel técnico: solicitudes, publicar, chats, org.
firestore.rules                 # Reglas de seguridad de la base de datos
storage.rules                   # Reglas de seguridad de archivos
```

## ¿Qué es real y qué es simulado?

Todo lo descrito arriba es **real y funcional** una vez configurado:
correo de verificación (lo envía Firebase), fotos de galería/cámara
(`image_picker`), archivos PDF (`file_picker`), y chat en vivo (Firestore
streams, sin necesidad de refrescar). No hay datos de ejemplo (`mock`) en
ninguna pantalla: todo lee y escribe directamente en tu proyecto de
Firebase. La única pieza pendiente es el mapa de ubicación (por ahora es
un campo de texto simple), tal como lo pediste.
