// Nav-link / door alive() guard (Car Shop crash).
//
// Crash (release blocker, Car Shop `cane`, heavy assault, 276 nav-link
// elements):
//
//   [string "core/lib/utils/corecode.lua"]:100: attempt to call method 'alive' (a nil value)
//   itr_find_best_navlink() @ lua/navigationmanager.lua:961
//   itr_get_alternate_navlink() @ lua/copactionwalk.lua:179
//   itr_switch_to_sibling_navlink() @ lua/copactionwalk.lua:226
//
// The game's `alive(obj)` is `if obj and obj:alive() then ... end`
// (core/lib/utils/corecode.lua:86-92). Door and nav-link userdata is not a
// unit and may not implement `alive()`, so calling the game helper on it raises
// instead of returning false. Iter therefore routes every door/nav-link check
// through its own `itr_alive` / `itr_alive_navpoint` helpers, which only call
// `alive()` when the userdata actually has that method. `alive(user)` on real
// units keeps working (units always implement it), so those calls stay.
//
// Static checks only: Node cannot execute Lua, and the engine userdata types
// only exist in-game. The runtime regression test is the in-game Car Shop card
// of the AI-suite compatibility suite: play Car Shop loud for 10+ minutes
// through a heavy assault and confirm no crash in `mods/logs/*.txt` and no
// `crash.txt`.

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const read = (...parts) => fs.readFileSync(path.join(repoRoot, ...parts), 'utf8');

