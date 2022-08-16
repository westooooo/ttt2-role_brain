if SERVER then
	AddCSLuaFile()

	util.AddNetworkString("TTT2SlaveSyncClasses")

	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_slave.vmt")

	CreateConVar("ttt2_slave_protection_time", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
end

CreateConVar("ttt2_slave_mode", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "0 = Slave doesn't become an Innocent and can't win alone, but gets targets \n 1 = Slave becomes an Innocent upon their death. \n 2 = Slave doesn't become an Innocent but can win alone and gets targets", 0, 2)

local plymeta = FindMetaTable("Player")
if not plymeta then return end

ROLE.Base = "ttt_role_base"

function ROLE:PreInitialize()
	self.color = Color(0, 0, 0, 255)

	self.abbr = "slave"
	self.score.surviveBonusMultiplier = 0.5
	self.score.timelimitMultiplier = -0.5
	self.score.killsMultiplier = 2
	self.score.teamKillsMultiplier = -16
	self.score.bodyFoundMuliplier = 0

	self.preventWin = GetConVar("ttt2_slave_mode"):GetInt() ~= 2
	self.notSelectable = true
	self.disableSync = true
	self.preventFindCredits = true

	self.defaultEquipment = SPECIAL_EQUIPMENT

	self.conVarData = {
		credits = 1,
		shopFallback = SHOP_FALLBACK_TRAITOR
	}
end

cvars.AddChangeCallback( "ttt2_slave_mode", function(convar, oldValue, newValue)
	GetRoleByAbbr("slave").preventWin = newValue ~= 2
end)

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicSlaveCVars", function(tbl)
	tbl[ROLE_SLAVE] = tbl[ROLE_SLAVE] or {}

	table.insert(tbl[ROLE_SLAVE], {
		cvar = "ttt2_slave_protection_time",
		slider = true,
		min = 0,
		max = 60,
		desc = "Protection Time for new Slave (Def. 1)"
	})

	table.insert(tbl[ROLE_SLAVE], {
		cvar = "ttt2_slave_mode",
		combobox = true,
		desc = "Slave-Mode (Def. 1)",
		choices = {
		"0 = Slave doesn't become an Innocent and can't win alone, but gets targets",
		"1 = Slave becomes an Innocent upon their death.",
		"2 = Slave doesn't become an Innocent but can win alone and gets targets"
		},
		numStart = 0
	})

	table.insert(tbl[ROLE_SLAVE], {
		cvar = "ttt2_slave_deagle_refill",
		checkbox = true,
		desc = "The Slave Deagle can be refilled when you missed a shot. (Def. 1)"
	})

	table.insert(tbl[ROLE_SLAVE], {
		cvar = "ttt2_slave_deagle_refill_cd",
		slider = true,
		min = 1,
		max = 300,
		desc = "Seconds to Refill (Def. 120)"
	})

	table.insert(tbl[ROLE_SLAVE], {
		cvar = "ttt2_slave_deagle_refill_cd_per_kill",
		slider = true,
		min = 1,
		max = 300,
		desc = "CD Reduction per Kill (Def. 60)"
	})
end)

if SERVER then
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		if not GetGlobalBool("ttt2_classes") or not GetGlobalBool("ttt2_heroes") then return end
		if not TTTH then return end

		ply:GiveEquipmentWeapon("weapon_ttt_crystalknife")
	end

	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		if not GetGlobalBool("ttt2_classes") or not GetGlobalBool("ttt2_heroes") then return end
		if not TTTH then return end

		ply:StripWeapon("weapon_ttt_crystalknife")
	end
end

function GetDarkenColor(color)
	if not istable(color) then return end
	local col = table.Copy(color)
	-- darken color
	for _, v in ipairs{"r", "g", "b"} do
		col[v] = col[v] - 60
		if col[v] < 0 then
			col[v] = 0
		end
	end

	col.a = 255

	return col
end

local function tmpfnc(ply, mate, colorTable)
	if IsValid(mate) and mate:IsPlayer() then
		if colorTable == "dkcolor" then
			return table.Copy(mate:GetRoleDkColor())
		elseif colorTable == "bgcolor" then
			return table.Copy(mate:GetRoleBgColor())
		elseif colorTable == "color" then
			return table.Copy(mate:GetRoleColor())
		end
	elseif ply.mateSubRole then
		return table.Copy(GetRoleByIndex(ply.mateSubRole)[colorTable])
	end
end

