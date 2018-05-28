FAIO_utility_functions = {}

function FAIO_utility_functions.utilityRoundNumber(number, digits)

	if not number then return end

  	local mult = 10^(digits or 0)
  	return math.floor(number * mult + 0.5) / mult

end

function FAIO_utility_functions.utilityGetTableLength(table)

	if not table then return 0 end
	if next(table) == nil then return 0 end

	local count = 0
	for i, v in pairs(table) do
		count = count + 1
	end

	return count

end

function FAIO_utility_functions.utilityIsInTable(table, arg)

	if not table then return false end
	if not arg then return false end
	if next(table) == nil then return false end

	for i, v in pairs(table) do
		if i == arg then
			return true
		end
		if type(v) ~= 'table' and v == arg then
			return true
		end
	end

	return false

end

function FAIO_utility_functions.castLinearPrediction(myHero, enemy, adjustmentVariable)

	if not myHero then return end
	if not enemy then return end

	local enemyRotation = Entity.GetRotation(enemy):GetVectors()
		enemyRotation:SetZ(0)
    	local enemyOrigin = NPC.GetAbsOrigin(enemy)
		enemyOrigin:SetZ(0)


	local cosGamma = (NPC.GetAbsOrigin(myHero) - enemyOrigin):Dot2D(enemyRotation:Scaled(100)) / ((NPC.GetAbsOrigin(myHero) - enemyOrigin):Length2D() * enemyRotation:Scaled(100):Length2D())

		if enemyRotation and enemyOrigin then
			if not NPC.IsRunning(enemy) then
				return enemyOrigin
			else return enemyOrigin:__add(enemyRotation:Normalized():Scaled(FAIO_utility_functions.GetMoveSpeed(enemy) * adjustmentVariable * (1 - cosGamma)))
			end
		end
end

function FAIO_utility_functions.castPrediction(myHero, enemy, adjustmentVariable)

	if not myHero then return end
	if not enemy then return end

	local enemyRotation = Entity.GetRotation(enemy):GetVectors()
		enemyRotation:SetZ(0)
    	local enemyOrigin = NPC.GetAbsOrigin(enemy)
		enemyOrigin:SetZ(0)

	if enemyRotation and enemyOrigin then
			if not NPC.IsRunning(enemy) then
				return enemyOrigin
			else return enemyOrigin:__add(enemyRotation:Normalized():Scaled(FAIO_utility_functions.GetMoveSpeed(enemy) * adjustmentVariable))
			end
	end
end

