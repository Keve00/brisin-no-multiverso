// Godot 4.5.1 SampleNode resumes restart sources even when already playing.
// Keep this pinned, idempotent fix in every regenerated web export.
const fs = require('node:fs');
const path = require('node:path');
const file = path.join(__dirname, '../dist/index.js');
const original = 'pause(enable=true){if(enable){this._pause();return}this._unpause()}';
const patched = 'pause(enable=true){if(enable===this.isPaused){return}if(enable){this._pause();return}this._unpause()}';
let bundle = fs.readFileSync(file, 'utf8');
if (bundle.split(patched).length === 2 && !bundle.includes(original)) {
 console.log('Web audio pause guard already installed.');
} else {
 if (bundle.split(original).length !== 2 || bundle.includes(patched)) {
  throw new Error('Unknown web audio runtime: review SampleNode before patching.');
 }
 fs.writeFileSync(file, bundle.replace(original, patched));
 console.log('Installed idempotent Web Audio Sample pause guard.');
}