local function GetDarkenMateColor(ply, colorTable)
	ply = ply or LocalPlayer()

	if IsValid(ply) and ply.GetSubRole and ply:GetSubRole() and ply:GetSubRole() == ROLE_SLAVE then
		local col
		local deadSubRole = ply.lastMateSubRole
		local mate = ply:GetSlaveMate()

		if not ply:Alive() and deadSubRole then
			if IsValid(mate) and mate:IsPlayer() and mate:IsInTeam(ply) and not mate:GetSubRoleData().unknownTeam then
				col = tmpfnc(ply, mate, colorTable)
			else
				col = table.Copy(GetRoleByIndex(deadSubRole)[colorTable])
			end
		else
			col = tmpfnc(ply, mate, colorTable)
		end

		return GetDarkenColor(col)
	end
end

function plymeta:IsSlave()
	return IsValid(self:GetNWEntity("binded_slave", nil))
end

function plymeta:GetSlaveMate()
	local data = self:GetNWEntity("binded_slave", nil)

	if IsValid(data) then
		return data
	end
end

function plymeta:GetSlaves()
	local tmp = {}

	for _, v in ipairs(player.GetAll()) do
		if v:GetSubRole() == ROLE_SLAVE and v:GetSlaveMate() == self then
			table.insert(tmp, v)
		end
	end

	if #tmp == 0 then
		tmp = nil
	end

	return tmp
end

function HealPlayer(ply)
	ply:SetHealth(ply:GetMaxHealth())
end

if SERVER then
	util.AddNetworkString("TTT_HealPlayer")
	util.AddNetworkString("TTT2SyncSlaveColor")

	function AddSlave(target, attacker)
		if target:IsSlave() or attacker:IsSlave() then return end

		target:SetNWEntity("binded_slave", attacker)
		target:SetRole(ROLE_SLAVE, attacker:GetTeam())
		local credits = target:GetCredits()
		target:SetDefaultCredits()
		target:SetCredits(target:GetCredits() + credits)

		target.mateSubRole = attacker:GetSubRole()

		target.slaveTimestamp = os.time()
		target.slaveIssuer = attacker

		timer.Simple(0.1, SendFullStateUpdate)
	end

	hook.Add("PlayerShouldTakeDamage", "SlaveProtectionTime", function(ply, atk)
		local pTime = GetConVar("ttt2_slave_protection_time"):GetInt()

		if pTime > 0 and IsValid(atk) and atk:IsPlayer()
		and ply:IsActive() and atk:IsActive()
		and atk:IsSlave() and atk.slaveIssuer == ply
		and atk.slaveTimestamp + pTime >= os.time() then
			return false
		end
	end)

	hook.Add("EntityTakeDamage", "SlaveEntTakeDmg", function(target, dmginfo)
		local attacker = dmginfo:GetAttacker()

		if target:IsPlayer() and IsValid(attacker) and attacker:IsPlayer()
		and (target:Health() - dmginfo:GetDamage()) <= 0
		and hook.Run("TTT2SLAVEAddSlave", attacker, target)
		then
			dmginfo:ScaleDamage(0)

			AddSlave(target, attacker)
			HealPlayer(target)

			-- do this clientside as well
			net.Start("TTT_HealPlayer")
			net.Send(target)
		end
	end)

	hook.Add("PlayerDisconnected", "SlavePlyDisconnected", function(discPly)
		local slaves, mate

		if discPly:IsSlave() then
			slaves = {discPly}
			mate = discPly:GetSlaveMate()
		else
			slaves = discPly:GetSlaves()
			mate = discPly
		end

		if slaves then
			local enabled = GetConVar("ttt2_slave_mode"):GetInt() == 1

			for _, slave in ipairs(slaves) do
				if not IsValid(slave) or not slave:IsPlayer() or not slave:IsActive() then continue end

				slave:SetNWEntity("binded_slave", nil)

				if not enabled then continue end

				local newRole = ROLE_INNOCENT

				if not newRole then continue end

				slave:SetRole(newRole, TEAM_INNOCENT)
				SendFullStateUpdate()
			end
		end
	end)

	hook.Add("PostPlayerDeath", "PlayerDeathChangeSlave", function(ply)
		if GetConVar("ttt2_slave_mode"):GetInt() == 1 then
			local slaves = ply:GetSlaves()
			if slaves then
				for _, slave in ipairs(slaves) do
					if not IsValid(slave) or not slave:IsActive() then continue end

					slave:SetNWEntity("binded_slave", nil)

					local newRole = ROLE_INNOCENT

					if newRole then
						slave:SetRole(newRole, TEAM_INNOCENT)

						SendFullStateUpdate()
					end

					-- a player can just be binded with one player as slave
					if #slaves == 1 then
						ply.spawn_as_slave = slave
					end
				end
			end
		end

		local mate = ply:GetSlaveMate()

		if not IsValid(mate) or ply.lastMateSubRole then return end

		ply.lastMateSubRole = ply.mateSubRole or mate:GetSubRole()
	end)

	hook.Add("PlayerSpawn", "PlayerSpawnsAsSlave", function(ply)
		if not ply.spawn_as_slave then return end

		AddSlave(ply, ply.spawn_as_slave)

		ply.spawn_as_slave = nil
	end)

	hook.Add("TTT2OverrideDisabledSync", "SlaveAllowTeammateSync", function(ply, p)
		if IsValid(p) and p:GetSubRole() == ROLE_SLAVE and ply:IsInTeam(p) and (not ply:GetSubRoleData().unknownTeam or ply == p:GetSlaveMate()) then
			return true
		end
	end)

	hook.Add("TTTBodyFound", "SlaveSendLastColor", function(ply, deadply, rag)
		if not IsValid(deadply) or deadply:GetSubRole() ~= ROLE_SLAVE then return end

		net.Start("TTT2SyncSlaveColor")
		net.WriteString(deadply:EntIndex())
		net.WriteUInt(deadply.mateSubRole, ROLE_BITS)
		net.WriteUInt(deadply.lastMateSubRole, ROLE_BITS)
		net.Broadcast()
	end)

	-- fix that innos can see their slaves
	hook.Add("TTT2SpecialRoleSyncing", "TTT2SlaveInnoSyncFix", function(ply, tmp)
		local rd = ply:GetSubRoleData()
		local slaves = ply:GetSlaves()

		if not rd.unknownTeam or not slaves then return end

		for _, slave in ipairs(slaves) do
			if IsValid(slave) and slave:IsInTeam(ply) then
				tmp[slave] = {ROLE_SLAVE, ply:GetTeam()}
			end
		end
	end)