function FAIO_utility_functions.isEnemyTurning(enemy)

	if enemy == nil then return true end
	if not NPC.IsRunning(enemy) then return true end

	local rotationSpeed = Entity.GetAngVelocity(enemy):Length2D()
	if NPC.IsRunning(enemy) then
		table.insert(FAIO_utility_functions.rotationTable, rotationSpeed)
			if #FAIO_utility_functions.rotationTable > (Menu.GetValue(FAIO_options.optionKillStealInvokerTurn) + 1) then
				table.remove(FAIO_utility_functions.rotationTable, 1)
			end
	end
	
	if #FAIO_utility_functions.rotationTable < Menu.GetValue(FAIO_options.optionKillStealInvokerTurn) then 
		return true
	else
		local rotationSpeedCounter = 0
		i = 1
		repeat
			rotationSpeedCounter = rotationSpeedCounter + FAIO_utility_functions.rotationTable[#FAIO_utility_functions.rotationTable + 1 - i]
			i = i + 1
		until i > Menu.GetValue(FAIO_options.optionKillStealInvokerTurn)

		if rotationSpeedCounter / Menu.GetValue(FAIO_options.optionKillStealInvokerTurn) <= 10 then
			return false
		else
			return true
		end
	end
 
end

function FAIO_utility_functions.GetMoveSpeed(enemy)

	if not enemy then return end

	local base_speed = NPC.GetBaseSpeed(enemy)
	local bonus_speed = NPC.GetMoveSpeed(enemy) - NPC.GetBaseSpeed(enemy)
	local modifierHex
    	local modSheep = NPC.GetModifier(enemy, "modifier_sheepstick_debuff")
    	local modLionVoodoo = NPC.GetModifier(enemy, "modifier_lion_voodoo")
    	local modShamanVoodoo = NPC.GetModifier(enemy, "modifier_shadow_shaman_voodoo")

	if modSheep then
		modifierHex = modSheep
	end
	if modLionVoodoo then
		modifierHex = modLionVoodoo
	end
	if modShamanVoodoo then
		modifierHex = modShamanVoodoo
	end

	if modifierHex then
		if math.max(Modifier.GetDieTime(modifierHex) - GameRules.GetGameTime(), 0) > 0 then
			return 140 + bonus_speed
		end
	end

    	if NPC.HasModifier(enemy, "modifier_invoker_ice_wall_slow_debuff") then 
		return 100 
	end

	if NPC.HasModifier(enemy, "modifier_invoker_cold_snap_freeze") or NPC.HasModifier(enemy, "modifier_invoker_cold_snap") then
		return (base_speed + bonus_speed) * 0.5
	end

	if NPC.HasModifier(enemy, "modifier_spirit_breaker_charge_of_darkness") then
		local chargeAbility = NPC.GetAbility(enemy, "spirit_breaker_charge_of_darkness")
		if chargeAbility then
			local specialAbility = NPC.GetAbility(enemy, "special_bonus_unique_spirit_breaker_2")
			if specialAbility then
				 if Ability.GetLevel(specialAbility) < 1 then
					return Ability.GetLevel(chargeAbility) * 50 + 550
				else
					return Ability.GetLevel(chargeAbility) * 50 + 1050
				end
			end
		end
	end
			
    	return base_speed + bonus_speed
end

function FAIO_utility_functions.getBestPosition(unitsAround, radius)

	if not unitsAround or #unitsAround < 1 then
		return 
	end

	local countEnemies = #unitsAround

	if countEnemies == 1 then 
		return Entity.GetAbsOrigin(unitsAround[1]) 
	end

	return FAIO_utility_functions.getMidPoint(unitsAround)



end

function FAIO_utility_functions.getMidPoint(entityList)

	if not entityList then return end
	if #entityList < 1 then return end

	local pts = {}
		for i, v in ipairs(entityList) do
			if v and not Entity.IsDormant(v) then
				local pos = Entity.GetAbsOrigin(v)
				local posX = pos:GetX()
				local posY = pos:GetY()
				table.insert(pts, { x=posX, y=posY })
			end
		end
	
	local x, y, c = 0, 0, #pts

		if (pts.numChildren and pts.numChildren > 0) then c = pts.numChildren end

	for i = 1, c do

		x = x + pts[i].x
		y = y + pts[i].y

	end

	return Vector(x/c, y/c, 0)

end

function FAIO_utility_functions.GetMyFaction(myHero)

	if not myHero then return end
	
	local radiantFountain = Vector(-7600, -7300, 640)
	local direFountain = Vector(7800, 7250, 640)
	
	local myFountain
	if myFountain == nil then
		for i = 1, NPCs.Count() do 
		local npc = NPCs.Get(i)
    			if Entity.IsSameTeam(myHero, npc) and NPC.IsStructure(npc) then
    				if NPC.GetUnitName(npc) ~= nil then
        				if NPC.GetUnitName(npc) == "dota_fountain" then
						myFountain = npc
					end
				end
			end
		end
	end

	local myFaction
	if myFaction == nil and myFountain ~= nil then
		if NPC.IsPositionInRange(myFountain, radiantFountain, 1000, 0) then
			myFaction = "radiant"
		else myFaction = "dire"
		end
	end

	return myFaction

end

function FAIO_utility_functions.GetMyFountainPos(myHero)

	if not myHero then return end

	local myFaction 
		if myFaction == nil then 
			myFaction = FAIO_utility_functions.GetMyFaction(myHero)
		end

	local myFountainPos
	if myFaction ~= nil then
		if myFaction == "radiant" then
			myFountainPos = Vector(-7600, -7300, 640)
		else 
			myFountainPos = Vector(7800, 7250, 640)
		end
	end

	return myFountainPos

end

function FAIO_utility_functions.GetEnemyFountainPos(myHero)

	if not myHero then return end

	local myFaction
		if myFaction == nil then 
			myFaction = FAIO_utility_functions.GetMyFaction(myHero)
		end

	local enemyFountainPos
	if myFaction ~= nil then
		if myFaction == "radiant" then
			enemyFountainPos = Vector(7800, 7250, 640)
		else 
			enemyFountainPos = Vector(-7600, -7300, 640)
		end
	end

	return enemyFountainPos

end

function FAIO_utility_functions.IsCreepAncient(npc)

	if not npc then return false end

	ancientNameList = { 
		"npc_dota_neutral_black_drake",
    		"npc_dota_neutral_black_dragon",
    		"npc_dota_neutral_blue_dragonspawn_sorcerer",
    		"npc_dota_neutral_blue_dragonspawn_overseer",
    		"npc_dota_neutral_granite_golem",
    		"npc_dota_neutral_elder_jungle_stalker",
    		"npc_dota_neutral_prowler_acolyte",
    		"npc_dota_neutral_prowler_shaman",
    		"npc_dota_neutral_rock_golem",
    		"npc_dota_neutral_small_thunder_lizard",
    		"npc_dota_neutral_jungle_stalker",
    		"npc_dota_neutral_big_thunder_lizard",
    		"npc_dota_roshan" }

	for _, creepName in ipairs(ancientNameList) do
		if creepName and NPC.GetUnitName(npc) ~= nil then
			if NPC.GetUnitName(npc) == creepName then
				return true
			end
		end
	end

	return false

end

function FAIO_utility_functions.inSkillAnimation(myHero)

	if not myHero then return false end

	local abilities = {}

	if next(abilities) == nil then
		for i = 0, 25 do
			local ability = NPC.GetAbilityByIndex(myHero, i)
			if ability and Entity.IsAbility(ability) then
				table.insert(abilities, ability)
			end
		end
	end

	for i, v in ipairs(abilities) do
		if Ability.IsInAbilityPhase(v) then
			return true
		end
	end

	return false

end

------ bis hier angepasst

function FAIO_utility_functions.TimeToFacePosition(myHero, pos)

	if not myHero then return 0 end
	if not pos then return 0 end

	local myPos = Entity.GetAbsOrigin(myHero)
	local myRotation = Entity.GetRotation(myHero):GetForward():Normalized()

	local baseVec = (pos - myPos):Normalized()

	local tempProcessing = math.min(baseVec:Dot2D(myRotation) / (baseVec:Length2D() * myRotation:Length2D()), 1)	

	local checkAngleRad = math.acos(tempProcessing)
	local checkAngle = (180 / math.pi) * checkAngleRad

	local myTurnRate = NPC.GetTurnRate(myHero)

	local turnTime = FAIO_utility_functions.utilityRoundNumber(((0.033 * math.pi / myTurnRate) / 180) * checkAngle, 3)

	return turntime or 0

end

function FAIO_utility_functions.GetLongestCooldown(myHero, skill1, skill2, skill3, skill4, skill5)

	if not myHero then return end

	local skill1 = skill1
	local skill2 = skill2
	local skill3 = skill3
	local skill4 = skill4
	local skill5 = skill5


	local tempTable = {}

	if skill1 then
		table.insert(tempTable, math.ceil(Ability.GetCooldownTimeLeft(skill1)))
	end
	if skill2 then
		table.insert(tempTable, math.ceil(Ability.GetCooldownTimeLeft(skill2)))
	end
	if skill3 then
		table.insert(tempTable, math.ceil(Ability.GetCooldownTimeLeft(skill3)))
	end
	if skill4 then
		table.insert(tempTable, math.ceil(Ability.GetCooldownTimeLeft(skill4)))
	end
	if skill5 then
		table.insert(tempTable, math.ceil(Ability.GetCooldownTimeLeft(skill5)))
	end

	table.sort(tempTable, function(a, b)
        	return a > b
    			end)

	return tempTable[1]

end

function FAIO_utility_functions.TargetDisableTimer(myHero, enemy)

	if not myHero then return 0 end
	if not enemy then return 0 end

	local stunRootList = {
		"modifier_stunned",
		"modifier_bashed",
		"modifier_alchemist_unstable_concoction", 
		"modifier_ancientapparition_coldfeet_freeze", 
		"modifier_axe_berserkers_call",
		"modifier_bane_fiends_grip",
		"modifier_bane_nightmare",
		"modifier_bloodseeker_rupture",
		"modifier_rattletrap_hookshot", 
		"modifier_earthshaker_fissure_stun", 
		"modifier_earth_spirit_boulder_smash",
		"modifier_enigma_black_hole_pull",
		"modifier_faceless_void_chronosphere_freeze",
		"modifier_jakiro_ice_path_stun", 
		"modifier_keeper_of_the_light_mana_leak_stun", 
		"modifier_kunkka_torrent", 
		"modifier_legion_commander_duel", 
		"modifier_lion_impale", 
		"modifier_magnataur_reverse_polarity", 
		"modifier_medusa_stone_gaze_stone", 
		"modifier_morphling_adaptive_strike", 
		"modifier_naga_siren_ensnare", 
		"modifier_nyx_assassin_impale", 
		"modifier_pudge_dismember", 
		"modifier_sandking_impale", 
		"modifier_shadow_shaman_shackles", 
		"modifier_techies_stasis_trap_stunned", 
		"modifier_tidehunter_ravage", 
		"modifier_treant_natures_guise",
		"modifier_windrunner_shackle_shot",
		"modifier_rooted", 
		"modifier_crystal_maiden_frostbite", 
		"modifier_ember_spirit_searing_chains", 
		"modifier_meepo_earthbind",
		"modifier_lone_druid_spirit_bear_entangle_effect",
		"modifier_slark_pounce_leash",
		"modifier_storm_spirit_electric_vortex_pull",
		"modifier_treant_overgrowth", 
		"modifier_abyssal_underlord_pit_of_malice_ensare", 
		"modifier_item_rod_of_atos_debuff",
		"modifier_eul_cyclone",
		"modifier_obsidian_destroyer_astral_imprisonment_prison",
		"modifier_shadow_demon_disruption"
			}
	
	local searchMod
	for _, modifier in ipairs(stunRootList) do
		if NPC.HasModifier(enemy, modifier) then
			searchMod = NPC.GetModifier(enemy, modifier)
			break
		end
	end

	if searchMod then
		if NPC.HasModifier(enemy, Modifier.GetName(searchMod)) then
			if Modifier.GetName(searchMod) == "modifier_enigma_black_hole_pull" then
				return Modifier.GetCreationTime(searchMod) + 4
			elseif Modifier.GetName(searchMod) == "modifier_faceless_void_chronosphere_freeze" then
				return Modifier.GetCreationTime(searchMod) + (3.5 + FAIO_utility_functions.GetTeammateAbilityLevel(myHero, "faceless_void_chronosphere") * 0.5)
			else
				return Modifier.GetDieTime(searchMod)
			end
		end
	end

	return 0

end

function FAIO_utility_functions.GetTeammateAbilityLevel(myHero, ability)

	if not myHero then return end
	if not ability then return 0 end

	for _, teamMate in ipairs(NPC.GetHeroesInRadius(myHero, 99999, Enum.TeamType.TEAM_FRIEND)) do
		if NPC.HasAbility(teamMate, ability) then
			if NPC.GetAbility(teamMate, ability) then
				return Ability.GetLevel(NPC.GetAbility(teamMate, ability))
			end
		end
	end
	return 0

end

function FAIO_utility_functions.TargetIsInvulnarable(myHero, enemy)

	if not myHero then return end
	if not enemy then return end

	local curTime = GameRules.GetGameTime()

	local invuList = {
		"modifier_eul_cyclone",
		"modifier_invoker_tornado",
		"modifier_obsidian_destroyer_astral_imprisonment_prison",
		"modifier_shadow_demon_disruption"
			}
	
	local searchMod
	for _, modifier in ipairs(invuList) do
		if NPC.HasModifier(enemy, modifier) then
			searchMod = NPC.GetModifier(enemy, modifier)
			break
		end
	end

	if searchMod then
		if NPC.HasModifier(enemy, Modifier.GetName(searchMod)) then
			return Modifier.GetDieTime(searchMod)
		else
			return 0
		end
	else
		return 0
	end

end

function FAIO_utility_functions.GetClosestPoint(A,  B,  P, segmentClamp)
	
	A:SetZ(0)
	B:SetZ(0)
	P:SetZ(0)

	local Ax = A:GetX()
	local Ay = A:GetY()
	local Bx = B:GetX()
	local By = B:GetY()
	local Px = P:GetX()
	local Py = P:GetY()

	local AP = P - A
	local AB = B - A

	local APx = AP:GetX()
	local APy = AP:GetY()

	local ABx = AB:GetX()
	local ABy = AB:GetY()

	local ab2 = ABx*ABx + ABy*ABy
	local ap_ab = APx*ABx + APy*ABy

	local t = ap_ab / ab2
 
	if (segmentClamp or true) then
		if (t < 0.0) then
			t = 0.0
		elseif (t > 1.0) then
			t = 1.0
		end
	end
 
	local Closest = Vector(Ax + ABx*t, Ay + ABy * t, 0)
 
	return Closest
end

function FAIO_utility_functions.IsNPCinDanger(myHero, npc)

	if not myHero then return false end
	if not npc or NPC.IsIllusion(npc) or not Entity.IsAlive(npc) then return false end

	if NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end
	if NPC.HasModifier(npc, "modifier_item_lotus_orb_active") then return false end

	if NPC.HasModifier(npc, "modifier_dazzle_shallow_grave") then return false end
	if FAIO_utility_functions.IsHeroInvisible(npc) == true then return false end
	if NPC.HasModifier(npc, "modifier_fountain_aura_buff") then return false end

	if #Entity.GetHeroesInRadius(npc, 1500, Enum.TeamType.TEAM_ENEMY) < 1 then return false end
	if #Entity.GetHeroesInRadius(myHero, 1500, Enum.TeamType.TEAM_ENEMY) < 1 then return false end
	if (Entity.GetAbsOrigin(myHero) - FAIO_utility_functions.GetMyFountainPos(myHero)):Length2D() < 1500 then return end

	if NPC.GetUnitName(npc) == "npc_dota_hero_monkey_king" then
		if NPC.GetAbilityByIndex(npc, 1) ~= nil then
			if Ability.SecondsSinceLastUse(NPC.GetAbilityByIndex(npc, 1)) > -1 and Ability.SecondsSinceLastUse(NPC.GetAbilityByIndex(npc, 1)) < 2 then
				return false
			end
		end
	end

	if NPC.GetUnitName(npc) == "npc_dota_hero_nyx_assassin" then
		if NPC.GetAbility(npc, "nyx_assassin_burrow") ~= nil and Ability.GetLevel(NPC.GetAbility(npc, "nyx_assassin_burrow")) > 0 then
			if Ability.IsInAbilityPhase(NPC.GetAbility(npc, "nyx_assassin_burrow")) then
				return false
			elseif not Ability.IsHidden(NPC.GetAbility(npc, "nyx_assassin_unburrow")) then
				return false
			end
		end
	end

	if NPC.GetUnitName(npc) == "npc_dota_hero_sand_king" then
		if NPC.GetAbility(npc, "sandking_burrowstrike") ~= nil then
			local burrow = NPC.GetAbility(npc, "sandking_burrowstrike")
			if Ability.SecondsSinceLastUse(burrow) > -1 and Ability.SecondsSinceLastUse(burrow) < 1 then
				return false
			end
		end
	end

	if NPC.GetUnitName(npc) == "npc_dota_hero_earth_spirit" then
		if NPC.GetAbility(npc, "earth_spirit_rolling_boulder") ~= nil then
			local boulder = NPC.GetAbility(npc, "earth_spirit_rolling_boulder")
			if Ability.SecondsSinceLastUse(boulder) > -1 and Ability.SecondsSinceLastUse(boulder) < 2 then
				return false
			end
		end
	end
	
	local momSilenced = false
	if NPC.HasItem(npc, "item_mask_of_madness", true) then
		local mom = NPC.GetItem(npc, "item_mask_of_madness", true)
		if Ability.SecondsSinceLastUse(mom) > -1 and Ability.SecondsSinceLastUse(mom) < 8 then
			momSilenced = true
		end
	end

	if NPC.HasModifier(npc, "modifier_nyx_assassin_burrow") then return false end
	if NPC.HasModifier(npc, "modifier_monkey_king_tree_dance_activity") then return false end

	if FAIO_utility_functions.TargetGotDisableModifier(myHero, npc) == true or (NPC.IsSilenced(npc) and not momSilenced) or
		NPC.HasModifier(npc, "modifier_item_nullifier_mute") or NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_HEXED) then

		if Entity.GetHealth(npc) / Entity.GetMaxHealth(npc) <= (Menu.GetValue(FAIO_options.optionDefensiveItemsThresholdDisable) / 100) then
			for _, v in ipairs(Entity.GetHeroesInRadius(myHero, 1000, Enum.TeamType.TEAM_ENEMY)) do
				if v and Entity.IsHero(v) and not Entity.IsDormant(v) then
					if NPC.FindFacingNPC(v) == npc or NPC.IsEntityInRange(npc, v, NPC.GetAttackRange(v) + 150) then
						return true
					end
				end
			end
		end
	end

	if Entity.GetHealth(npc) <= Menu.GetValue(FAIO_options.optionDefensiveItemsThreshold)/100 * Entity.GetMaxHealth(npc) then
		for _, v in ipairs(Entity.GetHeroesInRadius(npc, 1000, Enum.TeamType.TEAM_ENEMY)) do
			if v and Entity.IsHero(v) and not Entity.IsDormant(v) then
				if NPC.FindFacingNPC(v) == npc then
					return true
				end
			end
		end
	end

	return false

