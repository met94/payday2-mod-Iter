local key = ModPath .. '\t' .. RequiredScript
if _G[key] then return else _G[key] = true end

-- Final watch digest when the player leaves a heist for the menu.
--
-- PD2 does not call `NavigationManager:_clear` when a heist is quit to the main
-- menu, so the teardown hook never fires for aborted heists (2026-10-26/27: all
-- sessions were quit, never finished, and `evt=final` never appeared despite
-- 200.10). MenuManager keeps updating in the menu, so the final is emitted from
-- its `open`, which also runs on pause/options - hence `itr_watch_final` is
-- idempotent per level and no-ops when there is no frame window yet.
Hooks:PostHook(MenuManager, 'open', 'Iter_watch_menu_final', function(self, menu_id)
	if managers and managers.navigation and managers.navigation.itr_watch_final then
		managers.navigation:itr_watch_final()
	end
end)
