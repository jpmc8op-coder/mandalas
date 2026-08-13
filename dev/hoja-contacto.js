
/* --- hoja de contacto (inyectada, se ejecuta en el mismo ámbito) --- */
(function(){
  // El arranque de la app ya hizo replaceState('?seed=...'), así que location
  // ya no trae los parámetros de la hoja: hay que leer la URL de navegación.
  const nav = (performance.getEntriesByType('navigation')[0] || {}).name || location.href;
  const P = new URLSearchParams(nav.split('?')[1] || '');
  if (!P.get('hoja')) return;
  const pintaHoja = () => {
    const g = document.createElement('div');
    g.style.cssText = 'position:fixed;inset:0;z-index:99999;background:#fff;display:grid;'
      + 'grid-template-columns:repeat(' + (P.get('modo')==='motivos'?4:3) + ',1fr);'
      + 'gap:6px;padding:6px;overflow:hidden';
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
