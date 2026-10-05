const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const htmlPath = path.join(root, 'dist/index.html');
const html = fs.readFileSync(htmlPath, 'utf8');
const size = fs.statSync(path.join(root, 'dist/index.pck')).size;
if (!/'index\.pck':\d+/.test(html)) throw new Error('Metadado de tamanho do PCK ausente');
fs.writeFileSync(htmlPath, html.replace(/'index\.pck':\d+/, `'index.pck':${size}`));
console.log(`Pacote web: ${size} bytes`);
