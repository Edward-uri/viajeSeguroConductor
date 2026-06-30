# Guía de integración — Apps de Pasajero y Conductor (flujo de viajes)

Cómo conectar las apps al backend de ViajeSeguro: autenticación, endpoints REST y eventos
WebSocket en tiempo real. La doc completa de cada request/response está en **Swagger: `GET /api/docs`**.

- **Base URL:** `https://TU-DOMINIO` (REST y WebSocket usan el mismo host)
- **Formato:** JSON. REST sobre HTTPS; tiempo real sobre **Socket.IO**.

---

## 1. Autenticación

Todas las rutas de viajes requieren un **access token** (JWT) en el header:

```
Authorization: Bearer <accessToken>
```

### Cómo obtenerlo
Dos caminos (body exacto en Swagger):

| Método | Endpoints |
|--------|-----------|
| OTP (código por correo/SMS) | `POST /api/auth/login/start` → `POST /api/auth/login/verify` |
| Contraseña | `POST /api/auth/login/password` |

La respuesta incluye `accessToken` (corta vida, ~30 min) y `refreshToken` (larga vida).

### Renovar el token
Cuando un request devuelve **401**, renueva con:
```
POST /api/auth/refresh        body: { "refreshToken": "..." }
```
y reintenta. Guarda el `refreshToken` de forma segura (Keychain / Keystore).

> El token trae el `rol` (`pasajero` | `conductor`). El backend decide qué puede hacer cada quien;
> la app no necesita mandar el rol.

---

## 2. Estados del viaje

```
solicitado ──▶ aceptado ──▶ en_curso ──▶ completado
     │             │
     └─────────────┴────────▶ cancelado
```

La app debe pintar la UI según `estado`. Las transiciones las hace el backend; la app solo
dispara la acción (aceptar, iniciar, etc.) y **escucha los eventos** para actualizarse.

---

## 3. Objeto `Viaje` (respuesta estándar)

```jsonc
{
  "idViaje": 12,
  "idPasajero": 1,
  "idConductor": 5,            // null hasta que alguien acepta
  "idVehiculo": 30,            // null hasta que alguien acepta
  "idMunicipio": 10,
  "tipoServicio": "viaje",
  "origen":  { "lat": 16.62, "lng": -93.09, "texto": "Calle X" },
  "destino": { "lat": 16.63, "lng": -93.08, "texto": "Calle Y" },
  "idZonaDestino": 3,
  "distanciaKm": 2.4,
  "numPasajeros": 2,
  "tarifa": 30,               // precio fijo de tabla × personas (sin decimales inventados)
  "tarifaEstimada": false,    // true si se usó la tarifa por defecto del municipio
  "estado": "aceptado",
  "fechaSolicitud": "2026-06-29T18:00:00Z",
  "fechaAceptacion": "2026-06-29T18:01:00Z",
  "fechaInicio": null,
  "fechaFin": null,
  "canceladoPor": null,
  "motivoCancelacion": null
}
```

---

## 4. Endpoints REST

> Las listas responden `{ "data": [ ... ] }`. Los objetos sueltos responden el `Viaje` directo.

### Comunes / Pasajero

| Acción | Request | Notas |
|--------|---------|-------|
| Tarifario del municipio | `GET /api/municipios/:id/tarifas` | Público. `{ data: [{ idZona, nombre, precio }] }` |
| **Estimar** tarifa | `POST /api/viajes/estimar` | Ver body abajo. No crea nada |
| **Crear** viaje | `POST /api/viajes` | Body igual que estimar. Devuelve `Viaje` (201) |
| Mis viajes | `GET /api/viajes/mios` | Historial del pasajero |
| Ver un viaje | `GET /api/viajes/:id` | Solo el pasajero o el conductor del viaje |
| Cancelar | `POST /api/viajes/:id/cancelar` | Body: `{ "motivo": "opcional" }` |
| Evaluar | `POST /api/viajes/:id/evaluacion` | `{ "calificacion": 1..5, "comentario": "opcional" }` |
| Registrar token push | `POST /api/dispositivos` | `{ "tokenFcm": "...", "plataforma": "android"\|"ios" }` |

**Body de estimar / crear:**
```jsonc
{
  "idMunicipio": 10,
  "origen":  { "lat": 16.62, "lng": -93.09, "texto": "opcional" },
  "destino": { "lat": 16.63, "lng": -93.08, "texto": "opcional" },
  "personas": 2,            // 1 a 3. Default 1
  "idZonaDestino": 3        // opcional: si lo mandas, usa esa tarifa fija directo
}
```

**Respuesta de `/estimar`** (muestra el desglose para la UI):
```jsonc
{
  "distanciaKm": 2.4,
  "duracionMin": 8,
  "personas": 2,
  "tarifaPorPersona": 15,   // precio unitario fijo de la zona
  "tarifa": 30,             // total = tarifaPorPersona × personas
  "tarifaEstimada": false,
  "idZonaDestino": 3,
  "ruta": { "type": "LineString", "coordinates": [[lng,lat], ...] }  // para dibujar en el mapa
}
```

### Conductor (rol `conductor`)

