const scene = document.getElementById('house-scene');
const pause = document.getElementById('build-pause');
const replay = document.getElementById('build-replay');
const status = document.getElementById('build-status');
const phases = [...document.querySelectorAll('[data-phase]')];
const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
const names = { foundation: 'Laying the foundation', frame: 'Raising the frame', walls: 'Placing the walls', glazing: 'Fitting the windows', roof: 'Lowering the roof', finish: 'Adding the finishing details' };
let finished = false;
let current = 'foundation';
function start() {
  scene.classList.remove('is-running', 'is-paused');
  phases.forEach(p => p.classList.remove('active', 'done'));
  pause.textContent = 'Pause';
  finished = reduced.matches;
  pause.disabled = reduced.matches;
  replay.disabled = reduced.matches;
  if (reduced.matches) {
    phases.forEach(p => p.classList.add('done'));
    status.textContent = 'Assembled · reduced motion';
    return;
  }
  current = 'foundation';
  status.textContent = names[current];
  // Reflow restarts the finite CSS sequence on replay, including after completion.
  void scene.getBoundingClientRect();
  scene.classList.add('is-running');
}
scene.addEventListener('animationstart', event => {
  if (event.animationName !== 'home-piece-enter') return;
  current = event.target.dataset.stage;
  phases.forEach(p => p.classList.toggle('active', p.dataset.phase === current));
  status.textContent = names[current];
});
scene.addEventListener('animationend', event => {
  if (event.animationName !== 'home-piece-enter') return;
  const phase = phases.find(p => p.dataset.phase === event.target.dataset.stage);
  phase?.classList.add('done');
  if (event.target.dataset.stage === 'finish') {
    finished = true;
    pause.disabled = true;
    phases.forEach(p => p.classList.remove('active'));
    status.textContent = 'Home assembled';
  }
});
pause.addEventListener('click', () => {
  if (finished || reduced.matches) return;
  const paused = scene.classList.toggle('is-paused');
  pause.textContent = paused ? 'Resume' : 'Pause';
  status.textContent = paused ? 'Assembly paused' : names[current];
});
replay.addEventListener('click', start);
reduced.addEventListener('change', start);
start();
