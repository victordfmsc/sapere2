# Backend de Sapere en Cloud Functions

Sustituye al backend de Railway (`sapere-backend`) para la creación de audiodocumentales.
Ya **no se genera audio en el servidor**: la voz la pone el lector bimodal del dispositivo
(`lib/features/local_reader`, flutter_tts), así que los documentos nuevos se guardan con
`bukbukUrl: ''` y la app debe tratarlos como válidos igualmente.

- Proyecto Firebase: **sapere-f7150**
- Región: **europe-west1** (Firestore está en `eur3`; no cambies la región o las llamadas cruzarán continente)
- Runtime: Node 22, CommonJS, `firebase-functions` v6, `firebase-admin` v13
- Bucket de Storage: `sapere-f7150.firebasestorage.app` (el predeterminado del proyecto)

## Proveedores

| Qué | Quién | Notas |
|---|---|---|
| Texto (título, escaleta, guion) | **Space privado de Hugging Face `Bukbuk/DocuGenerator`** (FastAPI + `deepseek-reasoner`) | Único generador de texto. **Sin respaldo** a otro modelo: si el Space falla, la tarea reintenta o termina en `error` con reembolso. |
| Portada | OpenAI (`gpt-image-2`) → Pollinations | Prompt visual construido con título + tema, sin modelo de texto. |
| Créditos | RevenueCat (moneda virtual) → reserva heredada `users/{uid}.credits` | Sin cambios. |

Ya no se usan el router de Hugging Face (`HF_MODEL`), Gemini ni el chat de OpenAI.

> **Aviso: saldo de DeepSeek.** El Space paga a DeepSeek con su propia clave. Si la cuenta se queda
> sin saldo, DeepSeek responde `402 Insufficient Balance`: la generación termina al momento en
> `error` con el mensaje `DeepSeek sin saldo (Insufficient Balance)...` y **se reembolsa el crédito**.
> No se reintenta hasta recargar. Lo mismo con una clave inválida o sin configurar en el Space.

### Notas del Space

- **Privado**: toda llamada lleva `Authorization: Bearer <HF_TOKEN>`; lo valida el proxy de Hugging Face.
- **Se duerme tras 48 h sin uso** (`gcTimeout` 172800). Si una llamada falla por red, 404, 502, 503 o 504,
  la función consulta `GET https://huggingface.co/api/spaces/Bukbuk/DocuGenerator/runtime`:
  `SLEEPING`/`STOPPED` → pide `POST .../restart` y sondea cada 10 s hasta `RUNNING` (máx. 180 s) y
  reintenta la llamada una vez; `BUILDING`/`APP_STARTING` → sondea; `PAUSED`, `RUNTIME_ERROR`,
  `BUILD_ERROR` → fatal (hay que arreglarlo en Hugging Face; un Space `PAUSED` no se despierta solo);
  401/403/404 del runtime → fatal `HF_TOKEN sin acceso al Space Bukbuk/DocuGenerator`.
- **Atiende una generación cada vez**: itera el stream de DeepSeek de forma síncrona y bloquea su bucle
  de eventos. Por eso `generateStory` limita la cola a 2 tareas simultáneas y hace las llamadas de cada
  documental en serie. Con dos documentales a la vez, la segunda llamada puede esperar a la primera y
  cortarse por el tope de 150 s sin datos: es un fallo reintentable y la tarea se reanuda sola.
- Cada sección es una llamada a `POST /documentary/{area}` con `stream: true`, nivel `intermedio`,
  `max_tokens` 4096 y un **`conversation_id` nuevo**; se manda el historial completo (texto bruto de las
  secciones anteriores, nunca el razonamiento) y la petición siempre termina en un mensaje `user`.
  Después se borra la conversación (`DELETE /conversations/{id}`, en segundo plano, tope de 5 s).
- Topes por sección: 420 s en total y 150 s sin recibir bytes.

---

## 1. Funciones exportadas

