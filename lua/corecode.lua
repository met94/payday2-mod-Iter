local key = ModPath .. '	pre_' .. RequiredScript
if _G[key] then return else _G[key] = true end

_G.Iter = _G.Iter or {}
Iter._path = ModPath
Iter._data_path = SavePath .. 'iter.txt'
Iter.settings = {
	-- r200 nav port to nav v6. All subsystem cards have passed; release
	-- defaults match original Iter (path extender, map patches and the idle
	-- cosmetic on). `streamline_path` is a legacy unused key; the live flag is
	-- `nav_streamline`. See dev/plans/full-nav-port.md.
	nav_overlay = true,
	nav_streamline = true,
	nav_search = true,
	nav_ai = true,
	navlink_queue = true,
	path_extender = true,
	direct_to_pos = true,
	map_patches = true,
	cop_idle_fix = true,
	debug_log = 1,
	rebuild_navlinks = true,
	map_change_alex_1 = true,
	map_change_alex_2 = true,
	map_change_arena = true,
	map_change_arm_fac = true,
	map_change_arm_for = true,
	map_change_big = true,
	map_change_born = true,
	map_change_branchbank = true,
	map_change_brb = true,
	map_change_cage = true,
	map_change_cane = true,
	map_change_chas = true,
	map_change_chew = true,
	map_change_chill_combat = true,
	map_change_crojob2 = true,
	map_change_dah = true,
	map_change_dinner = true,
	map_change_escape_garage = true,
	map_change_escape_park = true,
	map_change_escape_street = true,
	map_change_family = true,
	map_change_fex = true,
	map_change_firestarter_1 = true,
	map_change_firestarter_3 = true,
	map_change_flat = true,
	map_change_framing_frame_1 = true,
	map_change_friend = true,
	map_change_gallery = true,
	map_change_glace = true,
	map_change_hox_1 = true,
	map_change_hox_2 = true,
	map_change_jewelry_store = true,
	map_change_jolly = true,
	map_change_kenaz = true,
	map_change_kosugi = true,
	map_change_mad = true,
	map_change_mex = true,
	map_change_mia_1 = true,
	map_change_moon = true,
	map_change_mus = true,
	map_change_pbr = true,
	map_change_pbr2 = true,
	map_change_peta = true,
	map_change_pex = true,
	map_change_pines = true,
	map_change_rat = true,
	map_change_red2 = true,
	map_change_roberts = true,
	map_change_rvd1 = true,
	map_change_skm_big2 = true,
	map_change_skm_mallcrasher = true,
	map_change_vit = true,
	map_change_watchdogs_1 = true,
	map_change_welcome_to_the_jungle_2 = true,
	map_change_wwh = true
}

function Iter:load()
	local file = io.open(self._data_path, 'r')
	if file then
		local data = json.decode(file:read('*all')) or {}
		for k, v in pairs(data) do
			self.settings[k] = v
		end

		-- Original Iter had only `streamline_path` as the master toggle. If
		-- the saved file predates the port (no `nav_overlay` key) and the
		-- player had turned pathing off, keep it off.
		if data.nav_overlay == nil and data.streamline_path == false then
			self.settings.nav_overlay = false
		end

		self.settings.streamline_path = nil
		file:close()
	end
end

function Iter:save()
	local file = io.open(self._data_path, 'w+')
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

function Iter:get_level_id()
	local level_id = Global.game_settings and Global.game_settings.level_id or ''
	level_id = level_id:gsub('_night$', ''):gsub('_day$', '')
	return level_id
end

Iter:load()

dofile(Iter._path .. 'lua/iter_diag.lua')

Iter.diag.event('boot', {
	diag_version = Iter.diag.version,
	nav_overlay = tostring(Iter.settings.nav_overlay),
	nav_streamline = tostring(Iter.settings.nav_streamline),
	nav_search = tostring(Iter.settings.nav_search),
	navlink_queue = tostring(Iter.settings.navlink_queue),
	path_extender = tostring(Iter.settings.path_extender),
	direct_to_pos = tostring(Iter.settings.direct_to_pos),
	nav_ai = tostring(Iter.settings.nav_ai),
	debug_log = Iter.settings.debug_log
})
