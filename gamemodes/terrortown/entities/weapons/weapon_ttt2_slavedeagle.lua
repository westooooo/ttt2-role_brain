SWEP.Base = "weapon_tttbase"

SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true

SWEP.HoldType = "pistol"

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/icon_slavedeagle.vmt")

	util.AddNetworkString("tttSlaveMSG_attacker")
	util.AddNetworkString("tttSlaveMSG_target")
	util.AddNetworkString("tttSlaveRefillCDReduced")
	util.AddNetworkString("tttSlaveDeagleRefilled")
	util.AddNetworkString("tttSlaveDeagleMiss")
	util.AddNetworkString("tttSlaveSameTeam")
end

if CLIENT then
	SWEP.PrintName = "Slave Deagle"
	SWEP.Author = "Westoon"

	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false

	SWEP.Category = "Deagle"
	SWEP.Icon = "vgui/ttt/icon_slavedeagle.vtf"
	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "weapon_slavedeagle_name",
		desc = "weapon_slavedeagle_desc"
	}
end

-- dmg
SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 6
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage = 0
SWEP.Primary.Cone = 0.00001
SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1

-- some other stuff
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.UseHands = true
SWEP.Kind = WEAPON_EXTRA
SWEP.CanBuy = {}
SWEP.LimitedStock = true
SWEP.globalLimited = true
SWEP.NoRandom = true

-- view / world
SWEP.ViewModel = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.Weight = 5
SWEP.Primary.Sound = Sound("Weapon_Deagle.Single")

SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.notBuyable = true