| Export | Tipo | Región | Detalles | Secretos |
|---|---|---|---|---|
| `startStory` | `onCall` (https v2) | europe-west1 | 256 MiB, 120 s | RevenueCat |
| `generateStory` | `onTaskDispatched` (tasks v2) | europe-west1 | 512 MiB, **1800 s**, `maxAttempts: 5`, `minBackoffSeconds: 60`, `maxConcurrentDispatches: 2` | `HF_TOKEN`, `OPENAI_API_KEY`, RevenueCat |
| `sweepStalled` | `onSchedule` (scheduler v2) | europe-west1 | 256 MiB, 300 s, `every 5 minutes` | RevenueCat |
| `creditsBalance` | `onCall` (https v2) | europe-west1 | 256 MiB, 30 s | RevenueCat |

RevenueCat = `REVENUECAT_SECRET_KEY` + `REVENUECAT_PROJECT_ID`.

### `startStory`

```js
// Flutter: FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('startStory')
data = {
  prompt: string,                 // obligatorio
  languageCode: string,           // obligatorio, xx_YY (p.ej. 'es_ES')
  language?: string,              // nombre largo; si falta se deduce ('Spanish (Spain)')
  systemPrompt?: string,          // solo para type 'gamification_episode' (persona, max 4000 car.); en el resto se ignora
  genre?: string,
  type?: 'sapere' | 'preview' | 'gamification_episode',   // por defecto 'sapere'
  coverUrl?: string,              // solo si es del bucket del proyecto; si no, se genera portada
  chapters?: number,              // SE IGNORA: duración y secciones las decide el servidor por tipo
  bukbukId?, bukbukCategoryId?, bukbukTypeNames?, bukbukCategoryNames?,
  gamificationSubject?, gamificationEpisode?
}
// respuesta
{ docId: string, status: 'pending', credits: { revenuecat: number, legacy: number, total: number } }
```

**Duración por tipo** (constantes `GENERATION_PLANS` en `src/config.js`):

| `type` | Duración | Secciones | Escaleta |
|---|---|---|---|
| `sapere` | 30 min | 6 | sí |
| `gamification_episode` | 20 min | 4 | sí |
| `preview` | 5 min | 1 | no |

Errores (`HttpsError`): `unauthenticated`, `invalid-argument` (falta `prompt` o `languageCode`, o
superan los topes: `prompt` 4000 caracteres, `genre`/`language`/ids 200; se valida antes de cobrar),
`failed-precondition` con mensaje `already_generating`, `resource-exhausted` con mensaje
`insufficient_credits`, `unavailable` (no se pudo leer el tipo), `internal`. **Si algo falla después de
cobrar, se reembolsa el crédito.** El encolado usa `dispatchDeadlineSeconds: 1800`, igual al timeout de
`generateStory`, para que Cloud Tasks no relance una tarea que sigue viva.

### `generateStory` (no se llama desde la app)

Payload `{ docId, uid }`. La encola `startStory` con Cloud Tasks. Es idempotente: si el documento
ya está `completed`, en `error` o con el crédito devuelto, sale sin escribir nada; `error` es
terminal y nada lo pasa a `completed`.

**Marco del documental.** Lo decide `startStory` antes de cobrar y queda en `generation.systemPrompt`
(`generation.systemPromptSource` dice de dónde salió). Solo se envía al Space con `type` o
`gamification_client`:
- `type`: el prompt del tipo elegido, leído por el servidor de `sapereCategories/{bukbukCategoryId}/sapereTypes/{bukbukId}.prompts` (idioma exacto, otra variante del mismo idioma, luego `en_US` o `es_ES`). Los ids se validan antes de construir la ruta.
- `gamification_client`: la persona que arma la app para un episodio de gamificación, acotada a 4000 caracteres.
- `framework`: ninguno de los anteriores; `systemPrompt` queda vacío y el Space usa solo su propio prompt.

**Área del Space**: primero por id de categoría conocido (Artes → `arte_cultura`, Imagina el futuro →
`tecnologia`, Formas de aprender y Crecimiento y mentalidad → `psicologia_mente`, Historias Humanas →
`biografias`, Explora el mundo y Aprende Algo Nuevo → `general`, Historia → `historia`); si no, por
palabras clave sin tildes ni emojis en `genre`, `bukbukCategoryNames` y `gamificationSubject` (incluidas
las 7 categorías de gamificación en los 29 idiomas de la app); si no, `general`. **Idioma**: nombre en
español derivado de `languageCode` (`es_MX` → `español de México`, `zh_TW` → `chino tradicional`...).

