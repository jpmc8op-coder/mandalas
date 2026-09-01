
/* --- hoja de contacto (inyectada, se ejecuta en el mismo ámbito) --- */
(function(){
  // El arranque de la app ya hizo replaceState('?seed=...'), así que location
  // ya no trae los parámetros de la hoja: hay que leer la URL de navegación.
  const nav = (performance.getEntriesByType('navigation')[0] || {}).name || location.href;
  const P = new URLSearchParams(nav.split('?')[1] || '');
  if (!P.get('hoja')) return;
  // `modo=grafico`: el gráfico destacado de la ficha (1024x500). Se compone con
  // las mandalas de la propia app, no con un montaje aparte, para que lo que se
  // anuncia sea exactamente lo que la app dibuja.
  if (P.get('modo') === 'grafico'){
    const listo = () => {
      const mandala1 = (est, sem, pal, n, a, d) => {
        estado.cfg = { estilo: est, simetria: n, anillos: a, densidad: d };
        estado.semilla = sem; estado.paleta = iPaleta(pal);
        estado.vista = 'plano'; estado.fondo = 'transparente'; estado.lineas = false;
        estado.acabado = 'plano'; estado.enBlanco = false; estado.fondoColor = null;
        estado.piezas = {};
        mandala = generar(sem, estado.cfg); autoColorear();
        return svgMarkup();
      };
      const g = document.createElement('div');
      g.style.cssText = 'position:fixed;inset:0;z-index:99999;width:1024px;height:500px;'
        + 'background:radial-gradient(120% 150% at 22% 40%,#1e2738,#0f131c 70%);'
        + 'overflow:hidden;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif';
      g.innerHTML =
          '<div style="position:absolute;left:-90px;top:-120px;width:420px;height:420px;opacity:.55">'
        + mandala1('hindu', 8080, 'Flor', 14, 8, 70) + '</div>'
        + '<div style="position:absolute;right:-96px;top:172px;width:400px;height:400px;opacity:.5">'
        + mandala1('robot', 21, 'Escuadrón', 12, 7, 70) + '</div>'
        + '<div style="position:absolute;left:150px;bottom:-230px;width:300px;height:300px;opacity:.3">'
        + mandala1('natura', 60606, 'Selva', 10, 6, 55) + '</div>'
        + '<div style="position:absolute;left:360px;top:118px;width:560px;text-align:center">'
        + '<div style="font-size:74px;font-weight:800;letter-spacing:-.02em;color:#fff;'
        + 'text-shadow:0 4px 24px #0009">Mandalas</div>'
        + '<div style="font-size:27px;color:#f2a65a;font-weight:600;margin-top:10px">'
        + 'Crea y colorea · sin conexión</div>'
        + '<div style="font-size:20px;color:#a8b3c7;margin-top:16px;line-height:1.5">'
        + 'Siete estilos · infinitos diseños<br>Pinta con el dedo, figura por figura</div>'
        + '</div>';
      document.body.appendChild(g);
    };
    if (document.readyState === 'complete') listo();
    else window.addEventListener('load', listo);
    return;
  }

  // `modo=app`: no dibuja rejilla, solo deja la app en un estado concreto para
  // fotografiarla. Es lo que se usa para las capturas de la ficha de la tienda.
  if (P.get('modo') === 'app'){
    const listo = () => {
      const num = (k, d) => P.get(k) !== null ? +P.get(k) : d;
      estado.cfg = { estilo: P.get('e') || 'geo', simetria: num('n', 12),
                     anillos: num('a', 7), densidad: num('d', 60) };
      estado.semilla = num('s', 4242);
      if (P.get('p')) estado.paleta = iPaleta(P.get('p'));
      estado.vista = P.get('v') || 'plano';
      estado.fondo = P.get('f') || 'blanco';
      estado.acabado = P.get('ac') || 'plano';
      estado.lineas = P.get('l') === '1';
      estado.enBlanco = P.get('b') === '1';
      mandala = generar(estado.semilla, estado.cfg);
      colorearInicial();
      if (P.get('pinta'))                       // "capa:copia:color,..."
        P.get('pinta').split(',').forEach(t => {
          const [i, j, c] = t.split(':');
          estado.piezas[i + ':' + j] = '#' + c;
        });
      if (P.get('fondoc')) estado.fondoColor = '#' + P.get('fondoc');
      sincronizarControles();
      pintar(false);
      const tab = P.get('tab');
      if (tab) document.querySelector('#tabs button[data-hoja="' + tab + '"]').click();
      if (P.get('plegado') === '1') document.getElementById('bPlegar').click();
      if (P.get('gal')) try { localStorage.setItem('mandalas.galeria', P.get('gal')); } catch {}
      // Sin `tour`, se cierra el recorrido de bienvenida: en un perfil nuevo la
      // app cree que es la primera vez y lo abre a los 900 ms, tapando la
      // captura. Con `tour=N` se abre a propósito.
      if (!P.get('tour'))
        setTimeout(() => { if (typeof tourCerrar === 'function') tourCerrar(); }, 1100);
      // `tour=N` abre el recorrido en el paso N (1..7), para fotografiarlo.
      if (P.get('tour') && typeof tourAbrir === 'function'){
        tourAbrir();
        const n = Math.max(1, Math.min(TOUR.length, +P.get('tour'))) - 1;
        setTimeout(() => tourIr(n), 60);
      }
      if (typeof dibujarGaleria === 'function') dibujarGaleria();
    };
    if (document.readyState === 'complete') listo();
    else window.addEventListener('load', listo);
    return;
  }

  const pintaHoja = () => {
    const g = document.createElement('div');
    g.style.cssText = 'position:fixed;inset:0;z-index:99999;background:#fff;display:grid;'
      + 'grid-template-columns:repeat(' + (P.get('modo')==='motivos'?4:3) + ',1fr);'
      + 'gap:6px;padding:6px;overflow:hidden';
    if (P.get('modo') === 'siluetas'){
      // Las siluetas de animales se juzgan aisladas y en negativo: lo único que
      // importa es si se reconocen de un vistazo a tamaño pequeño.
      g.style.gridTemplateColumns = 'repeat(' + (P.get('cols') || 4) + ',1fr)';
      const lista = P.get('m') ? P.get('m').split(',') : Object.keys(SILUETAS);
      lista.forEach(n => {
        const d = document.createElement('div');
        d.style.cssText = 'position:relative;background:#fff';
        d.innerHTML = '<svg viewBox="-62 -62 124 124" style="width:100%;display:block">'
          + '<path d="' + SILUETAS[n] + '" fill="#2C3A47"/></svg>'
          + '<b style="position:absolute;left:6px;bottom:2px;font:12px monospace;color:#777">' + n + '</b>';
        g.appendChild(d);
      });
      document.body.appendChild(g);   // las otras ramas caen al append del final
      return;
    }

    if (P.get('modo') === 'motivos'){
      P.get('m').split(',').forEach(n => {
        const m = MOTIVOS[n](70, 150, 180/8*0.92, mulberry32(7));
        let s = '<svg viewBox="-200 -200 400 400" style="width:100%">'
              + '<rect x="-200" y="-200" width="400" height="400" fill="#fff"/>';
        for (let i = 0; i < 8; i++)
          s += '<path d="' + m.d + '" transform="rotate(' + (45*i) + ')" fill="'
             + (m.trazo ? 'none' : '#39506B') + '" stroke="#111" stroke-width="'
             + (m.trazo ? 3 : 2) + '"' + (m.evenodd ? ' fill-rule="evenodd"' : '')
             + ' stroke-linejoin="round"/>';
        const d = document.createElement('div');
        d.style.position = 'relative';
        d.innerHTML = s + '</svg><b style="position:absolute;left:6px;top:2px;font:12px monospace;color:#777">' + n + '</b>';
        g.appendChild(d);
      });
    } else {
      const num = k => (P.get(k[0]) || k[1]).split(',').map(Number);
      const semillas = num(['s','11,23,47,88,131,205']);
      const sim = num(['n','8,10,12,14,16,20']);
      const an  = num(['a','6,7,8,7,9,8']);
      const de  = num(['d','45,65,80,55,90,70']);
      semillas.forEach((s, i) => {
        estado.cfg = { estilo: P.get('e') || 'robot', simetria: sim[i%sim.length],
                       anillos: an[i%an.length], densidad: de[i%de.length] };
        estado.semilla = s;
        estado.paleta = iPaleta(P.get('p') || 'Casco');
        estado.colores = []; estado.fondo = 'blanco'; estado.vista = 'plano';
        estado.lineas = P.get('l') === '1';
        estado.acabado = P.get('ac') || 'plano';
        estado.trazos = 'tinta';
        mandala = generar(s, estado.cfg);
        autoColorear();
        const d = document.createElement('div');
        d.style.position = 'relative';
        d.innerHTML = svgMarkup()
          + `<b style="position:absolute;left:6px;top:2px;font:12px monospace;color:#777">`
          + `${s} · N${estado.cfg.simetria} · a${estado.cfg.anillos} · d${estado.cfg.densidad}</b>`;
        g.appendChild(d);
      });
    }
    document.body.appendChild(g);
  };
  if (document.readyState === 'complete') pintaHoja();
  else window.addEventListener('load', pintaHoja);
})();
