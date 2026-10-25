#!/usr/bin/env node
// Scan a SuperBLT log for Iter load status, nav events, Lua errors, and harness output.
//
// Usage:
//   node dev/tools/log-scan.mjs <logfile> [--mod DIR] [--out report.md] [--json report.json] [--strict]
//   node dev/tools/log-scan.mjs <logfile> --card dev/test/cards/T0-load.json

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const LUA_ERROR_RE = /attempt to (index|call|perform|compare|concatenate|arithmetic)|Lua: Error:/i;
const FATAL_RE = /FATAL ERROR|FATAL:/i;
const ERROR_MARKER_RE = /attempt to |Lua: Error:|stack traceback|FATAL ERROR|FATAL:/i;
const NAV_EVENT_RE = /\[ITER-NAV\]\s+(.*)$/;
const ITER_ERR_RE = /\[ITER-ERR\]\s+(.*)$/;

function normalizeHook(hook) {
  return String(hook || '').replace(/\\/g, '/').replace(/\.lua$/, '');
}

export function parseNavEvent(line) {
  const match = NAV_EVENT_RE.exec(line);
  if (!match) return null;

  const event = {};

  for (const token of match[1].trim().split(/\s+/)) {
    const eq = token.indexOf('=');
    if (eq <= 0) continue;
    const key = token.slice(0, eq);
    const raw = token.slice(eq + 1);
    const num = Number(raw);
    event[key] = raw !== '' && Number.isFinite(num) ? num : raw;
  }

  return event;
}

function sumField(events, field) {
  let total = 0;
  let seen = false;

  for (const event of events) {
    const value = event[field];
    if (typeof value === 'number') {
      total += value;
      seen = true;
    }
  }

  return seen ? total : undefined;
}

export function aggregateNavEvents(events) {
  const byType = {};

  for (const event of events) {
    const type = event.evt || 'unknown';
    byType[type] = byType[type] || [];
    byType[type].push(event);
  }

  return byType;
}

export function scanLog(text, { file = '', hookFiles = [] } = {}) {
  const lines = text.split(/\r?\n/);
  const hooks = new Set(hookFiles.map(normalizeHook));

  const setup = [];
  const harness = [];
  const harnessErrors = [];
  const fatal = [];
  const luaErrors = [];
  const iterErrors = [];
  const navEvents = [];
  const navEventLines = [];
  const errEvents = [];
  let setupSeen = false;

  const hasIterFrame = (startIndex) => {
    const stop = Math.min(lines.length, startIndex + 8);

    for (let i = startIndex; i < stop; i++) {
      const line = lines[i];
      if (/\[ITER-(NAV|TEST|ERR)\]|mods[\\/]Iter\b|Iter\.lua/i.test(line)) return true;
      for (const hook of hooks) {
        if (hook && line.toLowerCase().includes(hook.toLowerCase())) return true;
      }
    }

    return false;
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (/Setting up mod 'Iter( Lite)?'\s*$/.test(line)) {
      setup.push({ line: i + 1, text: line.trim() });
      setupSeen = true;
    }

    if (/\[ITER-TEST\]/.test(line)) harness.push({ line: i + 1, text: line.trim() });
    if (/\[ITER-TEST\]\s*ERROR/.test(line)) harnessErrors.push({ line: i + 1, text: line.trim() });

    const navEvent = parseNavEvent(line);
    if (navEvent) {
      navEvents.push(navEvent);
      navEventLines.push({ line: i + 1, event: navEvent });
    }

    const iterErr = ITER_ERR_RE.exec(line);
    if (iterErr) {
      const entry = { line: i + 1, text: line.trim() };
      iterErrors.push(entry);
      errEvents.push(entry);
    }

    if (FATAL_RE.test(line)) fatal.push({ line: i + 1, text: line.trim() });

    if (LUA_ERROR_RE.test(line)) {
      const entry = { line: i + 1, text: line.trim() };
      luaErrors.push(entry);
      if (setupSeen && ERROR_MARKER_RE.test(line) && hasIterFrame(i)) {
        iterErrors.push(entry);
      }
    }
  }

  return {
    file,
    setup,
    harness,
    harnessErrors,
    fatal,
    luaErrors,
    iterErrors,
    navEvents,
    navEventLines,
    errEvents,
    ok: setup.length > 0 && fatal.length === 0 && iterErrors.length === 0 && harnessErrors.length === 0
  };
}

