# Publicar Mandalas en Google Play — paso a paso

Orden exacto de las tareas tal como aparecen en Play Console. Respuestas listas
para copiar. Los archivos que se piden están en:

```
_apk\Mandalas.aab                              el archivo que se sube
icon-512.png                                   icono (en la raíz del proyecto)
_capturas\tienda\destacado.png                 gráfico de funciones
_capturas\tienda\1-hindu.png … 6-galeria.png   capturas de teléfono
```

---

# Estado a 2026-09-02

**11 de 11 tareas completadas.** La sección «Termina de configurar tu aplicación»
desapareció del panel: el panel ahora solo muestra Prueba interna, Prueba cerrada
y Producción.

Clasificación de contenido enviada el 2 de septiembre de 2026 a las 21:19.
Resultado: ESRB *Para todos* · PEGI 3 · USK *Para todos los públicos* ·
Google Play *Para mayores de 3 años*, sin descriptores de contenido.

| Tarea | Estado |
|---|---|
| Política de privacidad | ✅ |
| Datos de inicio de sesión | ✅ |
| Anuncios | ✅ |
| Clasificación de contenido | ✅ enviada, apta para todos |
| Audiencia objetivo | ✅ 13-15, 16-17, A partir de 18 años |
| Seguridad de los datos | ✅ no se recogen datos |
| Aplicaciones gubernamentales | ✅ No |
| Funciones financieras | ✅ ninguna |
| Salud | ✅ ninguna |
| Categoría y datos de contacto | ✅ Arte y diseño · correo · sitio web |
| Ficha de Play Store | ✅ textos + icono + gráfico + 6 capturas |

**Prueba interna publicada** el 2026-09-02: versión `1 (1.0)`, canal *Activo*,
3.18 MB de descarga. Mientras Google no revise la app, los testers la ven con el
nombre temporal `com.jpmedina.mandalas (unreviewed)`.

**«Enviar aplicación a revisión» está bloqueado.** El Console dice: *«Para enviar
cambios a revisión, completa los pasos necesarios en el panel de control»*. En
cuentas personales el desbloqueo pasa por la **prueba cerrada**: publicar una
versión en ese canal, juntar 12 testers que acepten y mantenerla 14 días. La
ficha, la clasificación y todo lo demás quedan guardados como cambios pendientes
hasta entonces.

Lo que sigue: crear la versión de **prueba cerrada** y conseguir los 12 testers.

---

# PARTE A · "Termina de configurar tu aplicación"

En el **Panel de control**, sección *Termina de configurar tu aplicación* →
**Ver tareas**. Se hacen de arriba abajo.

## A1 · Establece la política de privacidad

Pegar en el campo de URL:

```
https://jpmc8op-coder.github.io/mandalas/privacidad.html
```

**Guardar**.

## A2 · Datos de inicio de sesión

La app no tiene cuentas ni login.

- Marcar: **No se necesitan datos de inicio de sesión para acceder a mi aplicación**
- **Guardar**

## A3 · Anuncios ✅ hecho

- ¿Contiene anuncios? → **No, mi aplicación no contiene anuncios**
- **Guardar**

## A4 · Clasificación de contenido

La página se titula **«Clasificaciones del contenido»** y es un asistente de tres
pasos: **1 Categoría — 2 Cuestionario — 3 Resumen**.

El cuestionario quedó **«Cuestionario incompleto · En curso»**: se empezó y no se
envió. Para retomarlo se entra por **Editar**, no por «Iniciar nuevo cuestionario».

**Paso 1 · Categoría**
- Dirección de correo electrónico: `jpmc8op@gmail.com`
- Categoría — solo hay tres opciones, no la lista larga:
  - Juego
  - Social o comunicación
  - **Todos los demás tipos de aplicaciones** ← esta
- **Términos y condiciones:** marcar **«Acepto los Términos de Uso tal como los
  describe la Coalición Internacional de Calificación por Edad (IARC)»**.
  Sin esa casilla el botón de continuar no se activa: es lo que dejó el
  cuestionario a medias.
- **Siguiente**

**Paso 2 · Cuestionario** — todo en **No**.

**Paso 3 · Resumen** — revisar y **Enviar**.

## A5 · Audiencia objetivo

Se abre desde el enlace **«Audiencia objetivo»** del panel, pero la página se
titula **«Contenido y audiencia objetivo»** y es un asistente de cinco pasos:
**1 Edad objetivo — 2 Detalles de la aplicación — 3 Anuncios —
4 Presencia en Google Play Store — 5 Resumen**.

**Paso 1 · Edad objetivo.** Casillas: Hasta 5 años · 6-8 · 9-12 · 13-15 · 16-17 ·
A partir de 18 años. Marcar **13-15**, **16-17** y **A partir de 18 años**.