| Acción | Request | Notas |
|--------|---------|-------|
| Viajes pendientes | `GET /api/viajes/pendientes` | Solicitados en su municipio, sin los que ya rechazó |
| Mis viajes asignados | `GET /api/viajes/asignados` | Historial del conductor |
| **Aceptar** | `POST /api/viajes/:id/aceptar` | Body: `{ "idVehiculo": 30 }` |
| **Iniciar** | `POST /api/viajes/:id/iniciar` | Pasa a `en_curso` |
| **Completar** | `POST /api/viajes/:id/completar` | Pasa a `completado` |
| **Rechazar** | `POST /api/viajes/:id/rechazar` | 204. No vuelve a aparecerle en pendientes |

**Reglas que el backend impone (la app debe manejar el error):**
- Un pasajero **no** puede tener dos viajes activos → `409 PasajeroConViajeActivo` al crear.
- Un conductor **no** puede aceptar si ya trae uno activo → `409` al aceptar.
- Si **otro conductor ya aceptó** ese viaje, tu aceptar devuelve `409` (transición inválida) →
  quítalo de la lista y muestra "ya fue tomado".

---

## 5. Tiempo real (Socket.IO)

### Conexión
Mismo host. El token va en `auth.token` del handshake:

```js
import { io } from 'socket.io-client';

const socket = io('https://TU-DOMINIO', {
  auth: { token: accessToken },     // el MISMO access token del REST
  transports: ['websocket'],
});

socket.on('connect_error', (e) => { /* token vencido → refresca y reconecta */ });
```

Al conectar, el backend te mete automáticamente a tu sala personal (por usuario) y, si eres
conductor, a tu sala de conductor. **No manejas salas a mano.**

### App del PASAJERO

**Escucha:**
```js
socket.on('viaje:aceptado', (viaje) => { /* un conductor aceptó: pinta "en camino" */ });
socket.on('viaje:cambio_estado', ({ idViaje, estado }) => { /* en_curso, completado, cancelado */ });
socket.on('viaje:ubicacion_conductor', ({ idViaje, lat, lng }) => { /* mueve el pin del conductor */ });
```
No emite nada por socket; sus acciones (crear, cancelar) van por REST.

### App del CONDUCTOR

**1) Ponerse en línea** (necesario para recibir viajes de su municipio):
```js
socket.emit('conductor:online', { idMunicipio: 10 }, (res) => {
  // res.ok === true si quedó en línea. El municipio se valida en el server.
});
```

**Escucha:**
```js
socket.on('viaje:solicitado', (viaje) => { /* nuevo pendiente: agrégalo a la lista */ });
socket.on('viaje:no_disponible', ({ idViaje }) => { /* otro lo tomó o se canceló: quítalo de la lista */ });
socket.on('viaje:cambio_estado', ({ idViaje, estado }) => { /* sincroniza tu viaje activo */ });
```

**2) Mandar su ubicación** mientras lleva un viaje (`aceptado` o `en_curso`), cada pocos segundos:
```js
socket.emit('conductor:ubicacion', { idViaje, lat, lng });
// el backend la reenvía al pasajero como 'viaje:ubicacion_conductor'
```

**3) Salir de línea:**
```js
socket.emit('conductor:offline');
```

---

## 6. Flujo completo de punta a punta

```
PASAJERO                         BACKEND                          CONDUCTOR (en línea)
  │  POST /viajes/estimar  ───────▶ (muestra tarifa)
  │  POST /viajes          ───────▶ crea (solicitado) ──emit──▶  viaje:solicitado
  │                                                              (acepta el viaje)
  │  ◀──emit viaje:aceptado──────── POST /viajes/:id/aceptar ◀────┤
  │                                 ──emit viaje:no_disponible──▶ (resto: quítalo de la lista)
  │  ◀─emit viaje:cambio_estado──── POST /viajes/:id/iniciar  ◀───┤ (en_curso)
  │  ◀─emit ubicacion_conductor──── conductor:ubicacion (loop) ◀──┤
  │  ◀─emit viaje:cambio_estado──── POST /viajes/:id/completar ◀──┤ (completado)
  │  POST /viajes/:id/evaluacion ─▶
```

---

## 7. Códigos de error

Formato: `{ "error": "mensaje", "code": "CODIGO" }` (o detalle de validación en 400).

| HTTP | Cuándo |
|------|--------|
| 400 | Body inválido (zod) |
| 401 | Sin token o vencido → refresca y reintenta |
| 403 | No es tu viaje / vehículo no autorizado / rol incorrecto |
| 404 | Viaje / vehículo no encontrado |
| 409 | Transición inválida (ya lo tomaron), pasajero o conductor con viaje activo |
| 429 | Rate limit (sobre todo en `/api/auth/*`) → reintenta con backoff |

---

## 8. Checklist de implementación

**Pasajero**
- [ ] Login → guardar access/refresh; interceptor que renueva en 401
- [ ] Conectar socket con el token
- [ ] Estimar → mostrar `tarifa` y `tarifaPorPersona` antes de confirmar
- [ ] Crear viaje → pintar "buscando conductor"
- [ ] Escuchar `viaje:aceptado`, `viaje:cambio_estado`, `viaje:ubicacion_conductor`
- [ ] Registrar token FCM para push

**Conductor**
- [ ] Login → guardar tokens; renovar en 401
- [ ] Conectar socket + `conductor:online { idMunicipio }`
- [ ] Listar `/pendientes` y escuchar `viaje:solicitado` / `viaje:no_disponible`
- [ ] Aceptar con `idVehiculo`; manejar 409 ("ya fue tomado")
- [ ] Loop de `conductor:ubicacion` mientras `aceptado`/`en_curso`
- [ ] Iniciar → Completar; `conductor:offline` al cerrar sesión
```
