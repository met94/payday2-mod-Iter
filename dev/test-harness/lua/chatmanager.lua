-- Iter full-nav port test harness. Dev-only; not shipped.
-- Chat commands: !iter help | nav | patch | navdump | navdoors | navpath | p7 | probe [n] | path | ai | links | alarm | assault | state | setting <key> <value> | dump | reset

Iter_TestHarness = Iter_TestHarness or {}
local TH = Iter_TestHarness
local PREFIX = '[ITER-TEST] '
local quiet_log = false

local function say(message)
	message = tostring(message)
	log(PREFIX .. message)

	if quiet_log then
		return
	end

	if managers and managers.chat and ChatManager then
		pcall(function()
			managers.chat:_receive_message(ChatManager.GAME, 'ITER-TEST', message, tweak_data and tweak_data.system_chat_color)
		end)
	end
end

local function nav_manager()
	return managers and managers.navigation
end

local function iter_settings()
	return Iter and Iter.settings or {}
end

function TH.parse_command(message)
	if type(message) ~= 'string' then
		return nil
	end

	local body = message:match('^%s*!iter%s*(.*)$')
	if not body then
		return nil
	end

	body = body:gsub('%s+$', '')
	if body == '' then
		return { command = 'help', args = {} }
	end

	local args = {}
	for word in body:gmatch('%S+') do
		args[#args + 1] = word
	end

	local command = table.remove(args, 1)
	return { command = command, args = args }
end

local function door_kind(door)
	if type(door) == 'number' then
		return 'numeric'
	elseif type(door) == 'table' and door.x then
		return 'vector'
	elseif type(door) == 'userdata' then
		local ok, x = pcall(function()
			return door.x
		end)

		if ok and x then
			return 'vector'
		end

		return 'navlink'
	end

	return 'unknown'
end

function TH.nav_stats()
	local nav = nav_manager()
	local segments = nav and nav._nav_segments or {}
	local stats = {
		segments = 0,
		string_keys = 0,
		numeric_keys = 0,
		missing_neighbours = 0,
		numeric_doors = 0,
		vector_doors = 0,
		nav_links = 0,
		unknown_doors = 0,
		rooms = 0,
		room_doors = 0,
		vis_groups = 0,
		proxy_segments = 0,
		choke_points = 0,
		in_proxies = 0,
		out_proxies = 0,
		navlink_elements = 0,
		covers = 0,
		bad_covers = 0
	}

	for key, segment in pairs(segments) do
		stats.segments = stats.segments + 1

		if type(key) == 'string' then
			stats.string_keys = stats.string_keys + 1
		else
			stats.numeric_keys = stats.numeric_keys + 1
		end

		local neighbours = segment.neighbours or {}

		for neighbour_id, doors in pairs(neighbours) do
			if not segments[neighbour_id] then
				stats.missing_neighbours = stats.missing_neighbours + 1
			end

			if type(doors) == 'table' then
				for _, door in ipairs(doors) do
					local kind = door_kind(door)

					if kind == 'numeric' then
						stats.numeric_doors = stats.numeric_doors + 1
					elseif kind == 'vector' then
						stats.vector_doors = stats.vector_doors + 1
					elseif kind == 'navlink' then
						stats.nav_links = stats.nav_links + 1
					else
						stats.unknown_doors = stats.unknown_doors + 1
					end
				end
			end
		end

		if segment.choke_points or segment.choke_point_proxies then
			stats.proxy_segments = stats.proxy_segments + 1
			stats.choke_points = stats.choke_points + table.size(segment.choke_points or {})
			stats.in_proxies = stats.in_proxies + table.size(segment.in_proxies or {})
			stats.out_proxies = stats.out_proxies + table.size(segment.out_proxies or {})
		end
	end

	stats.rooms = table.size(nav and nav._rooms or {})
	stats.room_doors = table.size(nav and nav._room_doors or {})
	stats.vis_groups = table.size(nav and nav._visibility_groups or {})
	stats.navlink_elements = table.size(nav and (nav.itr_navlink_elements or nav._navlink_elements) or {})

	local covers = nav and nav._covers or {}
	stats.covers = #covers

	for _, cover in ipairs(covers) do
		if type(cover) ~= 'table' or not cover[1] or not cover[2] then
			stats.bad_covers = stats.bad_covers + 1
		end
	end

	return stats
end

function TH.dump_doors(args)
	local nav = nav_manager()
	local seg_a = args[1] and tostring(args[1])
	local seg_b = args[2] and tostring(args[2])

	if not nav or not seg_a or not seg_b then
		say('navdoors: usage !iter navdoors <seg_a> <seg_b>')
		return
	end

	local function seg_of_quad(quad_id)
		local room = nav._rooms and nav._rooms[quad_id]
		local vis_group_id = room and room.vis_group
		local group = vis_group_id and nav._visibility_groups and nav._visibility_groups[vis_group_id]

		return group and group.seg
	end

	local shown = 0

	for door_id, door in pairs(nav._room_doors or {}) do
		local a = seg_of_quad(door.rooms[1])
		local b = seg_of_quad(door.rooms[2])

		if (a == seg_a and b == seg_b) or (a == seg_b and b == seg_a) then
			shown = shown + 1
			say(string.format(
				'navdoors %s<->%s id=%s quads=%s,%s pos=%s pos1=%s center=%s',
				seg_a,
				seg_b,
				tostring(door_id),
				tostring(door.rooms[1]),
				tostring(door.rooms[2]),
				tostring(door.pos),
				tostring(door.pos1),
				tostring(door.center)
			))
		end
	end

	say(string.format('navdoors %s<->%s total=%d', seg_a, seg_b, shown))
end

function TH.dump_nav()
	local stats = TH.nav_stats()
	say(string.format(
		'nav segments=%d keys(string=%d numeric=%d) missing_neighbours=%d doors(vector=%d numeric=%d links=%d unknown=%d) shim(rooms=%d room_doors=%d vis_groups=%d) proxies(segments=%d choke=%d in=%d out=%d) navlink_elements=%d covers=%d bad_covers=%d',
		stats.segments,
		stats.string_keys,
		stats.numeric_keys,
		stats.missing_neighbours,
		stats.vector_doors,
		stats.numeric_doors,
		stats.nav_links,
		stats.unknown_doors,
		stats.rooms,
		stats.room_doors,
		stats.vis_groups,
		stats.proxy_segments,
		stats.choke_points,
		stats.in_proxies,
		stats.out_proxies,
		stats.navlink_elements,
		stats.covers,
		stats.bad_covers
	))
end

function TH.dump_patch()
	local status = Iter and Iter.nav_patch_status

	if not status then
		say('patch: no patch status recorded yet (load a heist first)')
		return
	end

	say(string.format(
		'patch level=%s result=%s error=%s rooms=%s doors=%s segments=%s vis_groups=%s transfers=%s',
		tostring(status.level),
		tostring(status.result),
		tostring(status.error),
		tostring(status.rooms),
		tostring(status.doors),
		tostring(status.segments),
		tostring(status.vis_groups),
		tostring(status.transfers)
	))
end

function TH.dump_segment(args)
	local nav = nav_manager()
	local segment_id = args[1] and tostring(args[1])

	if not nav or not segment_id then
		say('navdump: usage !iter navdump <segment_id>')
		return
	end

	local segment = nav._nav_segments[segment_id]

	if not segment then
		say('navdump: no segment ' .. segment_id)
		return
	end

	say(string.format(
		'navdump seg=%s pos=%s vis_groups=%s neighbours=%d rooms=%d',
		segment_id,
		tostring(segment.pos),
		table.concat(segment.vis_groups or {}, ','),
		table.size(segment.neighbours or {}),
		table.size(nav._rooms or {})
	))

	for neighbour_id, doors in pairs(segment.neighbours or {}) do
		local counts = { vector = 0, navlink = 0, numeric = 0, other = 0 }

		for _, door in ipairs(doors or {}) do
			local kind = door_kind(door)
			counts[kind] = (counts[kind] or 0) + 1
		end

		say(string.format(
			'navdump seg=%s -> %s doors=%d vector=%d navlink=%d numeric=%d other=%d',
			segment_id,
			tostring(neighbour_id),
			#(doors or {}),
			counts.vector,
			counts.navlink,
			counts.numeric,
			counts.other
		))
	end

	for _, vis_group_id in ipairs(segment.vis_groups or {}) do
		local group = nav._visibility_groups and nav._visibility_groups[vis_group_id]

		if group then
			local quads = {}

			for quad_id in pairs(group.rooms or {}) do
				quads[#quads + 1] = tostring(quad_id)
			end

			say(string.format(
				'navdump seg=%s vg=%s quads=%s',
				segment_id,
				tostring(vis_group_id),
				table.concat(quads, ',')
			))
		end
	end
end

local function connected_segment_pool(segments)
	local roots = {}

	for key, segment in pairs(segments) do
		if not segment.disabled and next(segment.neighbours or {}) then
			roots[#roots + 1] = key
		end
	end

	if #roots < 2 then
		return {}
	end

	local start = roots[math.random(#roots)]
	local seen = { [start] = true }
	local queue = { start }
	local pool = { start }
	local head = 1

	while head <= #queue do
		local current = queue[head]
		head = head + 1

		for neighbour_id in pairs(segments[current].neighbours or {}) do
			local neighbour = segments[neighbour_id]

			if neighbour and not neighbour.disabled and not seen[neighbour_id] then
				seen[neighbour_id] = true
				queue[#queue + 1] = neighbour_id
				pool[#pool + 1] = neighbour_id
			end
		end
	end

	return pool
end

local function random_segment_pairs(count)
	local nav = nav_manager()
	local segments = nav and nav._nav_segments or {}
	local usable = connected_segment_pool(segments)

	if #usable < 2 then
		return {}
	end

	local pairs_out = {}
	local rng = math.random

	for _ = 1, count do
		local from = usable[rng(#usable)]
		local to = usable[rng(#usable)]

		if from ~= to then
			pairs_out[#pairs_out + 1] = { from, to }
		end
	end

	return pairs_out
end

local function path_length(path)
	local total = 0
	local prev

	for _, step in ipairs(path or {}) do
		local pos = step[2]

		if pos and pos.x then
			if prev then
				total = total + mvector3.distance(prev, pos)
			end

			prev = pos
		end
	end

	return total
end

local function path_positions(path)
	local count = 0

	for _, step in ipairs(path or {}) do
		if step[2] and step[2].x then
			count = count + 1
		end
	end

	return count
end

function TH.probe(args)
	local nav = nav_manager()

	if not nav then
		say('probe: no navigation manager')
		return
	end

	local count = tonumber(args[1]) or 10
	count = math.max(1, math.min(count, 100))

	local pairs_to_test = random_segment_pairs(count)

	if #pairs_to_test == 0 then
		say('probe: not enough connected segments')
		return
	end

	local ok_search = 0
	local ok_stream = 0
	local fail_search = 0
	local fail_stream = 0
	local raw_points = 0
	local stream_points = 0
	local raw_len = 0
	local stream_len = 0
	local raw_positions = 0
	local stream_positions = 0
	local first_fail_from, first_fail_to

	for _, pair in ipairs(pairs_to_test) do
		local from_seg, to_seg = pair[1], pair[2]
		local search_ok, path = pcall(function()
			return nav:search_coarse({ from_seg = from_seg, to_seg = to_seg })
		end)

		if not search_ok or not path then
			fail_search = fail_search + 1

			if not first_fail_from then
				first_fail_from = from_seg
				first_fail_to = to_seg
			end
		else
			ok_search = ok_search + 1
			raw_points = raw_points + #path
			raw_len = raw_len + path_length(path)
			raw_positions = raw_positions + path_positions(path)

			if nav.itr_streamline then
				local stream_ok, streamlined = pcall(function()
					return nav:itr_streamline(path, nil)
				end)

				if stream_ok and streamlined then
					ok_stream = ok_stream + 1
					stream_points = stream_points + #streamlined
					stream_len = stream_len + path_length(streamlined)
					stream_positions = stream_positions + path_positions(streamlined)
				else
					fail_stream = fail_stream + 1
					say(string.format('probe: streamline failed %s->%s err=%s', tostring(from_seg), tostring(to_seg), tostring(streamlined)))
				end
			end
		end
	end

	local avg_raw = ok_search > 0 and raw_len / ok_search or 0
	local avg_stream = ok_stream > 0 and stream_len / ok_stream or 0

	say(string.format(
		'probe pairs=%d search(ok=%d fail=%d) streamline(ok=%d fail=%d) points(raw=%d stream=%d) avg_len(raw=%.1f stream=%.1f)',
		#pairs_to_test,
		ok_search,
		fail_search,
		ok_stream,
		fail_stream,
		raw_points,
		stream_points,
		avg_raw,
		avg_stream
	))

	if Iter and Iter.diag then
		Iter.diag.event('probe', {
			pairs = #pairs_to_test,
			search_ok = ok_search,
			search_fail = fail_search,
			stream_ok = ok_stream,
			stream_fail = fail_stream,
			raw_points = raw_points,
			stream_points = stream_points,
			raw_positions = raw_positions,
			stream_positions = stream_positions,
			fail_from = first_fail_from or 'none',
			fail_to = first_fail_to or 'none'
		})
	end
end

-- P7 topology A/B: coarse search between two known segment ids.
-- Run once with "Dev: v6 map patches" on and once off; the line records the
-- live setting, level and the direct door count so the two runs compare.
function TH.navpath(args)
	local nav = nav_manager()
	local from_seg = args[1] and tostring(args[1])
	local to_seg = args[2] and tostring(args[2])

	if not nav or not from_seg or not to_seg then
		say('navpath: usage !iter navpath <from_seg> <to_seg>')
		return
	end

	local segments = nav._nav_segments or {}

	if not segments[from_seg] then
		say('navpath: no segment ' .. from_seg)
		return
	end

	if not segments[to_seg] then
		say('navpath: no segment ' .. to_seg)
		return
	end

	local level_id = 'unknown'

	if Iter and Iter.get_level_id then
		local id_ok, id = pcall(Iter.get_level_id, Iter)

		if id_ok and id then
			level_id = tostring(id)
		end
	end

	local patches = Iter and Iter.settings and Iter.settings.map_patches and 'on' or 'off'
	local direct = 0

	for neighbour_id, doors in pairs(segments[from_seg].neighbours or {}) do
		if tostring(neighbour_id) == to_seg then
			direct = type(doors) == 'table' and #doors or 0
		end
	end

	local ok, path = pcall(function()
		return nav:search_coarse({ from_seg = from_seg, to_seg = to_seg })
	end)

	if not ok then
		say(string.format(
			'navpath level=%s patches=%s %s->%s ok=0 err=%s direct=%d',
			level_id,
			patches,
			from_seg,
			to_seg,
			tostring(path),
			direct
		))
		return
	end

	if not path then
		say(string.format(
			'navpath level=%s patches=%s %s->%s ok=0 fail=search direct=%d',
			level_id,
			patches,
			from_seg,
			to_seg,
			direct
		))
		return
	end

	local ids = {}

	for i, step in ipairs(path) do
		if i > 32 then
			ids[#ids + 1] = '...'
			break
		end

		ids[#ids + 1] = tostring(step[1] or '?')
	end

	local length = path_length(path)
	local positions = path_positions(path)

	say(string.format(
		'navpath level=%s patches=%s %s->%s ok=1 steps=%d positions=%d length=%.1f direct=%d ids=%s',
		level_id,
		patches,
		from_seg,
		to_seg,
		#path,
		positions,
		length,
		direct,
		table.concat(ids, ';')
	))

	if Iter and Iter.diag then
		Iter.diag.event('navpath', {
			level = level_id,
			patches = patches,
			from = from_seg,
			to = to_seg,
			ok = 1,
			steps = #path,
			positions = positions,
			length = string.format('%.1f', length),
			direct = direct
		})
	end
end

-- Auto P7 collection: runs once per heist start on the five pending levels.
-- Pair ids and intent come from dev/test/cards/P7-dumps.md.
local P7_PLANS = {
	escape_street = {
		dumps = { 48, 63 },
		doors = { { 48, 63 } },
		paths = { { 63, 48 } }
	},
	jolly = {
		dumps = { 87, 141 },
		doors = { { 87, 141 } },
		paths = { { 141, 87 } },
		seal = { 87, 141 }
	},
	moon = {
		dumps = { 22, 23 },
		doors = { { 22, 23 } },
		paths = { { 22, 23 } },
		seal = { 23, 22 }
	},
	peta = {
		dumps = { 47, 53, 91 },
		doors = { { 47, 91 }, { 47, 53 } },
		paths = { { 47, 91 } },
		seal = { 91, 47 }
	},
	skm_mallcrasher = {
		dumps = { 8, 11 },
		doors = { { 8, 11 } }
	},
	-- The standard Vlad job reports level_id "mallcrasher"; skm_mallcrasher is
	-- the skirmish stage id. Keep both so either load collects the dump.
	mallcrasher = {
		dumps = { 8, 11 },
		doors = { { 8, 11 } }
	}
}

TH.p7_auto_enabled = true
local p7_last_dump_t = 0

local function first_other_neighbour(seg_id, exclude_id)
	local nav = nav_manager()
	local segment = nav and nav._nav_segments and nav._nav_segments[tostring(seg_id)]

	for neighbour_id in pairs(segment and segment.neighbours or {}) do
		if tostring(neighbour_id) ~= tostring(exclude_id) then
			return tostring(neighbour_id)
		end
	end
end

function TH.p7_dump(force)
	if not force and not TH.p7_auto_enabled then
		return
	end

	local level_id = 'unknown'

	if Iter and Iter.get_level_id then
		local id_ok, id = pcall(Iter.get_level_id, Iter)

		if id_ok and id then
			level_id = tostring(id)
		end
	end

	local plan = P7_PLANS[level_id]

	if not plan then
		return
	end

	local nav = nav_manager()

	if not nav or not nav._nav_segments or not next(nav._nav_segments) then
		say(string.format('p7auto level=%s skip=nav_not_ready', level_id))
		return
	end

	local patches = Iter and Iter.settings and Iter.settings.map_patches and 'on' or 'off'

	if not force then
		if not TH.p7_auto_enabled then
			return
		end

		local now = 0

		if TimerManager and TimerManager.game then
			local t_ok, t = pcall(function()
				return TimerManager:game():time()
			end)

			if t_ok and t then
				now = t
			end
		end

		if now - p7_last_dump_t < 5 then
			return
		end

		p7_last_dump_t = now
	end

	quiet_log = not force

	local ok, err = pcall(function()
		say(string.format('p7auto level=%s patches=%s', level_id, patches))

		if patches == 'on' then
			TH.dump_patch()
		else
			say('patch status=n/a (map_patches off)')
		end

		TH.dump_nav()

		for _, seg_id in ipairs(plan.dumps) do
			TH.dump_segment({ tostring(seg_id) })
		end

		for _, pair in ipairs(plan.doors) do
			TH.dump_doors({ tostring(pair[1]), tostring(pair[2]) })
		end

		for _, pair in ipairs(plan.paths) do
			TH.navpath({ tostring(pair[1]), tostring(pair[2]) })
		end

		if plan.seal then
			local alt = first_other_neighbour(plan.seal[1], plan.seal[2])

			if alt then
				say(string.format('p7auto seal seg=%s exclude=%s alt=%s', tostring(plan.seal[1]), tostring(plan.seal[2]), alt))
				TH.navpath({ tostring(plan.seal[1]), alt })
			else
				say(string.format('p7auto seal seg=%s exclude=%s alt=none', tostring(plan.seal[1]), tostring(plan.seal[2])))
			end
		end
	end)

	quiet_log = false

	if not ok then
		say('p7auto ERROR ' .. tostring(err))
	end
end

function TH.p7_auto_toggle(args)
	local value = args[1]

	if value == 'off' or value == '0' or value == 'false' then
		TH.p7_auto_enabled = false
	elseif value == 'on' or value == '1' or value == 'true' then
		TH.p7_auto_enabled = true
	end

	say(string.format('p7auto enabled=%s (levels: escape_street, jolly, moon, peta, mallcrasher)', tostring(TH.p7_auto_enabled)))
end

-- on_simulation_started fires after nav data, shim and proxies are ready.
-- The harness loads before NavigationManager exists (mod priority 999), so the
-- class hook is registered at GameSetup, when every game file is loaded.
local function register_p7_autodump()
	if TH._p7_hook_registered then
		return
	end

	if not (NavigationManager and NavigationManager.on_simulation_started) then
		return
	end

	Hooks:PostHook(NavigationManager, 'on_simulation_started', 'Iter_P7_AutoDump', function()
		TH.p7_dump()
	end)

	TH._p7_hook_registered = true
end

register_p7_autodump()
-- Both events fire after every game script is loaded (the harness itself
-- loads before NavigationManager exists).
Hooks:Add('LocalizationManagerPostInit', 'Iter_P7_AutoDumpRegister', register_p7_autodump)
Hooks:Add('GameSetupUpdate', 'Iter_P7_AutoDumpRegister', register_p7_autodump)

if log then
	log(PREFIX .. 'harness loaded (p7auto + navpath)')
end

function TH.dump_path()
	local nav = nav_manager()
	local player = managers and managers.player and managers.player:player_unit()

	if not nav then
		say('path: no navigation manager')
		return
	end

	if not player then
		say('path: no player unit')
		return
	end

	local tracker = player:movement():nav_tracker()
	local seg = tracker and tracker:nav_segment()
	local action = player:movement()._active_actions and player:movement()._active_actions.walk
	local parts = {}

	if action and action._simplified_path then
		for i, point in ipairs(action._simplified_path) do
			local pos = point.x or (point.element and point.element:value('position'))
			local kind = point.x and 'pos' or 'navlink'

			parts[#parts + 1] = string.format('%d:%s', i, kind)

			if pos and i > 6 then
				break
			end
		end
	end

	say(string.format(
		'path player_seg=%s pos=%s action=%s points=%s next_navlink=%s',
		tostring(seg),
		tostring(player:position()),
		action and tostring(action:type()) or 'none',
		table.concat(parts, ','),
		action and action._next_is_nav_link and 'yes' or 'no'
	))
end

function TH.dump_ai()
	local enemies = managers and managers.enemy and managers.enemy:all_enemies() or {}
	local counters = Iter and Iter.diag and Iter.diag.counters or {}
	local total = 0
	local travelling = 0
	local with_coarse = 0
	local with_direct = 0
	local with_path_ahead = 0
	local waiting_navlink = 0

	for _, data in pairs(enemies) do
		total = total + 1

		local unit = data.unit
		local brain = unit and unit:brain()
		local logic_data = brain and brain._logic_data
		local my_data = logic_data and logic_data.internal_data

		if my_data then
			if my_data.coarse_path then
				with_coarse = with_coarse + 1
			end

			if my_data.itr_direct_to_pos then
				with_direct = with_direct + 1
			end

			if my_data.advancing and my_data.advancing.itr_path_ahead then
				with_path_ahead = with_path_ahead + 1
			end

			if my_data.itr_want_path_ahead then
				waiting_navlink = waiting_navlink + 1
			end

			if my_data.advancing then
				travelling = travelling + 1
			end
		end
	end

	say(string.format(
		'ai total=%d travelling=%d coarse_path=%d direct_to_pos=%d path_ahead=%d pending_path_ahead=%d extend(ok=%d skip=%d)',
		total,
		travelling,
		with_coarse,
		with_direct,
		with_path_ahead,
		waiting_navlink,
		counters.path_extend_ok or 0,
		counters.path_extend_skip or 0
	))
end

function TH.dump_links()
	local nav = nav_manager()
	local elements = nav and (nav.itr_navlink_elements or nav._navlink_elements) or {}
	local shown = 0
	local queued = 0

	for key, element in pairs(elements) do
		local values = element._values or {}
		local queue = element.itr_navlink_queue_length or 0
		local reserved = element.itr_reserved_by_unit
		local interval = values.itr_interval or values.interval or 0

		if queue > 0 then
			queued = queued + 1
		end

		if shown < 20 then
			shown = shown + 1
			say(string.format(
				'link key=%s action=%s interval=%.2f queue=%d reserved=%s',
				tostring(key),
				tostring(values.so_action),
				interval,
				queue,
				tostring(reserved and alive(reserved) and reserved:key() or 'none')
			))
		end
	end

	say(string.format('links total=%d queued=%d shown=%d', table.size(elements), queued, shown))
end

function TH.set_setting(key, value)
	if not Iter or not Iter.settings then
		say('setting: Iter not loaded')
		return
	end

	if not key then
		say('setting: usage !iter setting <key> <value>')
		return
	end

	local parsed = tonumber(value)

	if parsed == nil then
		if value == 'true' then
			parsed = true
		elseif value == 'false' then
			parsed = false
		else
			parsed = value
		end
	end

	Iter.settings[key] = parsed
	say(string.format('setting %s=%s', tostring(key), tostring(parsed)))
end

function TH.force_assault()
	local state = managers and managers.groupai and managers.groupai:state()

	if not state or not state.set_assault_mode then
		say('assault: group AI state unavailable')
		return
	end

	state:set_assault_mode(true)
	say('assault: set_assault_mode(true)')
end

function TH.force_alarm()
	local state = managers and managers.groupai and managers.groupai:state()

	if not state then
		say('alarm: group AI state unavailable')
		return
	end

	if state.on_police_called then
		state:on_police_called('civ_alarm')
	end

	if state.on_police_weapons_hot then
		state:on_police_weapons_hot('civ_alarm')
	end

	if state.set_assault_mode then
		state:set_assault_mode(true)
	end

	say('alarm: on_police_called + on_police_weapons_hot + set_assault_mode')
end

function TH.dump_state()
	local state = managers and managers.groupai and managers.groupai:state()

	if not state then
		say('state: group AI state unavailable')
		return
	end

	local groups = state._groups or {}
	local spawning = state._spawning_groups or {}
	local cops = managers.enemy and managers.enemy:all_enemies() or {}
	local assault = state._task_data and state._task_data.assault or {}

	say(string.format(
		'state=%s is_server=%s police_called=%s weapons_hot=%s assault_mode=%s assault_active=%s queued=%s(%s) groups=%d spawning=%d cops=%d',
		tostring(state),
		tostring(state._is_server),
		tostring(state.is_police_called and state:is_police_called()),
		tostring(state._enemy_weapons_hot),
		tostring(state._assault_mode),
		tostring(assault.active),
		tostring(state._police_upd_task_queued),
		type(state._police_upd_task_queued),
		table.size(groups),
		table.size(spawning),
		table.size(cops)
	))
end

function TH.dump()
	if not Iter or not Iter.settings then
		say('dump: Iter settings unavailable')
		return
	end

	say('dump: settings')

	for key, value in pairs(Iter.settings or {}) do
		log(string.format('%s  %s=%s', PREFIX, tostring(key), tostring(value)))
	end

	local nav = nav_manager()
	local stats = TH.nav_stats()

	say(string.format(
		'dump: overlay=%s streamline=%s search=%s ai=%s path=%s navlink_queue=%s extender=%s direct=%s debug_log=%s segments=%d rooms=%d room_doors=%d navlink_elements=%d',
		tostring(Iter.settings.nav_overlay),
		tostring(Iter.settings.nav_streamline),
		tostring(Iter.settings.nav_search),
		tostring(Iter.settings.nav_ai),
		tostring(Iter.settings.streamline_path),
		tostring(Iter.settings.navlink_queue),
		tostring(Iter.settings.path_extender),
		tostring(Iter.settings.direct_to_pos),
		tostring(Iter.settings.debug_log),
		stats.segments,
		stats.rooms,
		stats.room_doors,
		stats.navlink_elements
	))
end

function TH.reset()
	local nav = nav_manager()

	if nav and nav.itr_counters then
		nav.itr_counters = {}
	end

	say('reset: nav counters cleared')
end

function TH.help()
	say('commands: nav | patch | navdump <seg> | navdoors <a> <b> | navpath <from> <to> | p7 [auto on|off] | probe [n] | path | ai | links | alarm | assault | state | setting <key> <value> | dump | reset | help')
end

function TH.execute_string(message)
	local command = TH.parse_command(message)

	if not command then
		return false
	end

	TH.execute(command)

	return true
end

function TH.execute(command)
	local name = command.command
	local args = command.args

	if name == 'help' then
		TH.help()
	elseif name == 'nav' then
		TH.dump_nav()
	elseif name == 'patch' then
		TH.dump_patch()
	elseif name == 'navdump' then
		TH.dump_segment(args)
	elseif name == 'navdoors' then
		TH.dump_doors(args)
	elseif name == 'navpath' then
		TH.navpath(args)
	elseif name == 'p7' then
		if args[1] == 'auto' then
			TH.p7_auto_toggle({ args[2] })
		else
			TH.p7_dump(true)
		end
	elseif name == 'probe' then
		TH.probe(args)
	elseif name == 'path' then
		TH.dump_path()
	elseif name == 'ai' then
		TH.dump_ai()
	elseif name == 'links' then
		TH.dump_links()
	elseif name == 'alarm' then
		TH.force_alarm()
	elseif name == 'assault' then
		TH.force_assault()
	elseif name == 'state' then
		TH.dump_state()
	elseif name == 'setting' then
		TH.set_setting(args[1], args[2])
	elseif name == 'dump' then
		TH.dump()
	elseif name == 'reset' then
		TH.reset()
	else
		say('unknown command: ' .. tostring(name))
	end
end

Hooks:Add('ChatManagerOnSendMessage', 'Iter_TestHarness_Chat', function(_, _, message)
	local command = TH.parse_command(message)

	if not command then
		return
	end

	local ok, err = pcall(TH.execute, command)

	if not ok then
		say('ERROR ' .. tostring(err))
	end
end)