Pasos:

0. **Latido de inicio de intento**: `generation.attemptStartedAt`, `generation.awaitingRetry: false` y `updatedAt`.
1. **Título** con `POST /generate/title` → `bukbukName` + estado `generating_title`. Si falla sin ser
   fatal, el título es el tema recortado (no es un error); si el fallo es fatal, no hay título de
   respaldo ni portada: el documento va a `error` + reembolso.
2. **Portada** en paralelo con el guion: OpenAI → Pollinations (cada petición con tope de 120 s), sube
   `covers/<docId>.png` y escribe `newCover`. Al cerrar se espera como mucho 2 min (y nunca más allá del
   plazo de la invocación); si no ha llegado, el documento se cierra sin ella.
3. **Escaleta** con `POST /generate/outline` (solo con 4 o más secciones) → campo `outline`; se reutiliza
   en los reintentos. Si falla sin ser fatal se sigue sin ella.
4. **Secciones** encadenadas, una llamada por sección. Cada una guarda en `chaptersMeta[i]` su texto
   bruto (`raw`) y su título (del encabezado `## ...`), y añade sus párrafos a `description` (sin
   marcadores markdown; el texto del encabezado queda como párrafo). Tras la primera: `readyToRead: true`,
   estado `generating_script` y, en la misma transacción, `deliveredAt` en el gasto (`creditSpends`).
   Al terminar la última: `completed`, gasto liquidado y cerrojo suelto. Si el dueño borra el documento
   cuando ya tenía texto, la tarea liquida el gasto y suelta el cerrojo.

**Errores**:
- **Fatales** (sin reintento: `error` + reembolso, y `closedInErrorAt` en el gasto): sin acceso al
  Space, Space pausado o roto, DeepSeek sin saldo, clave de DeepSeek inválida o sin configurar, 400/422
  del Space o de DeepSeek (petición rechazada, también dentro de un evento SSE `error`).
- **Reintentables** (Cloud Tasks reintenta y se **reanuda desde `chaptersMeta`** sin repetir secciones):
  timeouts, stream cortado sin evento `done`, sección vacía, 5xx, 429, red. Antes de lanzar se escribe
  `generation.lastError`, `generation.awaitingRetry: true` y `updatedAt`.
- En el **último intento** (el 5.º) cualquier fallo → `error` + reembolso.
- **Guarda de plazo**: si quedan menos de 8 minutos de invocación no se empieza otra sección; se lanza un
  error reintentable y el siguiente intento continúa. Dentro de la sección, el Space no se despierta ni
  se repite la llamada si no caben despertar (3 min) + sección (7) + reserva (1), y la sección se corta
  como muy tarde 1 min antes del plazo.

### `sweepStalled`

Cada 5 minutos, releyendo cada documento en una transacción:

- Atascados en `pending` / `generating_*` con más de **45 minutos** sin escribir: si ya tienen texto
  legible se cierran como `completed` parcial y el gasto se liquida (sin reembolso); si no, `error` +
  reembolso. Lo que solo espera turno en la cola de Cloud Tasks (`pending` sin `attemptStartedAt`, o
  `awaitingRetry: true`) usa su propio tope, **220 minutos** (`QUEUE_STALE_MS`). Al cerrar deja en el
  gasto `deliveredAt` (parcial) o `closedInErrorAt` (error).
- Conciliación sobre `creditSpends` (`settled == false` y `refunded == false`, con más de 45 minutos),
  que es la fuente de verdad porque el cliente no puede escribirla: documento `completed` → se
  liquida; inexistente con `deliveredAt` y sin `closedInErrorAt` (el dueño lo borró después de leerlo)
  → se liquida; en `error` o inexistente sin entrega (o cerrado en error por el servidor: la app borra
  el fallido al reintentar) → se reembolsa; cargo sin confirmar → `needs_review`.