export function isOk(result, { strict = false } = {}) {
  if (!result.ok) return false;
  if (strict && result.luaErrors.length > 0) return false;
  return true;
}

function compareExpectation(actual, expected) {
  if (typeof expected === 'number') return actual === expected;
  if (typeof expected === 'boolean') return actual === expected;
  if (typeof expected !== 'string') return actual === expected;

  if (expected === 'true') return actual === true;
  if (expected === 'false') return actual === false;

  const match = /^(>=|<=|>|<|=)?\s*(-?\d+(?:\.\d+)?)$/.exec(expected.trim());
  if (!match) return String(actual) === expected;

  const value = Number(match[2]);
  const op = match[1] || '=';

  if (typeof actual !== 'number') return false;
  if (op === '>') return actual > value;
  if (op === '>=') return actual >= value;
  if (op === '<') return actual < value;
  if (op === '<=') return actual <= value;
  return actual === value;
}

export function evaluateCard(result, card) {
  const byType = aggregateNavEvents(result.navEvents);
  const checks = [];

  const add = (name, actual, expected) => {
    checks.push({
      name,
      actual,
      expected,
      pass: compareExpectation(actual, expected)
    });
  };

  for (const [name, expected] of Object.entries(card.expect || {})) {
    const [head, field] = name.split('.');

    if (head === 'setup') {
      add(name, result.setup.length > 0, expected);
    } else if (head === 'iterErrors') {
      add(name, result.iterErrors.length, expected);
    } else if (head === 'harnessErrors') {
      add(name, result.harnessErrors.length, expected);
    } else if (head === 'fatal') {
      add(name, result.fatal.length, expected);
    } else if (head === 'luaErrors') {
      add(name, result.luaErrors.length, expected);
    } else if (head === 'fallback') {
      add(name, (byType.fallback || []).length, expected);
    } else if (head === 'err') {
      add(name, (byType.err || []).length, expected);
    } else if (field) {
      add(name, sumField(byType[head] || [], field), expected);
    } else {
      add(name, (byType[head] || []).length, expected);
    }
  }

  return {
    pass: checks.every(check => check.pass),
    checks
  };
}

export function renderReport(result, cardResult) {
  const lines = [];
  const byType = aggregateNavEvents(result.navEvents);
  const eventCounts = Object.entries(byType)
    .map(([type, events]) => `${type}=${events.length}`)
    .sort()
    .join(' ');

  lines.push('# Iter log scan');
  lines.push('');
  lines.push(`File: \`${result.file || '(stdin)'}\``);
  lines.push('');
  lines.push(`- setup: ${result.setup.length}`);
  lines.push(`- FATAL: ${result.fatal.length}`);
  lines.push(`- Lua errors: ${result.luaErrors.length}`);
  lines.push(`- Iter errors: ${result.iterErrors.length}`);
  lines.push(`- harness: ${result.harness.length}`);
  lines.push(`- harness errors: ${result.harnessErrors.length}`);
  lines.push(`- nav events: ${result.navEvents.length}${eventCounts ? ' (' + eventCounts + ')' : ''}`);
  lines.push(`- result: ${result.ok ? 'OK' : 'FAIL'}`);
  lines.push('');

  if (cardResult) {
    lines.push('## Card');
    lines.push('');
    lines.push(`Result: ${cardResult.pass ? 'PASS' : 'FAIL'}`);
    lines.push('');
    lines.push('| check | actual | expected | result |');
    lines.push('|---|---:|---:|---|');
    for (const check of cardResult.checks) {
      lines.push(`| ${check.name} | ${check.actual} | ${check.expected} | ${check.pass ? 'PASS' : 'FAIL'} |`);
    }
    lines.push('');
  }

  lines.push('## Iter setup');
  lines.push('');
  if (!result.setup.length) {
    lines.push('Iter did not report a setup line. Check that the mod is installed and enabled.');
  } else {
    for (const entry of result.setup) lines.push(`- ${entry.line}: \`${entry.text}\``);
  }
  lines.push('');

  lines.push('## FATAL');
  lines.push('');
  if (!result.fatal.length) lines.push('None.');
  else for (const entry of result.fatal) lines.push(`- ${entry.line}: \`${entry.text}\``);
  lines.push('');

  lines.push('## Iter errors');
  lines.push('');
  if (!result.iterErrors.length) lines.push('None.');
  else for (const entry of result.iterErrors) lines.push(`- ${entry.line}: \`${entry.text}\``);
  lines.push('');

  lines.push('## Other Lua errors');
  lines.push('');
  const other = result.luaErrors.filter(entry => !result.iterErrors.includes(entry));
  if (!other.length) lines.push('None.');
  else for (const entry of other) lines.push(`- ${entry.line}: \`${entry.text}\``);
  lines.push('');

  lines.push('## Harness output');
  lines.push('');
  if (!result.harness.length) lines.push('None.');
  else for (const entry of result.harness) lines.push(`- ${entry.line}: \`${entry.text}\``);
  lines.push('');

  lines.push('## Harness errors');
  lines.push('');
  if (!result.harnessErrors.length) lines.push('None.');
  else for (const entry of result.harnessErrors) lines.push(`- ${entry.line}: \`${entry.text}\``);
  lines.push('');

  return lines.join('\n') + '\n';
}

