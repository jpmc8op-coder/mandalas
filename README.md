# Mandalas

Generador procedural de mandalas para colorear. Elige un estilo, genera con una
semilla y pinta cada capa con un toque. Funciona en el navegador, sin cuenta,
sin conexión y sin instalar nada.

**Probarla:** https://jpmc8op-coder.github.io/mandalas/

## Qué hace

- **Siete estilos generativos:** geométrico, hindú (yantra), africano, circuitos,
  naturaleza, animales y robots/mecha.
- **Semilla determinista:** la misma semilla da siempre el mismo mandala, y viaja
  en la URL para poder compartirlo.
- **Coloreado por capas:** un toque pinta la figura tocada y todas sus hermanas.
  28 paletas, y tres acabados: plano, acuarela y lápiz de color.
- **Modo solo líneas:** la lámina lista para imprimir y colorear a mano.
- **Vista previa sobre objetos:** camiseta, bolsa, taza y pared.
- **Exporta a PNG y a SVG.** El SVG es vectorial de verdad: sirve para corte,
  bordado o impresión a cualquier tamaño.

## Cómo correrla

Doble clic en `index.html` funciona para todo menos la instalación como app.
Para eso hace falta servirla por HTTP:

```bash
python -m http.server 8777
```

y abrir `http://localhost:8777`.

## Cómo está hecha

Un solo archivo, `index.html`, con HTML + CSS + JavaScript y **cero
dependencias**. El dibujo es SVG generado por código: se construye un sector
angular y se replica con `rotate()`. Los detalles de arquitectura y las
decisiones de diseño están en [`CLAUDE.md`](CLAUDE.md).

| Archivo | Qué es |
|---|---|
| `index.html` | La aplicación completa. |
| `sw.js` | Service worker: caché offline. |
| `manifest.json`, `icon*.png`, `icon.svg` | Instalación como app. |
| `dev/` | Herramienta de desarrollo para renderizar hojas de contacto. |

## Licencia

Pendiente de definir.
