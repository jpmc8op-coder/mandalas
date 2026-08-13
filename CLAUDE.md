# CLAUDE.md — Mandalas

Generador procedural de mandalas con siete estilos, coloreado rápido y vista
previa sobre objetos. Web, sin backend, sin dependencias. Pensado para
publicarse gratis y luego empaquetarse con Capacitor para Play Store / App Store.

## Estado

Fase 1: web funcionando con siete estilos generativos. Aún **no** publicada ni
empaquetada.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La app completa: HTML + CSS + JS en un solo archivo. |
| `manifest.json` | PWA — permite "Añadir a pantalla de inicio". Solo funciona servido por HTTP, no con `file://`. |
| `icon.svg` | Ícono de la app. |
| `dev/hoja.ps1` + `dev/hoja-contacto.js` | Herramienta de desarrollo: renderiza varias mandalas de golpe y las captura en PNG. No forma parte de la app. |
| `_capturas/` | Salida de la herramienta anterior. Desechable. |

## Cómo probarla

> **Ojo con la caché al desarrollar.** `python -m http.server` manda
> `Last-Modified` y el navegador se queda con la versión anterior del HTML: se
> puede pasar un buen rato evaluando código viejo y creyendo que los cambios no
> hacen efecto. Recargar con un parámetro distinto (`?v=2`) o con Ctrl+F5.

Abrir `index.html` con doble clic funciona para todo menos la instalación PWA.
Para probar la PWA hace falta un servidor:

```bash
python -m http.server 8777 --directory "C:\Users\jpmc_\OneDrive\Documentos\claude code\mandalas"
```

Luego abrir `http://localhost:8777`.

### Hoja de contacto (juzgar el resultado, no adivinarlo)

Una miniatura suelta engaña: los fallos de un estilo se ven comparando varias
mandalas juntas. `dev\hoja.ps1` renderiza una rejilla y la captura en PNG con
Chrome headless:

```bash
powershell -File dev\hoja.ps1 -q "e=robot&p=Mecha&s=11,23,47,88,131,205"
```

Parámetros: `e` estilo · `p` paleta · `s` semillas · `n` simetrías · `a` anillos ·
`d` detalles · `l=1` solo líneas · `ac` acabado. Con `modo=motivos&m=canon,pinon`
dibuja **motivos aislados** repetidos en corona, que es la forma de comprobar si
una pieza nueva se lee o es una mancha.

Tres trampas que costaron un rato y están resueltas dentro del script:

1. **El código de `index.html` no está en `window`.** Todo se declara con `const`
   en el tope del script: esas ligaduras viven en el ámbito léxico global, no
   como propiedades de `window`, así que desde un iframe (`w.estado`) no se ven.
   Por eso la hoja se **inyecta dentro del propio script**, antes del último
   `</script>`, en una copia temporal `_hoja.html`.
2. **La app borra los parámetros de la URL.** `pintar()` hace
   `history.replaceState('?seed=...')` al arrancar, antes de que corra la hoja.
   Hay que leerlos de `performance.getEntriesByType('navigation')[0].name`.
3. **`chrome.exe --headless` devuelve el control antes de escribir el PNG**, y si
   el `--user-data-dir` está ocupado por otra instancia no escribe nada y
   tampoco avisa. El script usa un perfil nuevo por corrida y espera a que
   aparezca el archivo antes de borrar `_hoja.html`.

## Arquitectura

El código está en 12 secciones numeradas dentro de `index.html`.

### Principios del generador

1. **Simetría radial.** Se dibuja un solo sector angular y se replica N veces
   con `transform="rotate()"`. Todo motivo se define apuntando hacia arriba
   (ángulo 0) entre un radio interno y uno externo.
2. **Lista plana de partes.** El mandala es un array de
   `{ d, k, off, trazo, grosor, evenodd, tr }`. `k` = repeticiones,
   `off` = rotación inicial, `tr` = transform extra aplicado después del
   `rotate` (lo usan las siluetas y las rosetas de esquina).
   Cada parte es también **una capa de color** (su índice = slot).
3. **Repeticiones armónicas.** `repeticionesArmonicas()` solo devuelve divisores
   o múltiplos de la simetría base. Sin esto el mandala se ve ruidoso. Es la
   regla más importante del generador — no relajarla.
   `repeticionesParaBanda()` es la versión afinada: calcula cuántas
   repeticiones harían que el motivo quede tan ancho como alto y se queda con
   el valor armónico más cercano. Resuelve el problema de las bandas anchas con
   pocas figuras y huecos enormes entre ellas. **La usan todos los estilos.**
   Aparte, el ancho angular del motivo (`hw`) va al 94–100% del sector en todos
   los generadores: por debajo de eso quedan huecos visibles entre figura y
   figura dentro del mismo anillo.
4. **Anillos entrelazados.** `bandas()` acepta `hueco` (> 1: el anillo se asoma
   sobre el siguiente) y `solape` (muerde hacia dentro del anterior). Además los
   anillos **alternan medio sector de desfase** (`fase` por mandala,
   `off = ((i + fase) % 2) ? 180/k : 0`) para que las puntas de uno caigan en los
   huecos del siguiente. Entre las dos cosas desaparecen las zonas blancas que
   quedaban entre anillo y anillo.
   Los aros guía se dibujan en el límite **nominal**, no en `r1`: con solape,
   `r1` cae dentro del anillo siguiente y el aro se vería fuera de sitio.
   `circuito` no lleva solape a propósito — una placa no se trenza.
5. **Orden de dibujado por profundidad — `z`.** Cada parte lleva
   `z = -(radio medio)`. `cuerpoMandala()` ordena por `z` ascendente, así que se
   dibuja **de fuera adentro**: donde dos anillos se solapan, las figuras
   interiores quedan POR ENCIMA de las exteriores, que es como se ve una flor
   abierta desde arriba. El `sort` es estable, de modo que dentro de un mismo
   anillo se respeta el orden en que el generador creó las piezas (pétalo →
   contorno interior → punto). **`data-i` sigue siendo el índice original del
   array**, porque es el número de capa de color; no confundir orden de
   dibujado con número de capa.
   Cada generador declara la profundidad con una variable local `zB` que su
   helper `add()` estampa; los aros y collares se ponen su propio `zB = -radio`
   temporalmente, para no heredar el de la zona en curso.
4. **Semilla determinista** (`mulberry32`). Misma semilla = mismo mandala. Se
   refleja en la URL como `?seed=`. Se usa `replaceState`, nunca `pushState`
   (dentro de un webview el botón atrás del sistema se comporta distinto).
5. **`svgMarkup()` es una función pura.** Mismo estado, mismo SVG. La usan por
   igual la pantalla y la exportación — no hay dos caminos de render que puedan
   divergir.

### Registro de estilos

`ESTILOS` mapea cada id a `{ n (nombre), pal (paleta por defecto), gen }`.
Añadir un estilo = añadir una entrada ahí, más su generador, más su id en
`LIMITES_PRO.estilos`. La UI de chips se construye sola a partir del registro.

| id | Qué genera |
|---|---|
| `geo` | Anillos concéntricos de motivos geométricos. Motor `generarAnillos` con `VOC.geo`. |
| `hindu` | Yantra completo (ver abajo). |
| `africano` | Mismo motor que `geo` con `VOC.africano`, pero con cenefas compuestas (ver abajo). |
| `circuito` | Planta de un die real (ver abajo). |
| `natura` | Flores, hojas, frondas y fractales (ver abajo). |
| `animal` | Siluetas curadas distribuidas por los anillos (ver abajo). |
| `robot` | Engranajes (dientes + aro macizo), tuercas hexagonales, paneles, antenas. |

