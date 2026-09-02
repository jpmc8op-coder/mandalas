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

## A3 · Anuncios

- ¿Contiene anuncios? → **No, mi aplicación no contiene anuncios**
- **Guardar**

## A4 · Clasificación de contenido

1. **Iniciar cuestionario**
2. Correo de contacto: `jpmc8op@gmail.com`
3. Categoría: **Utilidades, productividad, comunicación u otro**
4. El cuestionario entero en **No**: violencia, sangre, contenido sexual,
   lenguaje soez, drogas, juegos de azar, contenido generado por usuarios,
   compartir ubicación, compartir información personal, compras digitales.
5. **Guardar** → **Siguiente** → **Enviar**

## A5 · Audiencia objetivo

- Grupos de edad: marcar de **13 a 15**, **16 a 17** y **18 y más**.
  *(No marcar los grupos de menores de 13: eso mete la app en el programa para
  niños, con requisitos extra que aquí no hacen falta.)*
- ¿La app podría atraer a niños de forma no intencionada? → **No**
- **Guardar**

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

## B1 · Selecciona testers

1. **Crear lista de correos electrónicos**
2. Nombre de la lista: `Yo`
3. Añadir `jpmc8op@gmail.com`
4. **Guardar cambios** y marcar la lista

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