local ttt2_slave_deagle_refill_conv = CreateConVar("ttt2_slave_deagle_refill", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
local ttt2_slave_deagle_refill_cd_conv = CreateConVar("ttt2_slave_deagle_refill_cd", 120, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
local ttt2_slave_deagle_refill_cd_per_kill_conv = CreateConVar("ttt2_slave_deagle_refill_cd_per_kill", 60, {FCVAR_NOTIFY, FCVAR_ARCHIVE})

local function SlaveDeagleRefilled(wep)
	if not IsValid(wep) then return end

	local text = LANG.GetTranslation("ttt2_slave_recharged")
	MSTACK:AddMessage(text)

	STATUS:RemoveStatus("ttt2_slave_deagle_reloading")
	net.Start("tttSlaveDeagleRefilled")
	net.WriteEntity(wep)
	net.SendToServer()
end

local function SlaveDeagleCallback(attacker, tr, dmg)
	if CLIENT then return end

	local target = tr.Entity

	--invalid shot return
	if not GetRoundState() == ROUND_ACTIVE or not IsValid(attacker) or not attacker:IsPlayer() or not attacker:IsTerror() then return end

	--no/bad hit: (send message), start timer and return
	if not IsValid(target) or not target:IsPlayer() or not target:IsTerror() or target:IsInTeam(attacker) then
		if IsValid(target) and target:IsPlayer() and target:IsTerror() and target:IsInTeam(attacker) then
			net.Start("tttSlaveSameTeam")
			net.Send(attacker)
		end

		if ttt2_slave_deagle_refill_conv:GetBool() then
			net.Start("tttSlaveDeagleMiss")
			net.Send(attacker)
		end

		return
	end

	local deagle = attacker:GetWeapon("weapon_ttt2_slavedeagle")
	if IsValid(deagle) then
		deagle:Remove()
	end

	AddSlave(target, attacker)

	net.Start("tttSlaveMSG_attacker")
	net.WriteEntity(target)
	net.Send(attacker)

	net.Start("tttSlaveMSG_target")
	net.WriteEntity(attacker)
	net.Send(target)

	return true
end

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:ShootBullet(dmg, recoil, numbul, cone)
	cone = cone or 0.01

	local bullet = {}
	bullet.Num = 1
	bullet.Src = self:GetOwner():GetShootPos()
	bullet.Dir = self:GetOwner():GetAimVector()
	bullet.Spread = Vector(cone, cone, 0)
	bullet.Tracer = 0
	bullet.TracerName = self.Tracer or "Tracer"
	bullet.Force = 10
	bullet.Damage = 0
	bullet.Callback = SlaveDeagleCallback

	self:GetOwner():FireBullets(bullet)

	self.BaseClass.ShootBullet(self, dmg, recoil, numbul, cone)
end

function SWEP:OnRemove()
	if CLIENT then
		STATUS:RemoveStatus("ttt2_slave_deagle_reloading")

		timer.Stop("ttt2_slave_deagle_refill_timer")
	end
end

function ShootSlave(target, dmginfo)
	local attacker = dmginfo:GetAttacker()

	if not attacker:IsPlayer() or not target:IsPlayer() or not IsValid(attacker:GetActiveWeapon())
		or not attacker:IsTerror() or not IsValid(target) or not target:IsTerror() then return end

	if target:GetSubRole() == ROLE_BRAINWASHER or target:GetSubRole() == ROLE_SLAVE then
		return
	end

	AddSlave(target, attacker)

	net.Start("tttSlaveMSG_attacker")
	net.WriteEntity(target)
	net.Send(attacker)

	net.Start("tttSlaveMSG_target")
	net.WriteEntity(attacker)
	net.Send(target)
end


if SERVER then
	hook.Add("PlayerDeath", "SlaveDeagleRefillReduceCD", function(victim, inflictor, attacker)
		if IsValid(attacker) and attacker:IsPlayer() and attacker:HasWeapon("weapon_ttt2_slavedeagle") and ttt2_slave_deagle_refill_conv:GetBool() then
			net.Start("tttSlaveRefillCDReduced")
			net.Send(attacker)
		end
	end)
end


-- auto add slave weapon into brainwasher shop
hook.Add("LoadedFallbackShops", "SlaveDeagleAddToShop", function()
	if BRAINWASHER and SLAVE and BRAINWASHER.fallbackTable then
		AddWeaponIntoFallbackTable("weapon_ttt2_slavedeagle", BRAINWASHER)
	end
end)

if CLIENT then
	hook.Add("Initialize", "ttt_slave_init_status", function()
		STATUS:RegisterStatus("ttt2_slave_deagle_reloading", {
			hud = Material("vgui/ttt/hud_icon_deagle.png"),
			type = "bad"
		})
	end)

	net.Receive("tttSlaveMSG_attacker", function(len)
		local target = net.ReadEntity()
		if not IsValid(target) then return end

		local text = LANG.GetParamTranslation("ttt2_slave_shot", {name = target:GetName()})
		MSTACK:AddMessage(text)
	end)

	net.Receive("tttSlaveMSG_target", function(len)
		local attacker = net.ReadEntity()
		if not IsValid(attacker) then return end

		local text = LANG.GetParamTranslation("ttt2_slave_were_shot", {name = attacker:GetName()})
		MSTACK:AddMessage(text)
	end)

	net.Receive("tttSlaveRefillCDReduced", function()
		if not timer.Exists("ttt2_slave_deagle_refill_timer") or not LocalPlayer():HasWeapon("weapon_ttt2_slavedeagle") then return end

		local timeLeft = timer.TimeLeft("ttt2_slave_deagle_refill_timer") or 0
		local newTime = math.max(timeLeft - ttt2_slave_deagle_refill_cd_per_kill_conv:GetInt(), 0.1)

		local wep = LocalPlayer():GetWeapon("weapon_ttt2_slavedeagle")
		if not IsValid(wep) then return end

		timer.Adjust("ttt2_slave_deagle_refill_timer", newTime, 1, function()
			if not IsValid(wep) then return end

			SlaveDeagleRefilled(wep)
		end)

		if STATUS.active["ttt2_slave_deagle_reloading"] then
			STATUS.active["ttt2_slave_deagle_reloading"].displaytime = CurTime() + newTime
		end

		local text = LANG.GetParamTranslation("ttt2_slave_ply_killed", {amount = ttt2_slave_deagle_refill_cd_per_kill_conv:GetInt()})
		MSTACK:AddMessage(text)
		chat.PlaySound()
	end)

	net.Receive("tttSlaveDeagleMiss", function()
		local client = LocalPlayer()
		if not IsValid(client) or not client:IsTerror() or not client:HasWeapon("weapon_ttt2_slavedeagle") then return end

		local wep = client:GetWeapon("weapon_ttt2_slavedeagle")
		if not IsValid(wep) then return end

		local initialCD = ttt2_slave_deagle_refill_cd_conv:GetInt()

		STATUS:AddTimedStatus("ttt2_slave_deagle_reloading", initialCD, true)

		timer.Create("ttt2_slave_deagle_refill_timer", initialCD, 1, function()
			if not IsValid(wep) then return end

			SlaveDeagleRefilled(wep)
		end)
	end)

	net.Receive("tttSlaveSameTeam", function()
		MSTACK:AddMessage(LANG.GetTranslation("ttt2_slave_sameteam"))
	end)
else
	net.Receive("tttSlaveDeagleRefilled", function(_, ply)
		local wep = net.ReadEntity()
	
		if not IsValid(wep) or wep:GetClass() ~= "weapon_ttt2_slavedeagle" then return end

		wep:SetClip1(1)
	end)
end