Las tres primeras salen **bloqueadas**, con este aviso:

> No puedes seleccionar grupos de edad de menos de 13 años porque la
> clasificación ESRB de tu aplicación es Para mayores de 13 años.

No es un problema ni hay que corregir nada: Google ya impide por sí solo que la
app entre en el programa para niños.

**Paso 4 · Presencia en Google Play Store** es donde se pregunta si la app podría
atraer a niños sin querer → **No**.

Al final, **Guardar**.

## A6 · Seguridad de los datos

1. **Iniciar**
2. ¿Tu app recopila o comparte alguno de los tipos de datos requeridos? → **No**
3. ¿Se cifran los datos en tránsito? → *no aplica, no aparece si respondiste No*
4. ¿Los usuarios pueden solicitar la eliminación de sus datos? → *igual*
5. **Siguiente** → revisar el resumen (debe decir *No se recopilan datos*) →
   **Guardar**

> Es la sección que más miedo da y en esta app es la más simple: no hace ni una
> sola petición de red. Lo que guarda —el mandala que estás pintando, tu galería
> y los colores recientes— vive en el propio teléfono y nunca sale de ahí.

## A7 · Las que aparezcan debajo

- **Aplicación de noticias** → No es una aplicación de noticias
- **Aplicación de seguimiento de contactos / COVID-19** → No
- **Funciones financieras** → Mi aplicación no ofrece funciones financieras
- **Aplicación gubernamental** → No
- **Salud** → No

## A8 · Categoría y datos de contacto

- Tipo de aplicación: **Aplicaciones**
- Categoría: **Arte y diseño**
- Correo electrónico: `jpmc8op@gmail.com`
- Sitio web (opcional): `https://jpmc8op-coder.github.io/mandalas/`
- **Guardar**

## A9 · Ficha de Play Store principal

**Nombre de la aplicación**
```
Mandalas: crear y colorear
```

**Descripción breve**
```
Crea mandalas infinitos y coloréalos con el dedo. Sin conexión y sin anuncios.
```

**Descripción completa**: copiar el bloque largo de `dev/ficha-play.md`.

**Recursos gráficos**
| Campo | Archivo |
|---|---|
| Icono de la aplicación | `icon-512.png` |
| Gráfico de funciones | `_capturas\tienda\destacado.png` |
| Capturas de pantalla de teléfono | las seis de `_capturas\tienda\`, del 1 al 6 |

**Guardar**.

---

# PARTE B · Prueba interna

En el **Panel de control**, sección *Prueba interna* → **Ver tareas**.

## B1 · Selecciona testers ✅ hecho

La cuenta ya tenía dos listas creadas para *Puño de Chatarra*:

| Lista | Personas |
|---|---|
| **Pruebas Puño de Chatarra** | 2 |
| Testers externos | 11 |

Para la prueba interna quedó marcada **Pruebas Puño de Chatarra**. «Testers
externos» se deja para la prueba cerrada, que necesita 12 personas.

Enlace para unirse a la prueba interna (funciona cuando haya una versión
publicada, y solo para los correos de la lista):

```
https://play.google.com/apps/internaltest/4700608733049926193
```

## B2 · Crea un nuevo lanzamiento

1. Si aparece **Play App Signing**, aceptar (Google guarda la clave de firma
   real; la tuya pasa a ser solo la de subida).
2. Subir **`_apk\Mandalas.aab`**
3. Nombre de la versión: `1.0`
4. Notas de la versión, dentro de las etiquetas `<es-ES>` o similares:
   ```
   Primera versión.
   ```
5. **Siguiente**

## B3 · Revisa y confirma la versión

1. Revisar los avisos. Los amarillos suelen ser recomendaciones, no bloqueos.
2. **Iniciar el lanzamiento en Prueba interna** → **Lanzar**

## B4 · Instalarla

1. En la pestaña **Verificadores**, copiar el **enlace para unirse**
2. Abrirlo en el celular con la misma cuenta de Google
3. Aceptar ser tester → **Descargar la app en Google Play**

De 5 a 15 minutos entre lanzar y poder instalarla.

---

# PARTE C · Producción

Google exige, en cuentas personales, una **prueba cerrada con 12 testers durante
14 días seguidos** antes de habilitar producción. La prueba interna **no** cuenta
para ese requisito.

Camino real: prueba interna (hoy) → prueba cerrada con 12 personas (dos semanas)
→ **Producción ▸ Crear versión** → revisión de Google (3 a 7 días).

Conviene ir juntando esos 12 correos desde ya.

---

# Actualizaciones posteriores

Play rechaza dos subidas con el mismo `versionCode`. Antes de generar un AAB
nuevo hay que subirlo en `android/app/build.gradle`:

```
versionCode 2
versionName "1.1"
```

Después `npm run aab` y subir el archivo nuevo.