`generarAnillos(semilla, cfg, voc)` es el motor compartido: `voc` define
`{ motivos, ancho, grosor, aros, hueco, solape, compuesto }`. Dos estilos con el
mismo esqueleto y vocabularios distintos se ven completamente distintos — es la
forma barata de añadir estilos nuevos.

### Estilo `africano` — cenefas de tejido

Vocabulario tomado de referencias de textil y adinkra que aportó el usuario:
`espiralAfr` (espiral de una sola línea, el motivo por excelencia), `ojoAfr`
(círculos concéntricos con pupila), `greca` (meandro angular continuo), `lente`,
`romboAnidado`, `triRayado` (triángulo con rayado interior), `abanico`
(semirrosetón de rayos), `damero`, `zigzagMulti`, `conteo` (marcas de conteo).

**`voc.compuesto` es lo que lo hace parecer tejido.** En las referencias una
cenefa nunca es una fila sola: es una franja de figuras **más** una tira de
rayas, puntos o greca pegada justo debajo. Por eso cada anillo emite su motivo y
además una tira de textura en su borde interior. Sin eso son anillos sueltos.

Paletas propias: `Kente` (verde, granate y mostaza) y `Adinkra` (ocres y tierra).

### Estilo `hindu` (yantra)

Reproduce la estructura del Sri Yantra, de afuera hacia adentro:

- **Bhupura** — marco cuadrado con cuatro puertas en T hacia los puntos
  cardinales. `ladoBhupura()` genera UN lado de esquina a esquina; el renderer
  lo repite 4 veces con `rotate(90)` y el cuadrado se cierra solo.
  **No sale siempre** (`conMarco`, ~45% de las semillas). Es el elemento propio
  del yantra, pero la lámina de mandala floral clásica no lo lleva: su contorno
  lo dibujan las puntas de los pétalos. Cuando no hay marco, `R_INT` sube de 322
  a 436, la capa exterior no se asoma hacia fuera (su punta ES el borde) y se
  omite el círculo exterior — si estuviera, el contorno volvería a ser una
  circunferencia perfecta y se pierde el aire de flor.
- **Rosetas en las cuatro esquinas** (`roseta()` + `tr` de translate). Sin
  ellas el cuadrado se ve hueco. Un solo `add` con `k:4` las coloca en las
  cuatro esquinas, porque `rotate(90)` lleva `(a,-a)` a `(a,a)`.
- **Collar de perlas y rayos** en la banda entre el marco y el primer círculo.
- **Orlas decorativas** — las controla el slider de anillos (`anillos - 3`,
  tope 6). Cada orla lleva su motivo, una **copia interior de contorno** y a
  veces una fila de puntos: eso es lo que multiplica el detalle sin inventar
  figuras nuevas, y deja más zonas para colorear.
- **Capas de pétalos** — el cuerpo de la flor, y lo primero que se reparte del
  radio. Hasta cinco capas grandes y muy superpuestas. En las láminas de
  referencia el mandala ES esto; dos anillos de pétalos perdidos entre orlas
  finas no se parece.
  El peso radial **crece hacia el centro** (`pesoCapa(c) = 0.70 + c*0.34`, con
  `c = 0` la capa exterior): los pétalos de dentro son grandes y van menguando
  hacia fuera, como en las láminas de referencia.
  **Cada capa lleva tantos pétalos como quepan con proporción esbelta**
  (ancho ≈ 0.75 del alto), con suelo de 10 y tope de 40. Como el alto ya crece
  hacia dentro, el pétalo interior sale más grande igualmente, pero sin quedarse
  en cuatro figuras sueltas.
  Dos intentos fallidos que no hay que repetir: **partir `k` a la mitad cada
  capa** (al llegar al suelo dos capas repiten número, la cuerda encoge al bajar
  el radio y el pétalo interior sale más PEQUEÑO); y **fijar una cuerda objetivo
  que crezca un 30% por capa** (hunde el número hasta 6 pétalos en la capa
  interior y el anillo se ve vacío). El tamaño visible depende de la cuerda, no
  solo del alto radial.
  Las **orlas se dibujan después, hacia dentro**: puestas fuera se comían el
  borde con anillos finos y los pétalos no llegaban al contorno.
- **Núcleo** — la semilla elige uno de los once de `NUCLEOS`, así que el
  corazón del mandala cambia de una generación a otra.
  Clásicos: `sriYantra` (los nueve triángulos entrelazados), `shatkona` (dos
  triángulos equiláteros, Shiva y Shakti), `ashtakona` (dos cuadrados girados
  45°), `chakra` (rueda de radios), `lotoCentro` (loto de 8 o 12 pétalos),
  `navayoni` (triángulos concéntricos alternando sentido) y `rayosEstrella`.
  Fractales: `sierpinskiYantra`, `shatkonaFractal` (la misma estrella a escalas
  decrecientes, girando), `kochYantra` y `sriYantraFractal` (el yantra que se
  contiene a sí mismo a media escala).
  Firma: `(add, R, grosor, rnd, N)`. Añadir uno es añadir una función al objeto.
- **Orla de mini-yantras** — con un 30% de probabilidad una orla se llena de
  copias en miniatura del propio yantra (shatkonas o Sierpinskis) colocadas con
  `tr`. Es la autosimilitud que ya está implícita en el Sri Yantra, hecha
  explícita y visible.
  El `sriYantra` usa `TRI_ARRIBA` / `TRI_ABAJO`: pares
  `[altura del ápice, altura de la base]` en fracción del radio. Las esquinas de
  la base se apoyan en el mismo círculo, que es lo que produce el entrelazado.
- **Bindu** — punto central con dos aros.

La referencia estética es la lámina de libro para colorear: **línea fina**
(`fino` arranca en 1.5, no en 4), muchas capas anidadas, poco vacío.

**`capaPetalos()` es la unidad de construcción**, compartida con `natura`. Un
pétalo liso repetido no se parece a una lámina de mandala; lo que la hace es la
acumulación de detalle DENTRO de cada pétalo:

1. el pétalo (por defecto `ojival`: base ancha, hombros y punta — la almendra
   de `loto` es más pobre y se nota enseguida). **Llena su sector (99%) y toca
   con el vecino**: en las láminas de referencia el anillo va lleno, sin aire.
   Lo que permite leer los pétalos uno a uno es su **contorno propio y grueso**
   (`g * 1.7`), no el hueco. Se probó dejarlos al 84% y el resultado se veía
   espaciado y perdía la densidad de flor;
2. dos contornos interiores anidados;
3. una gota en su corazón;
4. **`perlasDePetalo()`** — cadena de puntos que se separa y se vuelve a juntar
   siguiendo el ancho de la figura, colocada **por fuera** del borde para que
   caiga en el hueco entre pétalo y pétalo, que es donde va en las láminas. Un
   anillo de puntos concéntrico no vale: ese no sigue la forma;
5. **rayado** opcional: las nervaduras que llevan los pétalos de las láminas;
6. festón opcional bajo la base.

El detalle se **dosifica según la cuerda del pétalo** (`cuerdaPetalo`): cuando
hay muchos pétalos son estrechos, y meterles el mismo detalle que a uno ancho
solo produce ruido, así que se cae el segundo contorno y se encogen las perlas.

