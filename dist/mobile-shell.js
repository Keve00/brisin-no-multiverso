/* Mobile shell only publishes viewport/lifecycle facts; Godot owns gameplay. */
(() => {
 'use strict';
 const canvas = document.getElementById('canvas');
 const stage = document.getElementById('stage');
 const touch = matchMedia('(pointer: coarse)').matches;
 const state = window.brisinHost = {touch, portrait:false, hidden:document.hidden, interrupt:0, scale:1, menuRequest:0};
 document.body.classList.toggle('touch-device', touch);
 const rotation = document.createElement('div');
 rotation.id = 'rotate-device';
 rotation.innerHTML = '<p>Gire o celular para jogar em paisagem</p><button type="button">Voltar ao menu</button><small>A partida fica pausada.</small>';
 document.body.appendChild(rotation);
 rotation.querySelector('button').addEventListener('click', () => {state.menuRequest++;rotation.querySelector('small').textContent='Menu solicitado. Gire o celular para continuar.';});
 function measure() {
  const viewport = window.visualViewport;
  const width = viewport ? viewport.width : innerWidth;
  const height = viewport ? viewport.height : innerHeight;
  document.documentElement.style.setProperty('--view-height', height+'px');
  const previous = state.portrait;
  state.portrait = touch && height > width;
  if (previous !== state.portrait) state.interrupt++;
  const rect = canvas.getBoundingClientRect();
  state.scale = Math.min(rect.width/1152,rect.height/648);
  rotation.hidden = !state.portrait;
 }
 function interrupt() {state.interrupt++;state.hidden=document.hidden;}
 addEventListener('resize',measure);
 addEventListener('orientationchange',() => {interrupt();measure();});
 window.visualViewport?.addEventListener('resize',measure);
 document.addEventListener('visibilitychange',interrupt);
 addEventListener('blur',interrupt);
 addEventListener('pagehide',interrupt);
 // Never scroll/zoom over the playing canvas; GUI taps keep mouse emulation.
 canvas.addEventListener('contextmenu',event=>event.preventDefault());
 stage.addEventListener('touchmove',event=>event.preventDefault(),{passive:false});
 measure();
 new ResizeObserver(measure).observe(stage);
})();
