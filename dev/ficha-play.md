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

---

# Subir a Google Play, paso a paso

La cuenta de desarrollador ya existe: es la misma con la que se está probando
*Puño de Chatarra*. Una cuenta admite todas las apps que quieras.

## 1. La clave de firma

Ya hay un almacén de claves creado para el otro proyecto:
`C:/Users/jpmc_/claves/puno-de-chatarra.jks` (alias `puno`). **Lo recomendable
es añadirle una clave propia para esta app** —un archivo puede guardar varias— en
vez de compartir la misma:

```bash
& "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.8-hotspot\bin\keytool.exe" -genkeypair -v -keystore "C:\Users\jpmc_\claves\puno-de-chatarra.jks" -alias mandalas -keyalg RSA -keysize 2048 -validity 10000
```

Pide primero la contraseña **del almacén** (la que ya usas para chatarra), luego
los datos del certificado, y al final una contraseña para esta clave nueva.

*Alternativa sin escribir nada: copiar `android/keystore.properties` del proyecto
de chatarra a este. Funciona —una clave de subida puede firmar varias apps—, pero
las dos quedan atadas a la misma.*

## 2. Decirle al proyecto dónde está

Crear `android/keystore.properties` (está fuera de git):

```
storeFile=C:/Users/jpmc_/claves/puno-de-chatarra.jks
storePassword=LA-DEL-ALMACEN
keyAlias=mandalas
keyPassword=LA-DE-ESTA-CLAVE
```

> **La ruta va con barras normales `/`.** Este archivo usa el formato de
> propiedades de Java, donde la barra invertida es un carácter de escape: con
> `C:\Users\...` la ruta llega hecha pedazos (`C:Usersjpmc_...`) y Gradle dice
> que no encuentra el almacén. Pasó al probarlo.

## 3. Generar el AAB

```bash
npm run aab
```

Deja `_apk/Mandalas.aab`. Ese es el archivo que sube a Play — el APK de
depuración **no sirve** para la tienda.

## 4. En Play Console

1. **Crear la app**: nombre `Mandalas: crear y colorear`, español, Aplicación,
   Gratis. *(Gratis o de pago no se puede cambiar después.)*
2. **Pruebas internas > Crear versión** y subir el AAB. Empezar por aquí y no
   por producción: se instala en tu propio teléfono desde la tienda y se ve
   cómo queda de verdad antes de que lo vea nadie.
3. **Ficha principal**: pegar los textos de arriba y subir los gráficos de
   `_capturas/tienda/`.
4. **Contenido de la app**: política de privacidad, clasificación (cuestionario
   todo en «no»), seguridad de los datos (no se recoge nada), anuncios: no.
5. **Producción > Crear versión** cuando la prueba interna esté bien.

La primera revisión de una cuenta nueva tarda entre 3 y 7 días.

## Al publicar una actualización

Subir `versionCode` en `android/app/build.gradle` (2, 3, 4...) — Play rechaza dos
subidas con el mismo número — y `versionName` si el cambio lo merece. Después
`npm run aab` y subir el archivo nuevo.