end

if CLIENT then
	net.Receive("TTT_HealPlayer", function()
		HealPlayer(LocalPlayer())
	end)

	net.Receive("TTT2SyncSlaveColor", function()
		local ply = Entity(net.ReadString())

		if not IsValid(ply) or not ply:IsPlayer() then return end

		ply.mateSubRole = net.ReadUInt(ROLE_BITS)
		ply.lastMateSubRole = net.ReadUInt(ROLE_BITS)
		ply:SetRoleColor(COLOR_BLACK)
	end)

	-- Modify colors
	hook.Add("TTT2ModifyRoleDkColor", "SlaveModifyRoleDkColor", function(ply)
		return GetDarkenMateColor(ply, "dkcolor")
	end)

	hook.Add("TTT2ModifyRoleBgColor", "SlaveModifyRoleBgColor", function(ply)
		return GetDarkenMateColor(ply, "bgcolor")
	end)
end

--modify role colors on both client and server
hook.Add("TTT2ModifyRoleColor", "SlaveModifyRoleColor", function(ply)
	return GetDarkenMateColor(ply, "color")
end)

hook.Add("TTTPrepareRound", "SlavePrepareRound", function()
	for _, ply in ipairs(player.GetAll()) do
		ply.mateSubRole = nil
		ply.lastMateSubRole = nil
		ply.spawn_as_slave = nil

		if SERVER then
			ply:SetNWEntity("binded_slave", nil)
		end
	end
end)

-- SLAVE HITMAN FUNCTION
if SERVER then
	hook.Add("TTT2CheckCreditAward", "TTTCSlaveMod", function(victim, attacker)
		if IsValid(attacker) and attacker:IsPlayer() and attacker:IsActive() and attacker:GetSubRole() == ROLE_SLAVE and GetConVar("ttt2_slave_mode"):GetInt() ~= 1 then
			return false -- prevent awards
		end
	end)

	-- CLASSES syncing
	hook.Add("TTT2UpdateSubrole", "TTTCSlaveMod", function(slave, oldRole, role)
		if not TTTC or not slave:IsActive() or role ~= ROLE_SLAVE or GetConVar("ttt2_slave_mode"):GetInt() == 1 then return end

		for _, ply in ipairs(player.GetAll()) do
			net.Start("TTT2SlaveSyncClasses")
			net.WriteEntity(ply)
			net.WriteUInt(ply:GetCustomClass() or 0, CLASS_BITS)
			net.Send(slave)
		end
	end)

	include("target.lua")
end

if CLIENT then
	net.Receive("TTT2SlaveSyncClasses", function(len)
		local target = net.ReadEntity()
		if not IsValid(target) then return end

		local hr = net.ReadUInt(CLASS_BITS)
		if hr == 0 then
			hr = nil
		end

		target:SetClass(hr)
	end)
end