**Entrelazado.** Cada zona se asoma hacia FUERA sobre la anterior (`SOL`), pero
`r0` no se mueve: el reparto radial no cambia, solo se cierra el hueco. Como el
orden de dibujado va de fuera adentro, la zona interior queda encima.

**Pétalos intercalados.** Las repeticiones de cada orla se encajan a la mitad,
el mismo número o el doble que las de la orla de fuera (`kPrev`). Con cuentas
dispares el desfase de medio sector no intercala nada: los pétalos de un anillo
tienen que caer exactamente ENTRE los del anterior para que se lea como flor.

**Dos trampas ya pisadas, no repetirlas:**

- El reparto radial descuenta las separaciones (`SEP`) *antes* de repartir. En
  la primera versión se sumaban después y se comían el núcleo de triángulos
  hasta dejarlo en R=30, invisible. El peso del núcleo además crece con el
  número de orlas para que no se encoja cuando sube el detalle.
- Doblar la circunferencia separadora en *cada* orla convierte el mandala en
  una sopa de anillos concéntricos y se pierden las figuras. Por eso el doble
  círculo es probabilístico (35%) y el resto de las veces va uno solo.

### Estilo `circuito` — planta de un die + HUD de instrumento

No es "cables bonitos": reproduce los elementos reales de un floorplan de
microchip, y encima el instrumental de las referencias de HUD tecnológico.

- **Borde del die** — tres variantes, elegidas por semilla: pads de bonding
  (`padIO`), anillo de datos o escala de marcas. Antes era **siempre** el mismo
  anillo de pads gordos y oscuros: seis semillas distintas daban seis bordes
  idénticos y se comía el resto del dibujo.
- **Anillos de potencia VDD/VSS** — dos aros concéntricos, uno muy grueso.
- **Macros duros** — `arrayMem` dibuja el haz de líneas paralelas encerrado
  entre dos arcos que caracteriza a una SRAM vista al microscopio.
- **Filas de celdas estándar** — `celdas`, rectángulos abutados.
- **Rutado** — `manhattan` (tramos radiales y tangenciales con giros de 90°,
  nunca diagonales), `busDiagonal` (haz de cuatro pistas a 45°) y `trazaVia`
  (pista con dos quiebres que muere en su vía). Cada giro lleva su **vía**
  (`viaCuadrada`, `viaRedonda`) o su **pad** (`padTermina`): eso es lo que
  delata un cambio de capa de metal.
- **HUD** — `arcoSegmentado` (arco grueso partido), `arcoBloques` (banda con
  rectángulos de largo desigual encima), `escalaRadial`, `anilloDatos` (código
  de barras curvado), `cunaHud` y `flechaTicks`. Casi todo relleno, no trazo.
- **Pistas largas** que cruzan varias coronas y mueren en un pad. En las
  referencias son lo que ata el conjunto; sin ellas el dibujo se lee como
  coronas apiladas y no como una placa.
- **Centro vacío** rodeado de escalas, como en todas las referencias de HUD.

**Lo que arregló que se viera repetitivo y simple** (que era la queja) no fue
añadir motivos, sino cambiar cómo se reparten:

1. **Tres familias —`hud`, `rutado`, `bloques`— y nunca dos bandas seguidas de
   la misma.** Antes todas las bandas salían del mismo saco de cinco motivos:
   con ocho anillos, casi siempre tocaban dos o tres iguales.
2. **Una banda de cada cuatro se deja casi vacía** (familia `aire`). El aire es
   la mitad del look de las referencias; llenando las ocho coronas el resultado
   es una maraña donde no se distingue ninguna pieza. La probabilidad baja con
   el Detalle (`0.34 − dens*0.24`), que es lo que más se nota al mover ese
   deslizador en este estilo.
3. **Repeticiones por proporción de banda** (`repeticionesParaBanda`) en vez de
   un armónico suelto, **con tope por familia**: 20 en rutado, 24 en HUD, 30 en
   bloques. Sin tope, en una banda estrecha el reparto pide sesenta copias y una
   escala de marcas deja de leerse como escala: es un peine negro. Por lo mismo
   `escalaRadial` bajó de nueve marcas por sector a cinco, y `arrayMem` (siete
   líneas por sector) se limita a k ≤ 12.
4. **Segunda pasada desfasada en el rutado**: las pistas van en haz, no sueltas.

### Estilo `natura` — tierra, agua, viento y fractales

**Tres familias, una por mandala** (no mezcladas al azar, o queda ensalada):

- **tierra** — `hoja`, `hojaLobulada` (tres lóbulos), `fronda` (helecho en
  silueta cerrada), `ramaHojas`, `escamaPina`, `semillero`, `vena`, `arbol`, y
  flores construidas con `roseta(R, n, ancho)` de 5, 6, 8 o 12 pétalos,
  colocadas como pieza completa con `tr`, no como sector.
- **agua** — `ondaBanda` (la onda con cuerpo), `ola` (cresta con voluta, al modo
  de Hokusai), `gotaAgua`, `cumulo` (burbujas rellenas con su reflejo vaciado),
  `nautilo`.
- **viento** — `remolinoAncho` (voluta convertida en cinta), `rachaAncha`,
  `dendrita`.

**Nada de triángulos.** El copo de Koch y el triángulo de Sierpinski son las
fractales de manual y estuvieron aquí, pero las dos se construyen sobre un
triángulo equilátero y **el triángulo no dice naturaleza, dice geometría**. Se
sacaron de este estilo (siguen en el hindú, donde el triángulo sí es el
vocabulario correcto). Las que quedan son las que la naturaleza usa de verdad:

- `copoDendrita()` — seis brazos y cada brazo repite su propia forma. Es la
  fractal del hielo, la que forma un copo de nieve real. **Figura cerrada.**
- `filotaxis()` — semillas con el ángulo áureo (137.5°); la disposición real de
  una cabezuela de girasol.
- `circulosFractal()` — empaquetado de círculos, la lógica de la espuma. Ahora
  se pinta con `evenodd` en vez de dibujarse a trazo.
- `nautilo` — espiral logarítmica cerrada con sus cámaras.

**El centro es SIEMPRE una fractal**, y ocupa las dos primeras bandas enteras.
Con un radio pequeño la idea de fractal simplemente no se lee. Además, **una
banda al azar lleva un collar de fractales sueltas**: copos dendríticos en
miniatura, o frondas / dendritas / nautilos / escamas de piña.

**Todo relleno, no trazo.** De los 17 motivos de los que tiraba el estilo, 9
eran solo línea, y las familias agua y viento eran línea casi por completo: en
una lámina para colorear eso significa que media mandala no se puede pintar. Los
motivos nuevos son todos cerrados y hoy el estilo mide **64% de piezas de
relleno** — con `animal` (80%) y `robot` (68%), de los más pintables. Los de
línea (`vena`, `arbol`, `onda`, `racha`) quedan como acento.

**Cuidado con `roseta`:** el parámetro `ancho` se divide por el número de
pétalos (`min(1, 8/n)`). Sin ese ajuste, una flor de 12 pétalos sale como un
bulto macizo en vez de como una flor.

### Estilo `robot` — mecha de anime de los noventa

Vocabulario tomado del género (Gundam, Evangelion, mecha de los 80–90) y, sobre
todo, de fotogramas de referencia de panelado de hangar que aportó el usuario:

- **Panelado de casco** (lo que más define el estilo): `teclas` (matriz de
  pulsadores redondeados), `capsula` (ranura alargada de extremos redondos),
  `etiqueta` (placa de aviso con el damero vaciado), `brida` (puerto redondo con
  su círculo de tornillos), `diamante` (rombo de advertencia con el rayo
  vaciado), `peligro` (rayado diagonal continuo de lado a lado del sector).

- **Cabeza y silueta:** `vfin` (la cresta en V de la frente, el rasgo más
  reconocible), `visor` (cabeza de frente, visor ancho y mentón estrecho),
  `monoojo` (el ojo único tipo Zaku), `sensor` (cámara con iris).
- **Blindaje:** `hombrera` (placa con bisel), `remaches` (placa con tornillos),
  `ala` (binder de mochila tipo Wing), `panel`.
- **Maquinaria:** `piston` (cilindro hidráulico segmentado), `cable` (las
  mangueras expuestas del Zaku y del EVA), `articulacion` (rótula con
  horquilla), `garra` (manipulador de tres dedos), `turbina`, `diente`,
  `tuerca`.
- **Propulsión y armamento:** `thruster` (tobera con boca hueca), `rejilla`
  (vernier), `canon` (tubo con anillos de refuerzo y boca).
- **Panelado:** `blindaje` (placa escalonada con esquinas biseladas, la forma
  base del panelado ochentero), `escotilla` (con bisagras), `radiador`
  (aletas de disipación), `ranura` (ventilación inclinada), `ojiva`.
- **Señalética:** `peligro` (franjas diagonales), `diana` (retícula de
  puntería), `codigo` (código de barras estarcido), `placaTexto` (recuadro con
  renglones de texto vaciados), `trianguloAviso` (con la exclamación hueca),
  `cruzAviso` (el pictograma de cinco cuadrados del panel), `barrasAviso` (las
  barras diagonales que acompañan a las etiquetas), y la **numeración de
  unidad**: dígitos de siete segmentos (`SEGMENTOS`, `GLIFOS`, `textoPath()`)
  colocados con `tr`, como las siluetas de animales.
- **Artillería: solo la familia del cañón.** `canon`, `canonDoble` (dos tubos
  con puente de unión), `railgun` (tubo con anillos aceleradores), `multitubo`,
  `bocacha` (con venteos laterales).
  **Se quitó todo el resto del armamento** —sable de haz, emisor, torpedo, dron,
  lanzagranadas, rifle, bazooka, vulcan, misiles, escudo, garra de energía, y
  antes espada, naginata, lanza y hacha—. Dos razones: las medievales leían como
  fantasía y no como mecha; y el resto **desviaba el estilo del que muestran las
  referencias**, que no va de armas sino de chapa, uniones, engranajes y
  señalética. Un mandala no es una lámina de armamento.
  Todas apuntan hacia afuera: culata en `r0` y boca en `r1`, que es como quedan
  bien al repetirse en corona.
  **Se dibujan estrechas (60% del sector), no llenándolo.** Son formas
  alargadas: al ocupar todo el sector salen achatadas y dejan de reconocerse.
  El hueco que queda se rellena con una pieza pequeña intercalada.

- **Cabeza del mecha** (es lo que identifica al robot de un vistazo, y en las
  referencias aparece una y otra vez): `cascoMecha` (casco completo, cresta en V
  + visor vaciado + mentón, en una sola pieza), `ojoVisor` (ranura horizontal
  con ceja y barbilla), `antenaDoble` (antenas gemelas segmentadas).

- **Uniones y transmisión** — el rasgo que más se repite en las referencias: el
  mecha se lee por cómo están articuladas sus piezas, no solo por la chapa.
  `rotula` (esfera entre dos horquillas), `bisagra` (nudillos alternos con
  pasador), `acople` (collar con pestañas de bloqueo), `pinon` (rueda dentada
  pequeña con eje y chavetero).

- **Estructura y chapa:** `viga` (doble T con agujeros de aligeramiento),
  `refuerzo` (cartela con sus tornillos), `chapaOndulada`, y la señalética
  direccional `flechaDir`.

**Sombreado cel** (`sombra()`): una **cuña recortada con la silueta de la propia
pieza**, pintada con el tono más oscuro de la paleta, de borde duro y sin
degradado. Así sombrea el anime, y es lo que da volumen al blindaje.

**No vale una copia desplazada de la pieza**, que fue el primer intento: en las
piezas estrechas —un cañón, una antena— la copia caía fuera y parecía una
sombra proyectada al lado del objeto en vez de sombreado sobre él. La sombra
tiene que quedar DENTRO por construcción, y eso obliga a recortar.

El recorte va montado así: la parte lleva `recorte` (el path de la figura a la
que sombrea) y el renderer emite `<defs><clipPath>` dentro del propio grupo,
con **la rotación en un `<g>` envolvente y el `clip-path` en el `<path>` interior
sin transform propio**. Así el recorte gira con la pieza sin depender de en qué
espacio resuelva el navegador un `clip-path` sobre un elemento transformado —
que es ambiguo y no conviene apostar.

**La sombra se atenúa con `opacity="0.28"`, no eligiendo un tono más claro.**
Así oscurece lo que tiene debajo sea cual sea el color de la pieza y funciona
igual con las 28 paletas; con un tono fijo, en unas paletas se pasaba de negro y
en otras desaparecía. Las piezas con `sombra:true` reciben `pal[0]` en
`autoColorear` y la opacidad hace el resto. En modo línea las sombras se
omiten: una lámina para colorear no las quiere.
- **Mecanismos:** `corrugada` (el tubo de acordeón del Zaku y del Patlabor),
  `discoJunta` (disco de articulación con círculo de tornillos y buje),
  `pistonVastago` (pistón con el vástago salido y collarines), `multitubo`
  (cañón de varios tubos sobre su cuna), `perilla` (rotatoria con marca
  indicadora), `eslabon` (de oruga).
  `engranaje` es una corona dentada completa, así que se dibuja con `k = 1`;
  repetirla k veces solo apila copias idénticas encima de sí misma.
- **Recursos de dibujo de anime:** `destello` (la estrella de impacto del
  manga) y `velocidad` (líneas de velocidad).

El núcleo es siempre la cara del mecha: monoojo, o visor con cresta en V.

**Lo decisivo no es el vocabulario, es la estructura.** Se añadieron doce
motivos mecánicos y el resultado seguía leyéndose como un mandala geométrico,
porque cada anillo ponía UN motivo repetido k veces. La maquinaria real es una
placa grande con detalles anidados dentro. Por eso las bandas anchas de
`generarRobot` emiten un **conjunto de placa**, no un motivo:

1. placa base (`blindaje`, `chapaOndulada`, `viga`, `refuerzo`, `capsula`,
   `escotilla`, `hombrera`, `ala`, `ojiva`);
2. **línea de panel** — copia interior de contorno fino, la junta entre placas;
3. detalle en el tercio exterior: **señalética** (rótulo, flecha de sentido,
   aviso de peligro, código);
4. detalle en el tercio interior: tornillería, **unión o engranaje** (`pinon`,
   `rotula`, `acople`, `bisagra`, `brida`, `discoJunta`);
5. **una pieza pequeña intercalada entre placa y placa** (desfase de medio
   sector), que es lo que rompe la uniformidad del anillo;
6. desgaste ocasional.