Tiempos coherentes: cada paso de la generación escribe `updatedAt` y el peor caso de un paso (llamada
fallida + despertar el Space + sección, unos 13 min) queda por debajo de los 45 min; el cerrojo por
usuario y `hasActiveGeneration` usan 60 min (≥ 45 + intervalo del barrido), y `hasActiveGeneration`
usa 235 min para lo que está en cola.

Nunca reembolsa dos veces (transacción sobre el documento de gasto, y la misma `Idempotency-Key` de
RevenueCat en todos los intentos) y, si el ajuste de saldo falla, lo reintenta como mucho 2 veces,
separadas 10 min, antes de dejar el gasto en `refundState: 'needs_review'`. Un 401, 403, 429 o 503 de
RevenueCat no cuenta como intento: no aplicó nada.

### `creditsBalance`

Sin datos de entrada. Devuelve `{ revenuecat, legacy, total }` del usuario autenticado.

---

## 2. Documento de Firestore (colección `sapere`, id = `docId`)

```
uId, postId (= docId), type, bukbukName, description (array de párrafos),
bukbukUrl (''), newCover, coverImage (''), language, languageCode,
bukbukId, bukbukCategoryId, bukbukTypeNames, bukbukCategoryNames,
prompt, genre, publishTime, updatedAt, status, errorMessage, readyToRead,
outline                                         // escaleta del Space (si hay 4+ secciones)
chaptersMeta: [{ index, title, paragraphs, raw }] // paragraphs = nº de párrafos; raw = texto bruto de la sección
generation: {
  engine: 'firebase', textProvider ('docugen'), coverProvider, chapters, durationMinutes, area,
  spendId, refunded, startedAt, finishedAt, systemPrompt, systemPromptSource, lastError
}
```

Estados: `pending` → `generating_title` → `generating_script` → `completed` | `error`.
El estado nunca retrocede (ver `STATUS_RANK` en `src/story.js`).

---

## 3. Secretos y variables

### Secretos (Secret Manager) — uno por uno, pega el valor cuando lo pida

```bash
firebase functions:secrets:set HF_TOKEN
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set REVENUECAT_SECRET_KEY
firebase functions:secrets:set REVENUECAT_PROJECT_ID
```

- `HF_TOKEN`: token de Hugging Face (`hf_...`) con **lectura** sobre el Space privado `Bukbuk/DocuGenerator`.
  Con permiso de **escritura** además puede reiniciarlo cuando está dormido; con uno de solo lectura el
  reinicio se ignora y la función se limita a sondear el estado.
- `OPENAI_API_KEY`: clave de OpenAI (`sk-...`). Solo para la portada.
- `REVENUECAT_SECRET_KEY`: *secret key* v2 con permisos de lectura/escritura sobre
  *Customer Purchases Configuration* y *Customer Configuration*.
- `REVENUECAT_PROJECT_ID`: id del proyecto de RevenueCat.

**`GEMINI_API_KEY` ya no se usa.** Después de desplegar esta versión puede borrarse de Secret Manager:
`firebase functions:secrets:destroy GEMINI_API_KEY`.

Si pegas un `.env` entero por error, `src/sanitize.js` se queda con la primera línea y quita el
prefijo `NOMBRE=` (fue el fallo real que tumbó Railway el 2026-09-02), pero **corrígelo igualmente**.

Sin `REVENUECAT_SECRET_KEY` / `REVENUECAT_PROJECT_ID` el cobro cae automáticamente a la reserva
heredada `users/{uid}.credits`; sin `OPENAI_API_KEY` la portada la hace Pollinations (no necesita clave).
Sin `HF_TOKEN` no hay texto: la generación termina en `error` con reembolso.

### Variables (`functions/.env`, no se sube a git)

```
OPENAI_IMAGE_MODEL=gpt-image-2
REVENUECAT_CURRENCY=CRD
```

`HF_MODEL` ya no existe. Los parámetros del Space y de la cola (URL, tiempos, secciones por tipo,
reintentos) son **constantes** en `src/config.js`, no variables: firebase-tools 15 en modo no
interactivo no aplica los valores por defecto de `defineString`. `gpt-image-1` se apaga el 23-10-2026:
el modelo es `gpt-image-2` (exige organización verificada en OpenAI); si se configura otro y falla, se
reintenta con `gpt-image-2`, y si falla `gpt-image-2` la portada la hace Pollinations.