end

function FAIO_utility_functions.IsHeroInvisible(myHero)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return true end
	if NPC.HasModifier(myHero, "modifier_invoker_ghost_walk_self") then return true end
	if NPC.HasAbility(myHero, "invoker_ghost_walk") then
		if Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, "invoker_ghost_walk")) > -1 and Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, "invoker_ghost_walk")) < 1 then 
			return true
		end
	end

	if NPC.HasItem(myHero, "item_invis_sword", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_invis_sword", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_invis_sword", true)) < 1 then 
			return true
		end
	end
	if NPC.HasItem(myHero, "item_silver_edge", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_silver_edge", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_silver_edge", true)) < 1 then 
			return true
		end
	end

	return false
		
end

function FAIO_utility_functions.TargetGotDisableModifier(myHero, npc)

	if not myHero then return false end
	if not npc then return false end

	local stunRootList = {
		"modifier_stunned",
		"modifier_bashed",
		"modifier_alchemist_unstable_concoction", 
		"modifier_ancientapparition_coldfeet_freeze", 
		"modifier_axe_berserkers_call",
		"modifier_bane_fiends_grip",
		"modifier_bane_nightmare",
		"modifier_bloodseeker_rupture",
		"modifier_rattletrap_hookshot", 
		"modifier_earthshaker_fissure_stun", 
		"modifier_earth_spirit_boulder_smash",
		"modifier_enigma_black_hole_pull",
		"modifier_faceless_void_chronosphere_freeze",
		"modifier_jakiro_ice_path_stun", 
		"modifier_keeper_of_the_light_mana_leak_stun", 
		"modifier_kunkka_torrent", 
		"modifier_legion_commander_duel", 
		"modifier_lion_impale", 
		"modifier_magnataur_reverse_polarity", 
		"modifier_medusa_stone_gaze_stone", 
		"modifier_morphling_adaptive_strike", 
		"modifier_naga_siren_ensnare", 
		"modifier_nyx_assassin_impale", 
		"modifier_pudge_dismember", 
		"modifier_sandking_impale", 
		"modifier_shadow_shaman_shackles", 
		"modifier_techies_stasis_trap_stunned", 
		"modifier_tidehunter_ravage", 
		"modifier_treant_natures_guise",
		"modifier_windrunner_shackle_shot",
		"modifier_rooted", 
		"modifier_crystal_maiden_frostbite", 
		"modifier_ember_spirit_searing_chains", 
		"modifier_meepo_earthbind",
		"modifier_lone_druid_spirit_bear_entangle_effect",
		"modifier_slark_pounce_leash",
		"modifier_storm_spirit_electric_vortex_pull",
		"modifier_treant_overgrowth", 
		"modifier_abyssal_underlord_pit_of_malice_ensare", 
		"modifier_item_rod_of_atos_debuff",
			}
	
	local searchMod
	for _, modifier in ipairs(stunRootList) do
		if NPC.HasModifier(npc, modifier) then
			searchMod = NPC.GetModifier(npc, modifier)
			break
		end
	end

	local timeleft = 0
	if searchMod then
		if NPC.HasModifier(npc, Modifier.GetName(searchMod)) then
			if Modifier.GetName(searchMod) == "modifier_enigma_black_hole_pull" then
				timeleft = Modifier.GetCreationTime(searchMod) + 4
			elseif Modifier.GetName(searchMod) == "modifier_faceless_void_chronosphere_freeze" then
				timeleft = Modifier.GetCreationTime(searchMod) + 4.5
			else
				timeleft = Modifier.GetDieTime(searchMod)
			end
		else
			timeleft = 0
		end
	else
		timeleft = 0
	end

	if timeleft > 0.75 then
		return true
	end

	return false

