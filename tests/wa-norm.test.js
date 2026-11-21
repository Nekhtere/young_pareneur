// Perilaku normalisasi nomor WA: 08..., +62..., 62..., 6208... -> 628...
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');

function ambilWaNorm(file) {
  const teks = fs.readFileSync(path.join(root, file), 'utf8');
  const m = teks.match(/function waNorm\(s\)\{[\s\S]*?return d;\s*\}/);
  if (!m) throw new Error('waNorm tidak ditemukan di ' + file);
  return new Function('return ' + m[0])();
}

const cases = [
  ['081234567890', '6281234567890'],
  ['0812 3456 7890', '6281234567890'],
  ['+6281234567890', '6281234567890'],
  ['+62 812-3456-7890', '6281234567890'],
  ['6281234567890', '6281234567890'],
  ['62081234567890', '6281234567890'],
  ['81234567890', '6281234567890'],
];

for (const file of ['index.html', 'dashboard.html']) {
  const waNorm = ambilWaNorm(file);
  for (const [input, expected] of cases) {
    const actual = waNorm(input);
    if (actual !== expected) {
      console.log(`FAIL ${file}: "${input}" -> "${actual}", expected "${expected}"`);
      process.exitCode = 1;
    }
  }
}
if (!process.exitCode) console.log('PASS - normalisasi WA konsisten di form dan dashboard');