---

## 4. APIs de Google que hay que habilitar

En el proyecto `sapere-f7150` (Consola de Google Cloud → APIs y servicios):

- `cloudfunctions.googleapis.com`
- `cloudbuild.googleapis.com`
- `artifactregistry.googleapis.com`
- `run.googleapis.com`
- `eventarc.googleapis.com`
- `cloudtasks.googleapis.com` ← obligatoria para `generateStory`
- `cloudscheduler.googleapis.com` ← obligatoria para `sweepStalled`
- `secretmanager.googleapis.com`
- `firestore.googleapis.com`, `storage.googleapis.com`

De un tirón:

```bash
gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com run.googleapis.com eventarc.googleapis.com \
  cloudtasks.googleapis.com cloudscheduler.googleapis.com secretmanager.googleapis.com \
  --project sapere-f7150
```

La cuenta de servicio en tiempo de ejecución necesita además `roles/cloudtasks.enqueuer` para que
`startStory` pueda encolar (el despliegue de Firebase suele concederlo solo; si ves
`PERMISSION_DENIED` al encolar, dáselo a mano a la cuenta
`<numero-de-proyecto>-compute@developer.gserviceaccount.com`).

---

## 5. Despliegue

### Orden obligatorio

Las reglas nuevas de `firestore.rules` y `storage.rules` impiden crear documentos `sapere` desde el cliente,
cierran la colección `keys` y cambian las rutas de Storage. Las versiones publicadas de la app (1.3.0 y
anteriores) todavía crean esos documentos desde el cliente y cobran a través de Railway, así que **desplegar
las reglas antes de tiempo rompe la creación para todos los usuarios**. Las funciones, en cambio, funcionan
con las reglas actuales: el Admin SDK no pasa por ellas.

1. Plan Blaze activo en `sapere-f7150`.
2. Secretos creados (sección 3), APIs habilitadas y permiso de encolado (sección 4).
3. Saldo en la cuenta de DeepSeek del Space y Space en `RUNNING`.
4. `firebase deploy --only functions` y una creación de prueba de extremo a extremo con un usuario de prueba.
5. Distribuir la app 1.4.0 (`AppConfig.useFirebaseGeneration = true`) y esperar a que los usuarios actualicen.
6. Solo entonces: `firebase deploy --only firestore:rules,storage`.
7. Apagar Railway (web y worker) cuando ya nadie use versiones anteriores a la 1.4.0: siguen cobrando allí.

Vuelta atrás de las reglas: los rulesets anteriores son `65e10dfc-7510-4a9f-9fff-242913e86d8b` (Firestore) y
`76d9409b-1078-4e22-9805-6e17ff2dfd15` (Storage). Se restauran desde la consola, en el historial de reglas.

```bash
firebase login                                   # la sesión de la CLI estaba caducada
firebase use sapere-f7150
firebase deploy --only functions                 # las cuatro funciones
firebase deploy --only storage                   # SOLO en el paso 6 del orden obligatorio
```

El `predeploy` de `firebase.json` ejecuta `npm test` en `functions/`: si un test falla, no se
despliega. Para saltártelo puntualmente, borra el bloque `predeploy` o usa `--force`.

Al desplegar, la cola de Cloud Tasks `generateStory` (`europe-west1`) toma los nuevos `retryConfig` y
`rateLimits`. `src/config.js` la referencia como `locations/europe-west1/functions/generateStory` — sin el
prefijo `locations/...`, `firebase-admin` la buscaría en `us-central1` y el encolado fallaría.

---

## 6. Cómo probar cada función

### Tests locales (sin red, sin emulador)

```bash
cd functions
"C:/Program Files/nodejs/npm.cmd" install
"C:/Program Files/nodejs/npm.cmd" test
```