end

function FAIO_utility_functions.heroCanCastSpells(myHero, enemy)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.IsSilenced(myHero) then return false end 
	if NPC.IsStunned(myHero) then return false end
	if NPC.HasModifier(myHero, "modifier_bashed") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end	
	if NPC.HasModifier(myHero, "modifier_eul_cyclone") then return false end
	if NPC.HasModifier(myHero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(myHero, "modifier_invoker_tornado") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_HEXED) then return false end
	if NPC.HasModifier(myHero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(myHero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(myHero, "modifier_winter_wyvern_winters_curse") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(myHero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_enigma_black_hole_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(myHero, "modifier_pudge_dismember") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_shaman_shackles") then return false end
	if NPC.HasModifier(myHero, "modifier_techies_stasis_trap_stunned") then return false end
	if NPC.HasModifier(myHero, "modifier_storm_spirit_electric_vortex_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(myHero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(myHero, "modifier_item_nullifier_mute") then return false end

	if enemy then
		if NPC.HasModifier(enemy, "modifier_item_aeon_disk_buff") then return false end
	end

	return true	

end

function FAIO_utility_functions.heroCanCastItems(myHero)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.IsStunned(myHero) then return false end
	if NPC.HasModifier(myHero, "modifier_bashed") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end	
	if NPC.HasModifier(myHero, "modifier_eul_cyclone") then return false end
	if NPC.HasModifier(myHero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(myHero, "modifier_invoker_tornado") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_HEXED) then return false end
	if NPC.HasModifier(myHero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(myHero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(myHero, "modifier_winter_wyvern_winters_curse") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(myHero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_enigma_black_hole_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(myHero, "modifier_pudge_dismember") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_shaman_shackles") then return false end
	if NPC.HasModifier(myHero, "modifier_techies_stasis_trap_stunned") then return false end
	if NPC.HasModifier(myHero, "modifier_storm_spirit_electric_vortex_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(myHero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(myHero, "modifier_item_nullifier_mute") then return false end

	return true	

end

function FAIO_utility_functions.isHeroChannelling(myHero)

	if not myHero then return true end

	if NPC.IsChannellingAbility(myHero) then return true end
	if NPC.HasModifier(myHero, "modifier_teleporting") then return true end

	return false

end

function FAIO_utility_functions.shouldCastBKB(myHero)

	if not myHero then return end

	local dangerousRangeTable = {
		alchemist_unstable_concoction_throw = 775,
		beastmaster_primal_roar = 600,
		centaur_hoof_stomp = 315,
		chaos_knight_chaos_bolt = 500,
		crystal_maiden_frostbite = 525,
		dragon_knight_dragon_tail = 400,
		drow_ranger_wave_of_silence = 900,
		earth_spirit_boulder_smash = 300,
		earthshaker_fissure = 1400,
		ember_spirit_searing_chains = 400,
		invoker_tornado = 1000,
		jakiro_ice_path = 1200,
		lion_impale = 500,
		lion_voodoo = 500,
		naga_siren_ensnare = 650,
		nyx_assassin_impale = 700,
		puck_dream_coil = 750,
		rubick_telekinesis = 625,
		sandking_burrowstrike = 650,
		shadow_shaman_shackles = 400,
		shadow_shaman_voodoo = 500,
		skeleton_king_hellfire_blast = 525,
		slardar_slithereen_crush = 400,
		storm_spirit_electric_vortex = 400,
		sven_storm_bolt = 600,
		tidehunter_ravage = 1025,
		tiny_avalanche = 600,
		vengefulspirit_magic_missile = 500,
		warlock_rain_of_chaos = 1200,
		windrunner_shackleshot = 800,
		slark_pounce = 700,
		ogre_magi_fireblast = 475,
		meepo_poof = 400
			}

	local enemyTable = {}
	local enemiesAround = Entity.GetHeroesInRadius(myHero, Menu.GetValue(FAIO_options.optionDefensiveItemsBKBRadius), Enum.TeamType.TEAM_ENEMY)
		for _, enemy in ipairs(enemiesAround) do
			if enemy then
				if not Entity.IsDormant(enemy) and not NPC.IsIllusion(enemy) and not NPC.IsStunned(enemy) and not NPC.IsSilenced(enemy) then
					table.insert(enemyTable, enemy)
				end
			end
		end

	if next(enemyTable) == nil then return false end

	local tempTable = {}
	for i = 1, #FAIO_data.preemptiveBKBtable do
		if Menu.IsEnabled(FAIO.preemptiveBKB[i]) then
			table.insert(tempTable, FAIO_data.preemptiveBKBtable[i])
		end
	end

	if next(tempTable) == nil then return false end

	local searchAbility
	for _, enemy in ipairs(enemyTable) do
		for _, ability in ipairs(tempTable) do
			if NPC.HasAbility(enemy, ability) then
				if NPC.GetAbility(enemy, ability) ~= nil and Ability.IsReady(NPC.GetAbility(enemy, ability)) then
					if Ability.GetLevel(NPC.GetAbility(enemy, ability)) > 0 and Ability.GetCooldownTimeLeft(NPC.GetAbility(enemy, ability)) < 1 and not Ability.IsHidden(NPC.GetAbility(enemy, ability)) then
						if dangerousRangeTable[ability] > (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() then
							searchAbility = ability
							break
						end
					end
				end
			end
		end
	end

	if searchAbility ~= nil and #enemyTable >= Menu.GetValue(FAIO_options.optionDefensiveItemsBKBEnemies) then
		return true
	end

	return false

end

function FAIO_utility_functions.shouldCastSatanic(myHero, enemy)

	if not myHero then return end
	if not enemy then return false end
	if Entity.GetHealth(myHero) > Entity.GetMaxHealth(myHero) * 0.3 then return false end

	if enemy then
		if NPC.IsAttacking(myHero) and Entity.GetHealth(enemy) >= Entity.GetMaxHealth(enemy) * 0.25 then
			return true
		end
	end

	return false

end

return FAIO_utility_functions