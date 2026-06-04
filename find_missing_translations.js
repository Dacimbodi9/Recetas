const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      if (file.endsWith('.dart')) results.push(file);
    }
  });
  return results;
}

const files = walk('C:/Users/danie/Apps/Recetas/lib');
const trRegex = /'([^'\\]*(?:\\.[^'\\]*)*)'\.tr/g;
let allStrings = new Set();
files.forEach(f => {
  const content = fs.readFileSync(f, 'utf8');
  let match;
  while ((match = trRegex.exec(content)) !== null) {
    allStrings.add(match[1].replace(/\\'/g, "'"));
  }
});

const l10nContent = fs.readFileSync('C:/Users/danie/Apps/Recetas/lib/l10n.dart', 'utf8');
const existingKeys = new Set();
const keyRegex = /"([^"\\]*(?:\\.[^"\\]*)*)"\s*:/g;
let keyMatch;
while ((keyMatch = keyRegex.exec(l10nContent)) !== null) {
  existingKeys.add(keyMatch[1]);
}

const missing = [];
allStrings.forEach(s => {
  if (!existingKeys.has(s)) {
    missing.push(s);
  }
});

console.log('MISSING STRINGS:');
missing.forEach(s => console.log(s));
