# Ficha de Google Play — borrador

Todo lo de esta página se copia y pega en Play Console. Los límites de
caracteres son los que impone la tienda; los textos ya están dentro.

---

## Nombre de la aplicación · máx. 30

```
Mandalas: crear y colorear
```
*(25 caracteres)*

## Descripción corta · máx. 80

```
Crea mandalas infinitos y coloréalos con el dedo. Sin conexión y sin anuncios.
```
*(77 caracteres)*

## Descripción completa · máx. 4000

```
Mandalas crea dibujos nuevos cada vez que se lo pides, y te los deja listos
para colorear con el dedo.

No es una galería de plantillas repetidas: cada mandala se dibuja en el
momento con las reglas de la simetría radial, así que nunca se acaban.

CREA EL TUYO
• Siete estilos: geométrico, hindú (yantra), africano, circuitos,
  naturaleza, animales y robots mecha.
• Tres controles y ya: simetría, anillos y detalle.
• Cada dibujo tiene un número de semilla. Guárdalo o compártelo y volverá a
  salir exactamente igual.

COLOREA A TU RITMO
• Toca una figura y se pinta. Elige si el toque pinta el anillo entero o una
  sola figura.
• Empieza desde cero con la lámina en blanco, como un libro para colorear.
• Los espacios entre figuras también se pintan, uno por uno.
• 32 paletas y un selector de color propio, pensado para el dedo.
• Tres acabados: plano, acuarela y lápiz de color.

MÍRALO EN LA VIDA REAL
• Vista previa sobre camiseta, bolsa, taza y pared.
• Exporta en PNG para compartir, o en SVG para imprimir, cortar o bordar a
  cualquier tamaño sin perder calidad.

TUYO Y DE NADIE MÁS
• Funciona sin conexión, siempre.
• Sin anuncios, sin registro, sin cuentas.
• No recoge ningún dato. Lo que pintas se guarda en tu propio teléfono.
• Guarda hasta 30 mandalas en tu galería.

Para relajarte un rato, para tener algo que imprimir y colorear en papel, o
para sacar un patrón que después estampas donde quieras.
```

---

## Categoría y etiquetas

- **Categoría:** Arte y diseño *(alternativa: Estilo de vida)*
- **Etiquetas sugeridas:** mandala, colorear, dibujo, relajación, arte,
  antiestrés, generativo
- **Clasificación de contenido:** apta para todos. En el cuestionario todo va
  en «no»: sin violencia, sin lenguaje, sin contenido sexual, sin juegos de
  azar, sin compras, sin interacción entre usuarios, sin compartir ubicación.

## Seguridad de los datos (el formulario que da más miedo)

Responder así, y es verdad — comprobado sobre el código:

| Pregunta | Respuesta |
|---|---|
| ¿Recoges o compartes datos de usuario? | **No** |
| ¿Los datos se cifran en tránsito? | No aplica, no hay envío |
| ¿Se pueden solicitar borrado de datos? | No aplica, no hay datos en servidor |
| Permisos declarados | `INTERNET` (lo pone la plantilla de Capacitor; la app no hace ninguna petición de red) |

- **Política de privacidad:** `https://jpmc8op-coder.github.io/mandalas/privacidad.html`

## Recursos gráficos

Están en `_capturas/tienda/` (esa carpeta no se versiona; se regenera con
`dev/capturas.sh`).

| Recurso | Archivo | Tamaño | Exige Play |
|---|---|---|---|
| Icono | `icon-512.png` (raíz) | 512×512 | 512×512 PNG |
| Gráfico destacado | `destacado.png` | 1024×500 | 1024×500 |
| Capturas de teléfono | `1-hindu` … `6-galeria` | 1080×1920 | mín. 2, máx. 8 |

Orden sugerido de las capturas, que es un recorrido de la app: mandala hindú →
coloreando figura por figura → estilo mecha → vista en taza → lámina de líneas →
galería.
