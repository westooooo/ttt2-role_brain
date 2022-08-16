if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_brain.vmt")
end

roles.InitCustomTeam(ROLE.name, {
	icon = "vgui/ttt/dynamic/roles/icon_brain",
	color = Color(124, 33, 57, 255)
})

function ROLE:PreInitialize()
	self.color = Color(124, 33, 57, 255)

	self.abbr = "brain"
    self.surviveBonus = 0.5 -- bonus multiplier for every survive while another player was killed
    self.scoreKillsMultiplier = 5 -- multiplier for kill of player of another team
    self.scoreTeamKillsMultiplier = -16 -- multiplier for teamkill
    self.preventFindCredits = false
    self.preventKillCredits = false
    self.preventTraitorAloneCredits = false

    self.defaultEquipment = SPECIAL_EQUIPMENT -- here you can set up your own default equipment
    self.defaultTeam = TEAM_TRAITOR

    self.conVarData = {
    pct = 0.17, -- necessary: percentage of getting this role selected (per player)
    maximum = 1, -- maximum amount of roles in a round
    minPlayers = 7, -- minimum amount of players until this role is able to get selected
    credits = 1, -- the starting credits of a specific role
    togglable = true, -- option to toggle a role for a client if possible (F1 menu)
    random = 33,
    traitorButton = 1, -- can use traitor buttons
    shopFallback = SHOP_FALLBACK_TRAITOR
  }
end

-- now link this subrole with its baserole
function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_TRAITOR)
end

if SERVER then
	-- Give Loadout on respawn and rolechange
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		if isRoleChange and WEPS.IsInstalled("weapon_ttt2_slavedeagle")
			and GetConVar("ttt_brain_spawn_slave_deagle"):GetBool() then -- TODO: maybe give slavedeagle on respawn if not used before
			ply:GiveEquipmentWeapon("weapon_ttt2_slavedeagle")
		end
	end

	-- Remove Loadout on death and rolechange
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		if WEPS.IsInstalled("weapon_ttt2_slavedeagle") then
			ply:StripWeapon("weapon_ttt2_slavedeagle")
		end
	end
end