**Las bandas anchas se reparten en cuatro familias de anillo** (`fam = rnd()`),
no en una sola:

| Rango | Familia | Cómo se dibuja |
|---|---|---|
| < 0.16 | corona de artillería | cañón al 60% del sector + pieza intercalada |
| < 0.30 | corona de cabezas | `cascoMecha` al 92% con su `ojoVisor` anidado dentro, y `antenaDoble` entre casco y casco |
| < 0.46 | corona de uniones | rótula / bisagra / acople / piñón al 86% + piñón o tornillería intercalados |
| resto | conjunto de placa | los seis pasos de arriba |

Así el peso del estilo cae donde lo ponen las referencias —chapa, uniones,
engranajes y señalética— y el armamento queda como acento, no como tema. Medido
sobre 400 mandalas aleatorios, el vocabulario nuevo (16 motivos) se lleva el
**38% de las llamadas a `MOTIVOS`**, y los cinco cañones juntos solo el 5%.

Un mandala de robot pasó de ~15 piezas a ~36 con este cambio, y ahí sí se ve la
diferencia. El helper `poner(tipo, ra, rb, k, ancho, off, forzarTrazo)` coloca
cada elemento dentro de los límites que se le den, respetando su `trazo` y su
`evenodd`.

**Rótulos de bahía.** `GLIFOS` extiende los siete segmentos a las letras que ese
display sabe formar (A B C D E F H L P U y el guion); `textoPath()` compone la
cadena y `codigoBahia()` inventa códigos del tipo `E-75`, `15-E9` o `CF-09`.
Los caracteres no representables se ignoran en vez de romper el path.

Paletas propias: `Casco` (la de defecto: grises azulados de casco más el
amarillo de aviso del panelado de hangar), `Titanio`, `Hangar`, `Reactor`,
`Alerta`, más `Mecha` (los primarios del RX-78) y `Eva`. El defecto NO son los
primarios: no dicen "máquina".

Muchos de estos motivos usan `fill-rule="evenodd"` para vaciar el interior
(damero de la etiqueta, tornillos de la brida, rayo del diamante, cubo del
engranaje). Es lo que les da lectura de pieza real y no de mancha.

### Estilo `animal` — el límite de lo procedural

**Las siluetas no son procedurales y no pueden serlo.** No hay regla geométrica
que produzca una mariposa reconocible. `SILUETAS` es una biblioteca curada de 24
figuras dibujadas a mano, cada una mirando hacia arriba en una caja de ±52
unidades. Lo procedural es cómo se eligen, se escalan y se distribuyen por los
anillos. Añadir un animal = añadir una entrada al objeto.

- **Insectos:** mariposa, libélula, abeja (rayas huecas), escarabajo (seis patas
  y línea de élitros), araña (ocho patas), mariquita (cuatro puntos huecos).
- **Aves:** ave (vista desde arriba), búho (ojos huecos), golondrina (cola
  ahorquillada), colibrí (pico largo), y pluma de pavo real con el ojo hueco.
- **Marinos:** pez, delfín, ballena, medusa, cangrejo, estrella de mar, concha.
- **Otros:** tortuga, gato, huella, conejo, elefante, rana.

**Al dibujar una silueta nueva, mirarla aislada antes de darla por buena.**
Cuatro de las diez últimas no se leían al primer intento y todas fallaban por lo
mismo: **falta de contraste de silueta**. El elefante era tres bultos pegados
hasta que las orejas salieron bien fuera del contorno de la cabeza y la trompa
se estrechó; la ballena y el delfín parecían un pez cualquiera hasta que el
cuerpo se estrechó y la cola creció. Una figura se reconoce por lo que sobresale
de su masa principal, no por su masa principal.

El generador limita las repeticiones a 12 y exige bandas de más de 44 unidades:
por debajo de eso la silueta no se lee. Entre silueta y silueta se intercalan
puntos, porque pocas figuras dejan la circunferencia medio vacía.

**Trampa del sentido de trazado (winding).** Al espejar una silueta para hacer
el lado derecho se invierte el orden de los vértices, y la regla `nonzero`
cancela el relleno donde la pieza se solapa con el cuerpo. Eso hacía que al gato
le desapareciera una oreja mientras la otra se veía bien. La solución es
escribir la pieza espejada con los vértices en orden inverso
(`M 26,-14 L 6,-28 L 34,-46 Z` en vez de `M 26,-14 L 34,-46 L 6,-28 Z`).
El mismo mecanismo, usado a propósito, hace los **ojos del búho**: se dibujan
con `sweep 0`, al revés que el cuerpo, y quedan como agujeros.

## Decisiones tomadas (y por qué)

- **SVG y no Canvas.** Cada figura es un elemento del DOM, así que tocar para
  pintar sale gratis (sin hit-testing manual), el export es vectorial e
  imprimible, y el zoom no pixela.
- **Pintar afecta a la capa entera**, no a una figura suelta. Es un mandala:
  romper la simetría al colorear no tiene sentido. Efecto secundario útil en
  móvil: hay `k` blancos válidos para el mismo objetivo, así que acertar con el
  dedo es fácil.
- **Chips de capas** en la pestaña Color como alternativa a tocar el dibujo. Es
  la salida para los motivos finos que el dedo no alcanza.
- **El botón de color libre lleva anillo de arcoíris y un `+`** (`#pickerWrap`).
  Antes era un círculo más entre los swatches de la paleta y nadie entendía que
  ahí se elegía cualquier color. El `<input type="color">` va invisible encima.

**El modo línea une los subtrazados con `paint-order="stroke fill"`.** Una
silueta de animal es un solo path con varios subtrazados (cuerpo + patas +
alas). Al trazarlo se dibuja el contorno de CADA subtrazado, incluidos los
bordes internos donde una pata se solapa con el cuerpo: las piezas se veían
separadas, con líneas cortándolas por dentro. Con `paint-order="stroke fill"`
se pinta primero el trazo y encima el relleno, así el relleno tapa los trazos
que caen dentro de la figura y solo queda su contorno exterior. Los huecos
(`evenodd`) siguen viéndose, porque ahí no hay relleno que tape.
El grosor se dobla (5.2 en vez de 2.6) porque la mitad interior del trazo queda
tapada. Solo se aplica a las figuras macizas y solo en modo línea.

**El modo línea rellena con el color del papel, opaco.** No con `none` ni con
`transparent`. Tres razones, y las tres importan:

1. **Sin cruces.** Una lámina para colorear no puede mostrar las líneas de un
   anillo atravesando las del anillo vecino: no se entiende qué zona es qué. Con
   relleno opaco cada figura tapa lo que tiene debajo y, como el orden de
   dibujado va de fuera adentro, las figuras interiores se ven enteras sobre las
   exteriores.
2. **Hit-test.** Con `fill:none` el interior de la figura deja de existir para
   el navegador: solo se podía acertar sobre la línea misma y pintar tocando el
   dibujo era imposible.
3. Pintar estando en modo línea guardaba el color sin mostrar nada y la app
   parecía rota — ahora `aplicarColor` sale del modo línea sola, porque si el
   usuario pinta es que quiere ver color.

El papel sale de `opaco(fondo)`: el color de fondo si es sólido, blanco si el
fondo es transparente (no hay nada detrás que copiar), y un oro sólido si es el
degradado — dentro del grupo escalado de una maqueta el degradado se resolvería
en otra escala y se verían las costuras. Por eso también el degradado usa
`gradientUnits="userSpaceOnUse"`: continuo por todo el lienzo, no uno por pieza.