Pruebas con `node:test`: cliente del Space (parser SSE con trozos partidos en cualquier byte,
razonamiento ignorado, evento `error`, falta de `done`, historial, `conversation_id` y `DELETE`,
despertar del Space, clasificación fatal/reintentable, timeouts, mapeos de área e idioma),
generación completa con reanudación, guarda de plazo y reembolsos, cobro y reembolso único del crédito,
portada (OpenAI → Pollinations), saneado de errores y barrido de atascados. `global.fetch` está
interceptado (`test/helpers/fetch.js`, simulador del Space en `test/helpers/space.js`) y Firestore es un
doble en memoria: **ninguna prueba sale a internet**.

### Emulador

```bash
firebase emulators:start --only functions,firestore,storage
```

`startStory` y `creditsBalance` se llaman desde la app apuntando al emulador
(`FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator('10.0.2.2', 5001)`).
Aviso: el emulador de funciones **no trae Cloud Tasks**; para probar la cadena entera exporta
`CLOUD_TASKS_EMULATOR_HOST` o invoca el núcleo a mano (con `HF_TOKEN` en el entorno):

```bash
node -e "require('firebase-admin/app').initializeApp();\
const {runStory}=require('./src/story');\
const {getFirestore}=require('firebase-admin/firestore');\
const {getStorage}=require('firebase-admin/storage');\
runStory({db:getFirestore(),bucket:getStorage().bucket(),docId:'<docId>',uid:'<uid>'}).then(console.log)"
```

### En producción

- `creditsBalance`: llámala desde la app con sesión iniciada; debe devolver el mismo saldo que
  muestra RevenueCat.
- `startStory`: crea un documento en `sapere` con `status: 'pending'` y devuelve su `docId`;
  debe pasar a `generating_title` → `generating_script` (legible tras la primera sección) → `completed`.
- `generateStory`: `firebase functions:log --only generateStory`. Busca
  `[story] <docId>: completado (N secciones, M parrafos)`, y `[docugen]` para los avisos del Space.
- `sweepStalled`: `gcloud scheduler jobs run firebase-schedule-sweepStalled-europe-west1 --location europe-west1`
  y mira el log `[sweepStalled] revisados ... marcados ... reembolsados ...`.

---

## 7. Índices de Firestore

Las consultas compuestas usan solo filtros de igualdad (`sapere`: `uId == x` + `status in [...]`;
`creditSpends`: `settled == false` + `refunded == false`), que Firestore resuelve con los índices de
campo único. El cerrojo por usuario vive en `generationLocks/{uid}` (solo servidor). Si aun así la consola pide un índice compuesto, créalo con el enlace del mensaje de
error o añade a `firestore.indexes.json`:

```json
{ "collectionGroup": "sapere", "queryScope": "COLLECTION",
  "fields": [ { "fieldPath": "uId", "order": "ASCENDING" },
              { "fieldPath": "status", "order": "ASCENDING" } ] }
```

Mientras falte, `startStory` no bloquea al usuario: registra el error y deja crear el documento
(ver `hasActiveGeneration` en `src/story.js`).

---

## 8. Mapa de ficheros

```
functions/
  index.js              startStory, generateStory, sweepStalled, creditsBalance (opciones y secretos por función)
  src/config.js         región, colecciones, tiempos, planes por tipo, constantes del Space, secretos
  src/docugen.js        cliente del Space: SSE, historial, despertar, título, escaleta, secciones, área e idioma
  src/sanitize.js       cleanEnvValue + sanitizeError (portado de sapere-backend/src/env.js)
  src/credits.js        cobro y reembolso (portado de sapere-backend/src/credits.js)
  src/revenuecat.js     moneda virtual v2 (portado de sapere-backend/src/revenuecat.js)
  src/prompts.js        prompt de portada
  src/openai.js         imágenes (gpt-image-2)
  src/text.js           limpieza y troceado en párrafos, título de sección
  src/cover.js          portada: OpenAI → Pollinations
  src/storage.js        subida con token de descarga permanente
  src/story.js          núcleo de generateStory (título, escaleta, portada, secciones, estados, reembolso)
  src/sweep.js          barrido de atascados (portado de sapere-backend/src/watchdog.js)
  test/                 node:test + dobles de Firestore, de fetch y del Space
```