// Strip line comments and long comments so a commented-out helper or call site
// cannot satisfy a check. Short-string handling mirrors compat.test.mjs.
function stripLuaComments(source) {
  let out = '';
  let i = 0;
  while (i < source.length) {
    const c = source[i];

    if (c === '"' || c === "'") {
      const quote = c;
      out += c;
      i++;
      while (i < source.length) {
        const ch = source[i];
        out += ch;
        i++;
        if (ch === '\\') {
          if (i < source.length) out += source[i];
          i++;
          continue;
        }
        if (ch === quote) break;
      }
      continue;
    }

    if (c === '-' && source[i + 1] === '-') {
      const long = /^--(\[(=*)\[)/.exec(source.slice(i));
      if (long) {
        const close = ']' + long[2] + ']';
        const end = source.indexOf(close, i + long[0].length);
        i = end === -1 ? source.length : end + close.length;
      } else {
        const nl = source.indexOf('\n', i + 2);
        i = nl === -1 ? source.length : nl;
      }
      out += '\n';
      continue;
    }

    const longString = c === '[' && /^\[(=*)\[/.exec(source.slice(i));
    if (longString) {
      const close = ']' + longString[1] + ']';
      const end = source.indexOf(close, i + longString[0].length);
      i = end === -1 ? source.length : end + close.length;
      out += '\n';
      continue;
    }

    out += c;
    i++;
  }
  return out;
}

function countMatches(code, pattern) {
  return (code.match(pattern) || []).length;
}

const navCode = stripLuaComments(read('lua', 'navigationmanager.lua'));
const walkCode = stripLuaComments(read('lua', 'copactionwalk.lua'));

test('navigationmanager defines itr_alive and does not call alive() on doors/nav-links', () => {
  assert.match(
    navCode,
    /local function itr_alive\(obj\)/,
    'itr_alive helper missing from navigationmanager.lua'
  );

  // The helper must only call alive() when the userdata exposes the method.
  assert.match(navCode, /local alive_method = obj\.alive/);
  assert.match(navCode, /if type\(alive_method\) ~= 'function' then\s*\n\s*return true/);

  // Vector3 userdata is neither a door nor a unit: is_vec3() keeps the
  // 248.2 access-violation guard meaningful.
  assert.match(navCode, /if type\(obj\) ~= 'userdata' or is_vec3\(obj\) then/);

  // Five door/nav-link call sites, previously `alive(...)`.
  const sites = [
    /elseif itr_alive\(i_door\) then/,
    /elseif itr_alive\(door_id\) then/,
    /type\(navlink\) == 'userdata' and itr_alive\(navlink\)/
  ];
  for (const site of sites) {
    assert.ok(countMatches(navCode, site) >= 1, `missing guarded call site: ${site}`);
  }
  // Two `itr_alive(i_door) and not i_door:is_obstructed()` sites.
  assert.equal(
    countMatches(navCode, /itr_alive\(i_door\) and not i_door:is_obstructed\(\)/g),
    2,
    'both i_door obstruction checks must be guarded'
  );

  // No unguarded door/nav-link alive() call remains (lookbehind keeps
  // itr_alive() from counting as a match).
  assert.doesNotMatch(navCode, /(?<!itr_)alive\(i_door\)/);
  assert.doesNotMatch(navCode, /(?<!itr_)alive\(door_id\)/);
  assert.doesNotMatch(navCode, /and alive\(navlink\)/);
});

test('navigationmanager keeps alive() for units', () => {
  assert.equal(
    countMatches(navCode, /alive\(element\.itr_reserved_by_unit\)/g),
    2,
    'reservation checks are on units and must stay on the game helper'
  );
  assert.equal(
    countMatches(navCode, /(?<![\w.])alive\(user\)/g),
    3,
    'user is a unit; its alive() calls must stay on the game helper'
  );
});

test('copactionwalk defines itr_alive_navpoint and guards nav points and nav links', () => {
  assert.match(
    walkCode,
    /local function itr_alive_navpoint\(obj\)/,
    'itr_alive_navpoint helper missing from copactionwalk.lua'
  );
  assert.match(walkCode, /local alive_method = obj\.alive/);
  assert.match(walkCode, /if type\(alive_method\) ~= 'function' then\s*\n\s*return true/);

  assert.match(walkCode, /elseif itr_alive_navpoint\(nav_point\) then/);
  assert.equal(
    countMatches(walkCode, /if itr_alive_navpoint\(navlink\) then/g),
    2,
    'both nav-link delay call sites must be guarded'
  );

  assert.doesNotMatch(walkCode, /alive\(nav_point\)/);
  assert.doesNotMatch(walkCode, /alive\(navlink\)/);
});

test('copactionwalk keeps alive(user) in itr_reserve_navlink', () => {
  const start = walkCode.indexOf('function CopActionWalk:itr_reserve_navlink(');
  assert.ok(start >= 0, 'itr_reserve_navlink missing');
  const end = walkCode.indexOf('\n\tend', start);
  assert.ok(end > start, 'itr_reserve_navlink body is not terminated');
  const body = walkCode.slice(start, end);
  assert.match(body, /if not alive\(user\) or user:id\(\) == -1 then/);
});

test('helper truth table: non-userdata is absent, missing alive() means present', () => {
  // JS mirror of itr_alive's decision order (Lua `type(obj) ~= 'userdata'`
  // then the missing-method early return). This documents the intended
  // behaviour; the authoritative proof is the in-game Car Shop card.
  class Userdata {}

  const itrAlive = (obj, isVec3 = () => false) => {
    if (obj === null || obj === undefined) return false;
    if (!(obj instanceof Userdata) || isVec3(obj)) return false;
    const aliveMethod = obj.alive;
    if (typeof aliveMethod !== 'function') return true;
    return Boolean(aliveMethod(obj));
  };

  const door = new Userdata(); // Car Shop door: no alive() method
  assert.equal(itrAlive(null), false, 'nil is not alive');
  assert.equal(itrAlive('door'), false, 'a non-userdata value is not alive');
  assert.equal(itrAlive(door), true, 'userdata without alive() counts as existing');
  assert.equal(itrAlive(new Userdata(), () => true), false, 'Vector3 userdata is rejected');

  const liveUnit = new Userdata();
  liveUnit.alive = () => true;
  assert.equal(itrAlive(liveUnit), true, 'userdata with alive() delegates to it');

  const deadUnit = new Userdata();
  deadUnit.alive = () => false;
  assert.equal(itrAlive(deadUnit), false, 'userdata reporting not alive stays not alive');
});