**Trampa del pointer capture — no volver a pisarla.** Los cuatro botones
flotantes (deshacer, rehacer, solo líneas, zoom) viven DENTRO de `#escena`, que
hace `setPointerCapture` en cada `pointerdown` para gestionar el pellizco y el
arrastre. Sin una guarda, esa captura redirige el `pointerup` al lienzo y el
`click` del botón nunca llega a dispararse: los cuatro botones quedan muertos
sin ningún error en consola. La guarda es `enControl(e)`, que ignora los
eventos nacidos sobre `#acciones`, tanto en `pointerdown` como en el `pointerup`
que pinta. Cualquier control nuevo que se ponga sobre el lienzo necesita
entrar en esa guarda.
- **Cada estilo trae su paleta por defecto** (`ESTILOS[id].pal`). Un circuito
  en rosa no se lee como lo que es. Dos defectos corregidos aquí: el yantra
  arrancaba en tonos tierra y la primera impresión era apagada (ahora arranca
  en `Flor`, y hay `Joya`, `Pastel` y `Sorbete`); y los mechas arrancaban con
  los primarios del RX-78, que no dicen "máquina" (ahora `Titanio`, con
  `Hangar` —gris cañón y amarillo de seguridad— y `Reactor` —acero y cian de
  energía— al lado).
- **Acabados de color** (`estado.acabado`: `plano`, `acuarela`, `lapiz`). Son
  filtros SVG (`FILTROS`) aplicados **al grupo entero del mandala de una vez**,
  no pieza a pieza: con 79 piezas, un filtro por pieza sería inasumible.
  **El filtro va SOLO en los rellenos, nunca en los contornos.** Por eso
  `pintado()` emite dos pasadas cuando hay acabado: rellenos dentro del filtro,
  contornos limpios encima (`cuerpoMandala(..., 'relleno' | 'trazo')`). Filtrar
  también las líneas hacía que ondularan y el resultado parecía un reflejo bajo
  el agua, no una pintura. En una acuarela o un lápiz reales la tinta del
  dibujo queda nítida y solo el color está trabajado.
  **Acuarela:** se reconoce por cuatro cosas y hacen falta LAS CUATRO — quitar
  cualquiera y deja de parecer pintura:
  (1) la mancha no respeta el contorno (borde irregular por desplazamiento);
  (2) granulación con motas **claras y oscuras**, no solo oscuras — se hace con
  dos pasadas, una en `screen` y otra en `multiply`, con ruidos distintos;
  (3) el pigmento se acumula en el borde al secarse (`feMorphology` erosiona la
  forma, se le resta a sí misma para quedarse con una franja de borde y esa
  franja se multiplica encima);
  (4) la pintura es **translúcida** y deja ver el papel (`feComponentTransfer`
  con `slope 0.80` sobre el alfa).
  Versiones anteriores tenían solo (1) y (3) flojas: se veía color plano
  ondulado, no una aguada.
  **Lápiz:** es GRANO, no rayas. Una versión anterior usaba `baseFrequency` muy
  distinta en X e Y (`0.015 0.85`) y eso produce **franjas horizontales largas**,
  que no se parecen a un lápiz. Ahora la frecuencia es alta en los dos ejes
  (`0.55 0.72`), con solo un leve sesgo: se lee como el diente del papel.
  Los filtros **sobreviven a la exportación**: `drawImage` de un SVG en data URI
  los rasteriza (comprobado: el PNG de acuarela pasa de 1814 a 4322 colores
  distintos respecto al plano).
- **El color de los contornos se elige** (`estado.trazos`: `tinta`, `varios`,
  `claro`). Antes todos los trazos iban al color más oscuro de la paleta sin
  alternativa. `claro` usa el acento de la paleta, no un tono pálido — por eso
  el botón dice "Vivos" y no "Claros".
- **La taza lleva el mandala centrado en su BASE**, no un medallón pegado al
  frente: el dibujo se abre hacia arriba y cubre toda la pieza. Necesita tres
  cosas a la vez, y sin las tres no funciona: un `clip` con la silueta del
  cuerpo (en un grupo EXTERIOR al del `transform`, para que sus coordenadas
  sean las del objeto y no las del mandala escalado), `s = 1.08` para que el
  radio alcance las esquinas superiores desde el centro de la base, y una capa
  `encima` con los brillos, la boca y la base — son la cerámica, no el
  estampado, así que van después del mandala.
- **Maquetas dibujadas con paths, no imágenes.** Camiseta, bolsa, taza y pared
  viven en `VISTAS` como funciones que devuelven SVG. Así no hay recursos
  externos y la app sigue funcionando offline. El volumen se consigue con
  capas de negro semitransparente encima del color del material, nunca con
  colores fijos: así funcionan igual sobre blanco, negro o el degradado de oro.
  La camiseta lleva cuello acanalado, costuras de manga, puños y dobladillo;
  la bolsa, refuerzos de asa y pespunte discontinuo; la taza, boca elíptica con
  sombra interior y brillo vertical.
- **El zoom necesita botones visibles.** Hubo una versión en la que el zoom se
  hacía solo con pellizco y Ctrl+rueda, y el único botón (⤢) *restablecía* la
  vista en vez de ampliar: para quien usa ratón el zoom simplemente dejó de
  existir. Ahora hay **−** y **+** explícitos, con `disabled` en los topes
  (100% y 800%), más ⤢ para volver a ver el mandala entero. El pellizco y la
  rueda siguen funcionando como atajo — debajo del lienzo no hay nada que
  desplazar, así que la rueda ahí no compite con ningún otro gesto.
  Lección general: un gesto sin control visible equivale a no tener la función.
- **"Solo líneas" usa tinta de contraste**, calculada por luminancia contra el
  fondo elegido. Así el modo sin color funciona igual sobre blanco (página para
  colorear) que sobre negro u oro (previsualización de estampado).
- **Sin librerías, sin red, sin fuentes remotas.** Funciona offline.

### Lo que se está pintando sobrevive a cerrar la app

`localStorage['mandalas.actual']` guarda **la misma instantánea que usa el
historial** —semilla, ajustes, paleta, fondo, vista, acabado y el color de cada
figura—: unos 800 bytes. Nunca la imagen. Al volver, el mandala se regenera de
la semilla y se le aplican los colores guardados. Se escribe en `empujar()`, que
es por donde pasa todo cambio de estado, así que no hay nada que recordar
guardar.

**Qué gana el enlace compartido.** Al arrancar se restaura lo guardado *salvo*
que la URL traiga una semilla distinta a la guardada: eso significa que alguien
abrió un enlace ajeno, y ahí manda el enlace. Como `pintar()` deja la semilla en
la URL con `replaceState`, al recargar la página coincide y se restaura igual.

**Mirar no puede borrar.** Al abrir un enlace ajeno, el arranque llama a
`empujar(false)`: no guarda. Si no, con solo mirar el mandala de otra persona se
perdía el propio a medio pintar. En cuanto se toca algo sí se guarda — ahí la
persona cambió de trabajo a propósito.

**Red de seguridad al actualizar la app.** Si un estilo cambia y ese mismo
generador ahora produce otro número de figuras, los colores guardados dejan de
corresponder. `aplicarSnap()` compara largos y recolorea si no cuadran; sin eso
aparecían piezas grises sueltas (`estado.colores[i] || '#333'`).