function readModTxt(modDir) {
  const file = path.join(modDir, 'mod.txt');
  if (!fs.existsSync(file)) return null;
  const raw = fs.readFileSync(file, 'utf8');
  try {
    return JSON.parse(raw);
  } catch {
    return JSON.parse(raw.replace(/,\s*([}\]])/g, '$1'));
  }
}

function parseArgs(argv) {
  const args = {
    log: '',
    mod: process.cwd(),
    out: '',
    json: '',
    strict: false,
    hooks: '',
    card: ''
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--mod') args.mod = argv[++i];
    else if (arg === '--out') args.out = argv[++i];
    else if (arg === '--json') args.json = argv[++i];
    else if (arg === '--strict') args.strict = true;
    else if (arg === '--hooks') args.hooks = argv[++i];
    else if (arg === '--card') args.card = argv[++i];
    else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node dev/tools/log-scan.mjs <logfile> [--mod DIR] [--hooks a,b] [--card FILE] [--out FILE] [--json FILE] [--strict]');
      process.exit(0);
    } else if (!args.log) args.log = arg;
    else throw new Error(`Unknown argument: ${arg}`);
  }

  return args;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.log) throw new Error('log file is required');

  let hookFiles = args.hooks ? args.hooks.split(',').map(item => item.trim()).filter(Boolean) : [];
  if (!hookFiles.length) {
    const modTxt = readModTxt(path.resolve(args.mod));
    if (modTxt && Array.isArray(modTxt.hooks)) hookFiles = modTxt.hooks.map(hook => hook.hook_id);
  }

  const result = scanLog(fs.readFileSync(path.resolve(args.log), 'utf8'), {
    file: path.resolve(args.log),
    hookFiles
  });

  let cardResult = null;
  if (args.card) {
    const card = JSON.parse(fs.readFileSync(path.resolve(args.card), 'utf8'));
    cardResult = evaluateCard(result, card);
  }

  const markdown = renderReport(result, cardResult);

  if (args.out) {
    const out = path.resolve(args.out);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, markdown);
  }

  if (args.json) {
    const out = path.resolve(args.json);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, JSON.stringify({ ...result, card: cardResult }, null, 2));
  }

  if (!args.out && !args.json) process.stdout.write(markdown);

  console.log(`setup=${result.setup.length} fatal=${result.fatal.length} luaErrors=${result.luaErrors.length} iterErrors=${result.iterErrors.length} harness=${result.harness.length} navEvents=${result.navEvents.length} ok=${isOk(result, { strict: args.strict })}${cardResult ? ` card=${cardResult.pass ? 'PASS' : 'FAIL'}` : ''}`);

  if (!isOk(result, { strict: args.strict }) || (cardResult && !cardResult.pass)) process.exitCode = 1;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main();
}
