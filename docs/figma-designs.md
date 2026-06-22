# Diseños faltantes en Figma

Página: **App Conductor** (node-id=93:2)

---

## 1. Conductor · Viaje en curso (Ride In Progress)

**Frame:** 440×956 px

### Header (altura 64px)
- Fondo: `#1E8E5A` (verde)
- Texto izquierdo: ← flecha + "Viaje en curso", blanco, 18px
- Cuando aún no inicia: "Llegada al origen" con gris `#6B6661` 12px abajo

### Mapa (altura 380px)
- Tile map background simulado
- Marker conductor: círculo `#1E8E5A` 32px con icono moto, borde blanco 3px
- Marker origen: círculo `#FF8F00` 28px
- Marker destino: círculo `#D32F2F` 28px

### Bottom sheet (fondo blanco, esquinas superiores redondeadas 20px)
1. Avatar pasajero: círculo 48px `#FFF1E0`, iniciales `#FF8F00`
2. Nombre pasajero: `#1A1410`, 16px, bold
3. Ruta: "Origen → Destino", `#6B6661`, 13px
4. Botón primario:
   - Antes de iniciar: "Iniciar viaje" sobre `#FF8F00`, 56px altura
   - Después de iniciar: "Completar viaje" sobre `#1E8E5A`

---

## 2. Conductor · Evaluar pasajero (Ride Evaluation)

**Frame:** 440×956 px

### Estados: Formulario / Confirmación

### Estado formulario
- AppBar: "Evaluar pasajero"
- Avatar grande: 80px círculo `#FFF1E0`, icono persona `#FF8F00`
- Texto: "¿Cómo fue tu pasajero?", `#1A1410`, 22px bold
- **5 estrellas** para calificar:
  - Llenas: `#FF8F00`, 44px
  - Vacías: `#E2E2E2`, 44px
  - Labels debajo: "Muy malo", "Malo", "Regular", "Bueno", "Excelente"
- TextField comentario:
  - 3 líneas, max 200 caracteres
  - Hint: "Agrega un comentario (opcional)"
  - Border radius 8px
  - Focused border: `#FF8F00`
- Botón: "Enviar evaluación" sobre `#FF8F00`, 54px altura

### Estado confirmación
- Icono check: 80px círculo `#1E8E5A`12, icono `#1E8E5A` 48px
- "¡Evaluación enviada!" `#1A1410` 22px bold
- "Gracias por tu retroalimentación" `#6B6661`
- Botón: "Volver al inicio" sobre `#FF8F00`

---

## Cómo agregar a Figma

1. Abrir el archivo Figma: [Viaje Seguro](https://www.figma.com/design/zirPgA33aP6jYpxdue1k2b/Viaje-Seguro?node-id=93-2)
2. Seleccionar página **App Conductor**
3. Usar Frame tool (F), tamaño **440×956**
4. Agregar rectángulos, textos y shapes según las especificaciones arriba
5. **Colores del design system** (ya existen en el archivo):
   - `Jala/Primary` → `#FF8F00`
   - `Jala/Ink` → `#1A1410`
   - `Jala/Ink Soft` → `#6B6661`
   - `Jala/Border` → `#E2E2E2`
   - `Jala/Surface` → `#FDFBF7`
   - `Jala/Green` (no existe, crear) → `#1E8E5A`
   - `Jala/Red` → `#D32F2F`