### Lámina en blanco: pintar desde cero

`estado.enBlanco` + `vaciarColores()`. La mandala nace como una lámina recién
impresa —papel y contornos de tinta— y se pinta figura por figura.

**No hay un modo de dibujo nuevo, y ese es todo el truco:** basta con que TODOS
los rellenos valgan el color del papel (`opaco(colorFondo())`) y los contornos
la tinta que contrasta (`tinta()`). Pintar tocando, deshacer, las capas, los
acabados, las maquetas y la exportación siguen funcionando sin una sola rama
especial. Las sombras cel se pintan del color del papel: con `opacity 0.28`
encima del papel desaparecen, que es lo que corresponde en una lámina virgen.

**El modo "solo líneas" NO sirve para esto**, aunque se parezca: ahí los
rellenos no se guardan y al pintar se sale del modo. Ese modo es para imprimir
la lámina; este es para pintarla en pantalla.

Tres reglas que salieron de usarlo:

- **Queda activado.** Los mandalas que se generen después también nacen sin
  pintar (`colorearInicial()` es el único punto que decide). Quien entra a
  pintar quiere pintar varios, no volver a pedirlo cada vez.
- **Elegir paleta no repinta nada** estando en blanco: solo cambia los colores
  disponibles. Repintar borraría lo que la persona lleva hecho.
- **El selector de Contornos tampoco aplica**, por lo mismo.

`Auto-colorear` apaga el modo y devuelve el coloreado por paleta.

### El selector de color es propio, no el del sistema

Era un `<input type="color">`. En el escritorio abre una paleta cómoda, pero
**ese input delega en el selector del sistema operativo**: en Android abre un
diálogo tosco y en iPhone otro distinto. La misma app se usaba de tres maneras
y en el celular era la peor — que es justo donde se usa.

El selector propio (`#colorSheet`, `abrirColor()`) se ve igual en los tres y
ofrece dos caminos, los dos pensados para el dedo:

- **Rejilla de 30 chips** de 44 px — 8 tonos × 3 claridades + 6 grises. La
  primera versión tenía 56 (12 tonos × 4 + 8 grises) y la hoja crecía tanto
  que el botón de confirmar quedaba fuera de la pantalla del teléfono. Para el
  resto de los colores están los deslizadores, que es para lo que sirven.
- **Tono / Intensidad / Brillo**, en HSL, cada uno con su propio degradado de
  fondo calculado con los otros dos valores: el color se elige mirando, no
  leyendo un número.

Detalles que importan: el botón de confirmar va `position:sticky` al fondo de la
hoja; los últimos 10 colores usados quedan en `localStorage` (pintar suele
querer repetir un color en varias capas); y en escritorio la hoja se ancla
abajo a la derecha en vez de ocupar todo el ancho.

`hslHex()` / `hexHsl()` hacen la conversión, comprobada de ida y vuelta sobre
ocho colores con tolerancia de 6/765 en la suma de canales.

## Preparado para empaquetar (Capacitor)

Dos puntos del código son la frontera con lo nativo. Al empaquetar, solo se
tocan estos:

- **Sección 11 — capa de archivo/compartir.** `entregar()`, `svgBlob()`,
  `guardarImagen()`. Es el único lugar que toca descargas, portapapeles o
  `navigator.share`. Se reemplaza por los plugins de Capacitor (Filesystem +
  Share) sin tocar nada más.
- **Sección 1 — frontera de pago.** `esPro()` hoy devuelve `true` siempre.
  `LIMITES_GRATIS` / `LIMITES_PRO` definen qué cambia: resolución, marca de
  agua, paletas, motivos y **estilos** (gratis solo `geo` y `natura`).
  Conectar RevenueCat es cambiar el cuerpo de `esPro()`.

Modelo de monetización decidido: **gratis con desbloqueo Pro de pago único**.
Sin anuncios (arruinan una app de relajación) y sin suscripción (nadie paga
mensual por colorear).

### El deslizador de Detalle

`cfg.densidad` controla **cuántos adornos** lleva cada figura: contornos
interiores, puntos, perlas y nervaduras. Cada generador debe gatear sus
elementos opcionales con él (`dens > 0.35`, `rnd() < dens`, …). Si no, el
deslizador no cambia nada visible y el usuario no entiende para qué está —
que es exactamente lo que pasaba en `geo`, `circuito` y `animal`.
En `capaPetalos` viaja como `opts.detalle` y decide, por umbrales, si el pétalo
lleva segundo contorno, gota, perlas y rayado.

**Regla al añadir un estilo:** comprobar que el número de piezas crece de forma
monótona al subir el deslizador de 0 a 100. Medición actual:

| estilo | 0 → 100 |
|---|---|
| geo | 12 → 25 |
| hindu | 31 → 65 |
| africano | 14 → 30 |
| circuito | 23 → 32 |
| animal | 18 → 23 |
| robot | 34 → 41 |
| natura | 16 → 23 |

`circuito` y `natura` estaban planos (25 → 27 y 16 → 18: el deslizador no hacía
nada) y se arreglaron gateando adornos con `dens`. En circuito, además, la
probabilidad de banda vacía **baja** con el Detalle, que es lo que más se nota.

## Verificado

- 1050 combinaciones aleatorias de estilo × simetría (3–64) × anillos (3–14) ×
  detalle: cero geometría inválida en los siete estilos.
- Inventario: 133 motivos, 21 glifos estarcidos, 24 siluetas, 11 núcleos de
  yantra, 28 paletas. Máximo 83 piezas en un mandala.
- Los 22 motivos nuevos (12 de circuito/HUD, 10 de naturaleza rellena) se
  construyen sin geometría inválida y se comprobaron en 500 mandalas de esos dos
  estilos con simetría 4–64, 3–14 anillos y detalle 0–100: cero fallos.
- Reparto relleno / trazo por estilo, medido sobre 120 mandalas cada uno:
  animal 80% · robot 68% · **natura 64%** · geo 52% · circuito 49% ·
  africano 44% · hindu 42%. Natura era el más bajo de los siete antes de
  rellenar su vocabulario.
- Tras dejar solo los cañones: los 16 motivos del vocabulario mecha (5 de
  artillería, 3 de cabeza, 4 de unión, 4 de estructura y señalética) se usan
  todos al generar 400 mandalas de robots, y suman el 38% de las llamadas a
  `MOTIVOS` en ese estilo. Cero geometría inválida en esas 400.
- Los 16 motivos comprobados **aislados** en corona de 8 (rejilla de
  `modo=motivos`): todos se leen como la pieza que son. Los tres cañones largos
  —`canon`, `railgun`, `bocacha`— se parecen bastante entre sí; no molesta
  porque nunca coinciden en el mismo anillo.
- El sombreado cel aparece solo en `robot`, sus piezas reciben el tono oscuro de
  la paleta, el recorte sobrevive a la exportación a PNG (63 referencias de
  `clip-path` en el SVG exportado) y desaparece por completo en modo línea.
- Los 10 motivos mecha nuevos se usan todos al generar 400 mandalas de robots
  (medido instrumentando las llamadas a `MOTIVOS`, no comparando paths: un
  motivo devuelve coordenadas distintas según el radio, así que comparar
  cadenas da falsos negativos).
- Las 24 siluetas salen todas al generar 600 mandalas de animales.
- `paint-order` se emite solo en modo línea (15 grupos frente a 0 en color) y
  sobrevive a la rasterización a PNG.
