FAIO_undying = {}

local Q = nil
local W = nil
local ult = nil

function FAIO_undying.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroUndying) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	ult = NPC.GetAbility(myHero, "undying_flesh_golem")

	local myMana = NPC.GetMana(myHero)

	local switch = FAIO_undying.comboExecutionTimer(myHero)

	if Menu.IsEnabled(FAIO_options.optionHeroUndyingSoulKS) then

		FAIO_undying.system(switch, function (continue, wait)

			continue(FAIO_undying.UndyingSoulKS(myHero, myMana))
			wait()

		end)()

	end

	if Menu.IsEnabled(FAIO_options.optionHeroUndyingSoul) then

		FAIO_undying.system(switch, function (continue, wait)

			continue(FAIO_undying.autoSoulrip(myHero, myMana))
			wait()

		end)()

	end

	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_undying.system(switch, function (continue, wait)

			continue(FAIO_undying.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_undying.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroUndyingBlink) then
		FAIO_undying.blinkHandler(myHero, enemy, 600, 100, false)
	end

	if FAIO_skillHandler.skillIsReady(Q) == true then
		local bestPos = FAIO_utility_functions.getBestPosition(Heroes.InRadius(Entity.GetAbsOrigin(enemy), 620, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY), 310)
		if bestPos ~= nil then
			FAIO_skillHandler.executeSkillOrder(Q, enemy, bestPos)
			return
		end
	end

	if FAIO_skillHandler.skillIsReady(W) == true then	
		local saving = false
		local savingUnit = nil
			if Entity.GetHealth(myHero) / Entity.GetMaxHealth(myHero) < Menu.GetValue(FAIO_options.optionHeroUndyingSoulTreshold) / 100 then
				saving = true
				savingUnit = myHero
			elseif #Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(W) - 10, Enum.TeamType.TEAM_FRIEND) > 0 then
				for _, ally in ipairs(Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(W), Enum.TeamType.TEAM_FRIEND)) do
					if ally and Entity.IsAlive(ally) and not NPC.IsIllusion(ally) then
						if Entity.GetHealth(ally) / Entity.GetMaxHealth(ally) < Menu.GetValue(FAIO_options.optionHeroUndyingSoulTreshold) / 100 then
							saving = true
							savingUnit = ally
						end
					end
				end
			end				
		
		if not saving then
			if #Entity.GetUnitsInRadius(myHero, 1290, Enum.TeamType.TEAM_BOTH) >= Menu.GetValue(FAIO_options.optionHeroUndyingSoulCount) then
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, false) == true then
					FAIO_skillHandler.executeSkillOrder(W, enemy, nil)
					return
				end
			end
		else
			if savingUnit ~= nil then
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), savingUnit, nil, false) == true then
					FAIO_skillHandler.executeSkillOrder(W, savingUnit, nil)
					return
				end	
			end
		end
	end
				
	if Menu.IsEnabled(FAIO_options.optionHeroUndyingUlt) then
		if FAIO_skillHandler.skillIsReady(ult) == true then
			if #Entity.GetHeroesInRadius(myHero, 700, Enum.TeamType.TEAM_BOTH) >= Menu.GetValue(FAIO_options.optionHeroUndyingUltCount) then
				if FAIO_skillHandler.skillIsCastable(ult, 0, myHero, nil, false) then
					if NPC.IsEntityInRange(myHero, enemy, 500) then
						FAIO_skillHandler.executeSkillOrder(ult, myHero, nil)
						return
					end
				end
			end
		end
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

function FAIO_undying.autoSoulrip(myHero, myMana)

	if not myHero then return end

	if FAIO_skillHandler.skillIsReady(W) == true then

		if Entity.GetHealth(myHero) / Entity.GetMaxHealth(myHero) < Menu.GetValue(FAIO_options.optionHeroUndyingSoulTreshold) / 100 then
			if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), myHero, nil, false) == true then
				FAIO_skillHandler.executeSkillOrder(W, myHero, nil)
				return
			end
		end

		if #Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(W), Enum.TeamType.TEAM_FRIEND) > 0 then
			local alliedTarget = nil
			for _, ally in ipairs(Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(W) - 10, Enum.TeamType.TEAM_FRIEND)) do
				if ally and Entity.IsAlive(ally) and not NPC.IsIllusion(ally) then
					if Entity.GetHealth(ally) / Entity.GetMaxHealth(ally) < Menu.GetValue(FAIO_options.optionHeroUndyingSoulTreshold) / 100 then
						alliedTarget = ally
						break
					end	
				end
			end

			if alliedTarget ~= nil then
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), alliedTarget, nil, false) == true then
					FAIO_skillHandler.executeSkillOrder(W, alliedTarget, nil)
					return
				end
			end
		end
	end

	return

end

function FAIO_undying.UndyingSoulKS(myHero, myMana)

	if not myHero then return end

	if not W then return end
		if FAIO_skillHandler.skillIsReady(W) == false then return end

	if FAIO_utility_functions.heroCanCastSpells(myHero, enemy) == false then return end
	if FAIO_utility_functions.isHeroChannelling(myHero) == true then return end
	if FAIO_utility_functions.IsHeroInvisible(myHero) == true then return end

	local damagePerUnit = Ability.GetLevelSpecialValueFor(W, "damage_per_unit")
	local maxUnits = Ability.GetLevelSpecialValueFor(W, "max_units")
	local radius = Ability.GetLevelSpecialValueFor(W, "radius")

	local unitsAround = 0
		for _, v in ipairs(Entity.GetUnitsInRadius(myHero, radius - 25, Enum.TeamType.TEAM_BOTH)) do
			if v and Entity.IsNPC(v) and Entity.IsAlive(v) then
				if Entity.IsSameTeam(myHero, v) then
					unitsAround = unitsAround + 1
				else
					if not NPC.HasState(v, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
						unitsAround = unitsAround + 1
					end
				end
			end
		end

	local adjustedUnitsAround = math.min(unitsAround, maxUnits)

	local damage = adjustedUnitsAround * damagePerUnit

	local killTarget = nil
	for _, targets in ipairs(Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(W) - 10, Enum.TeamType.TEAM_ENEMY)) do
		if targets then
			local target = FAIO.targetChecker(targets)
			if target then
				if not NPC.HasModifier(target, "modifier_templar_assassin_refraction_absorb") then
					local targetHP = Entity.GetHealth(target) + NPC.GetHealthRegen(target)
					local ripTrueDamage = (1 - NPC.GetMagicalArmorValue(target)) * (damage + damage * (Hero.GetIntellectTotal(myHero) / 14 / 100))
					if targetHP < ripTrueDamage then
						if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), target, nil, true) then
							killTarget = target
							break
						end
					end
				end
			end
		end
	end

	if killTarget ~= nil then
		FAIO_skillHandler.executeSkillOrder(W, killTarget, nil)
		return
	end

	return

end

return FAIO_undying