-- replicated convars have to be created on both client and server
CreateConVar("ttt_brain_spawn_slave_deagle", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})

hook.Add("TTTUlxDynamicRCVars", "ttt2_ulx_dynamic_brain_convars", function(tbl)
	tbl[ROLE_BRAINWASHER] = tbl[ROLE_BRAINWASHER] or {}

	table.insert(tbl[ROLE_BRAINWASHER], {
		cvar = "ttt_brain_spawn_slave_deagle", 
		checkbox = true, 
		desc = "ttt_brain_spawn_slave_deagle (def. 1)"
	})
end)