- Peor caso de rendimiento por estilo (simetría 64, 14 anillos, detalle 100):
  animal 1.1 ms · geo 1.7 · robot 2.6 · natura 2.9 · africano 3.3 ·
  circuito 3.7 · **hindu 6.8 ms**. Objetivo era < 100 ms. Repetido tras
  rehacer robot, circuito y natura: peor caso de 1050 tiradas aleatorias
  7.0 ms (natura), y a tope de mandos (simetría 64, 14 anillos, detalle 100)
  ningún estilo pasa de 0.7 ms.
- Reparto marco/sin marco en el hindú medido sobre 300 semillas: 148 / 152.
- 1050 combinaciones de estilo × vista × fondo × modo línea × acabado: todas
  producen SVG válido, con el filtro correcto aplicado y con recorte en la taza.
- La taza exporta bien a PNG con el recorte puesto (plano y acuarela), conserva
  la transparencia alrededor de la pieza y se sigue pudiendo pintar tocándola.
- Exportar PNG con filtro: 21 ms (lápiz) a 64 ms (acuarela) a 1200 px.
- En modo línea, las figuras de relleno reciben el color de papel opaco en los
  cuatro tipos de fondo (blanco, negro, transparente y oro).
- Los tres modos de contorno producen colores distintos y el modo elegido viaja
  en el historial de deshacer.
- Orden de dibujado comprobado: va de `z = -454` (el bhupura, al fondo) a
  `z = 0` (el bindu, encima de todo), los índices de capa siguen siendo únicos
  y el pintado por capa sigue funcionando.
- Los cuatro botones flotantes comprobados con clics reales tras el arreglo del
  pointer capture: deshacer y rehacer mueven el puntero del historial, solo
  líneas alterna, zoom vuelve a 100%.
- Pintado comprobado con clics reales: sobre el dibujo en modo color, y en modo
  línea (acierta, pinta y sale del modo línea sola).
- Rueda sola no hace zoom; Ctrl+rueda sí; el botón ⤢ devuelve a 100%.
- Las 350 combinaciones de estilo × vista × fondo × modo línea producen SVG
  válido.
- Export PNG correcto en los siete estilos, incluidos los que usan `evenodd`
  (pads, tuercas) y `tr` (siluetas, rosetas).
- Lámina en blanco: 2100 combinaciones (los 1050 de siempre × modo normal y en
  blanco) producen SVG válido; pintar, deshacer y rehacer funcionan figura a
  figura; cambiar de paleta no borra lo pintado; el mandala siguiente nace en
  blanco.
- Persistencia comprobada en los tres casos: reabrir sin semilla en la URL
  restaura estilo, ajustes, fondo, acabado, modo y los colores figura por
  figura (804 bytes guardados); abrir un enlace con otra semilla muestra ese
  mandala y **no** pisa lo guardado; volver a abrir sigue recuperando lo propio.
  Datos corruptos y guardados de una versión anterior con menos colores caen
  ambos en el camino seguro.
- Ida y vuelta por `instantanea()` / `aplicarSnap()` idéntica en los 7 estilos.

## Camino a publicación

Cuatro fases. Cada una se valida antes de pagar por la siguiente.

| Fase | Qué es | Cuesta | Estado |
|---|---|---|---|
| 0 | Repo git, iconos PNG, service worker, README | — | **hecho** |
| 1 | Web pública en GitHub Pages (HTTPS gratis) | — | falta la cuenta de GitHub |
| 2 | Instalable como app (PWA) desde el navegador | — | listo; se comprueba al estar en HTTPS |
| 3 | APK/AAB nativo con Capacitor | requiere Node.js + Android Studio | pendiente |
| 4 | Publicación en tiendas | Google USD 25 pago único · Apple USD 99/año + Mac | pendiente |

**Fase 0 (hecha).** `git init` + primer commit; `sw.js` (red primero para el
HTML, caché primero para iconos — servir el HTML desde caché enterraría
cualquier corrección, porque toda la app vive en ese archivo); iconos PNG 192,
512, 1024 y `apple-touch-icon` 180; `manifest.json` con los PNG (Android e iOS
no bastan con SVG); metas de `apple-mobile-web-app-*`; `.gitignore` y `README`.

> **Los iconos se generaron con Chrome headless a 1024 y se redujeron con
> `System.Drawing`.** Capturar directamente a 192 o 180 devuelve una imagen en
> blanco: Chrome impone un tamaño mínimo de ventana y el `--window-size` chico
> se ignora. El archivo salía de 700 bytes en vez de 19 KB, que es la señal.

**Fase 1.** Repo público `mandalas` en GitHub → `git remote add origin` →
`git push -u origin main` → Settings ▸ Pages ▸ Deploy from branch `main` / root.
La URL queda `https://USUARIO.github.io/mandalas/`. Actualizar el enlace del
README. Sin `gh` instalado, el push lo tiene que autenticar el usuario.

**Fase 3.** `npm i @capacitor/core @capacitor/cli`, `npx cap init`,
`npx cap add android`, la carpeta web es la raíz del proyecto. Ojo con lo ya
resuelto en el código: `replaceState` en vez de `pushState` (el botón atrás del
webview), `navigator.share` con respaldo a descarga, y `esPro()` en la sección 1
como único punto donde se decide qué está bloqueado.

## Pendiente
- [ ] Galería local con `localStorage` guardando solo estilo + semilla + paleta
      + colores manuales (un proyecto guardado debe pesar menos de 1 KB, nunca
      imágenes).
- [ ] Animación de construcción (los anillos aparecen de dentro hacia afuera).
- [ ] Empaquetar con Capacitor. Android primero: cuenta de desarrollador
      USD 25 pago único vs USD 99/año de Apple.

## Fuentes sobre la estructura del yantra

- [Sri Yantra — Wikipedia](https://en.wikipedia.org/wiki/Sri_Yantra)
- [The Sri Yantra: Meaning, Symbolism and Spiritual Power — Gaia](https://www.gaia.com/article/what-is-the-power-of-shri-yantra)
- [The Art of Sacred Geometry: Mandalas, Yantras & the Cosmic Order — MeMeraki](https://www.memeraki.com/blogs/posts/the-art-of-sacred-geometry-mandalas-yantras-and-cosmic-order)
- [5 Motifs for Mandalas Inspired by Indian Art — Blululi](https://blululi.com/blogs/news/5-motifs-for-mandalas-inspired-by-indian-art)
- [Motivos mágicos: colorear mandalas — STAEDTLER](https://www.staedtler.com/pe/es/descubrir/motivos-magicos-colorear-mandalas/)
  (banco de plantillas, no guía técnica; sirve como referencia de estética:
  línea fina y muy densa)

## Fuentes sobre la planta de un microchip

- [VLSI Floorplanning – Step by Step Deep Dive — EcrioniX](https://ecrionix.org/vlsi/floorplanning/)
- [Full-chip layout — Advanced Digital Systems Design, WPI](https://schaumont.dyn.wpi.edu/ece574f24/10fclayout.html)
- [Floorplan Guidelines for Sub-Micron Technology Node — Design & Reuse](https://www.design-reuse.com/article/61421-floorplan-guidelines-for-sub-micron-technology-node-for-networking-chips/)

---

*Creado: 2026-08-04 · Siete estilos, maquetas y modo sin color: 2026-08-04*
