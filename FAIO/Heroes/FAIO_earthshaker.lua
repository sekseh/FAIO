FAIO_earthshaker = {}

local Q = nil
local W = nil
local ult = nil

function FAIO_earthshaker.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroEarthshaker) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
	W = NPC.GetAbilityByIndex(myHero, 1)
	ult = NPC.GetAbility(myHero, "earthshaker_echo_slam")

	local myMana = NPC.GetMana(myHero)

	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end
	
	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_earthshaker.comboExecutionTimer(myHero)

	local aftershockRange = 260
		if NPC.IsRunning(enemy) then
			if not NPC.HasItem(myHero, "item_blink", true) then
				aftershockRange = aftershockRange - 100
			else
				if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_blink", true)) > 0.75 then
					aftershockRange = aftershockRange - 100
				end
			end	
		end

	local initiationRange = 280
		if FAIO_skillHandler.skillIsReady(Q) == true then
			initiationRange = 500
		end
		if Q and Ability.SecondsSinceLastUse(Q) > -1 and Ability.SecondsSinceLastUse(Q) < (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D() / NPC.GetMoveSpeed(myHero) + 0.25 then
			initiationRange = 99999
		end	


	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_earthshaker.system(switch, function (continue, wait)

			continue(FAIO_earthshaker.comboExecute(myHero, enemy, myMana, aftershockRange, initiationRange)	)
			wait()

		end)()
	
	end

	return

end

function FAIO_earthshaker.comboExecute(myHero, enemy, myMana, aftershockRange, initiationRange)

	local aghanimsBuffed = false
		if NPC.HasItem(myHero, "item_ultimate_scepter", true) or NPC.HasModifier(myHero, "modifier_item_ultimate_scepter_consumed") then
			aghanimsBuffed = true
		end

	local check = true
		if aghanimsBuffed then
			if FAIO_skillHandler.skillIsReady(W) then
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, false) then
					check = false
				end
			end
			if W and Ability.SecondsSinceLastUse(W) > -1 and Ability.SecondsSinceLastUse(W) < 1 + 0.05 then
				check = false
			end
		end		

	if Menu.IsEnabled(FAIO_options.optionHeroEarthshakerBlink) then
		if check then
			if Menu.GetValue(FAIO_options.optionHeroEarthshakerBlinkStyle) < 1 then
				FAIO_earthshaker.blinkHandler(myHero, enemy, initiationRange, 0, false)
			else
				FAIO_earthshaker.blinkHandler(myHero, enemy, initiationRange, 0, true, aftershockRange)
			end
		end
	end

	if FAIO_skillHandler.skillIsReady(W) then
		if aghanimsBuffed then
			local bestPos = FAIO_utility_functions.getBestPosition(Heroes.InRadius(Entity.GetAbsOrigin(enemy), 560, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY), aftershockRange)
			if bestPos ~= nil then
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, bestPos, false) == true then
					if (bestPos - Entity.GetAbsOrigin(myHero)):Length2D() > aftershockRange then
						Ability.CastPosition(W, bestPos)
						FAIO_earthshaker.mainTick = os.clock() + 0.055 + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) + FAIO_earthshaker.humanizerMouseDelayCalc(bestPos) + FAIO_utility_functions.TimeToFacePosition(myHero, bestPos) + 1
						return
					else
						Ability.CastTarget(W, myHero)
						FAIO_earthshaker.mainTick = os.clock() + 0.055 + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) + FAIO_earthshaker.humanizerMouseDelayCalc(Entity.GetAbsOrigin(myHero))
						return
					end
				end
			end
		else
			if FAIO_skillHandler.skillIsCastable(W, aftershockRange, enemy, nil, false) == true then
				FAIO_skillHandler.executeSkillOrder(W)
				return
			end
		end
	end

	if Menu.IsEnabled(FAIO_options.optionHeroEarthshakerUlt) then
		local check = true
			if Menu.GetValue(FAIO_options.optionHeroEarthshakerUltTiming) > 0 then
				if W and Ability.SecondsSinceLastUse(W) > -1 and Ability.SecondsSinceLastUse(W) < 0.15 then
					check = false
				end
				if FAIO_utility_functions.TargetDisableTimer(myHero, enemy) - GameRules.GetGameTime() > 0.15 then
					check = false
				end
				if NPC.HasItem(myHero, "item_refresher", true) then
					local refresher = NPC.GetItem(myHero, "item_refresher", true)
					if Ability.SecondsSinceLastUse(refresher) > -1 and Ability.SecondsSinceLastUse(refresher) < 0.15 then
						check = false
					end
				end	
			end
			if Menu.GetValue(FAIO_options.optionHeroEarthshakerUltStyle) < 1 then
				if FAIO_earthshaker.calculateEchoSlamInstances(myHero, enemy) < Menu.GetValue(FAIO_options.optionHeroEarthshakerUltEchoes) then
					check = false
				end
			else
				if FAIO_earthshaker.calculateEchoSlamInstances(myHero, enemy) < 2 then
					check = false
				end
			end		
					
		if check and FAIO_skillHandler.skillIsReady(ult) == true then
			if Menu.GetValue(FAIO_options.optionHeroEarthshakerUltStyle) < 1 then
				if FAIO_skillHandler.skillIsCastable(ult, aftershockRange, enemy, nil, false) == true then
					FAIO_skillHandler.executeSkillOrder(ult, enemy)
					return
				end
			else
				if Menu.IsKeyDown(FAIO_options.optionHeroEarthshakerUltKey) then
					if FAIO_skillHandler.skillIsCastable(ult, aftershockRange, enemy, nil, false) == true then
						FAIO_skillHandler.executeSkillOrder(ult, enemy)
						return
					end
				end
			end
		end
	end

	if FAIO_skillHandler.skillIsReady(Q) == true then

		local fissureRange = Ability.GetCastRange(Q) - 10
			if NPC.HasItem(myHero, "item_blink") and Ability.IsReady(NPC.GetItem(myHero, "item_blink")) then
				fissureRange = initiationRange + 1
			end

		local check = false
			if W and Ability.SecondsSinceLastUse(W) > -1 and Ability.SecondsSinceLastUse(W) < 0.15 then
				check = true
			end
			if ult then
				if Ability.SecondsSinceLastUse(ult) > -1 and Ability.SecondsSinceLastUse(ult) < 0.15 then
					check = true
				end
				if Menu.IsEnabled(FAIO_options.optionHeroEarthshakerUlt) and (Menu.GetValue(FAIO_options.optionHeroEarthshakerUltStyle) < 1 or (Menu.GetValue(FAIO_options.optionHeroEarthshakerUltStyle) == 1 and Menu.IsKeyDown(FAIO_options.optionHeroEarthshakerUltKey))) then
					if FAIO_skillHandler.skillIsCastable(ult, aftershockRange, enemy, nil, false) == true and FAIO_earthshaker.calculateEchoSlamInstances(myHero, enemy) >= Menu.GetValue(FAIO_options.optionHeroEarthshakerUltEchoes) then
						check = true
					end
				end
			end	

		if not check and FAIO_utility_functions.TargetDisableTimer(myHero, enemy) - GameRules.GetGameTime() < 0.85 then	
			local pred = 0.69 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
			local predPos = FAIO_utility_functions.castPrediction(myHero, enemy, pred)
			if NPC.IsPositionInRange(myHero, predPos, Ability.GetCastRange(Q) - 100, 0) then
				local predPosAdjustedStart = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(50)
				local predPosAdjustedEnd = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(Ability.GetCastRange(Q) - 25)
				local fastPoint = Entity.GetAbsOrigin(myHero) + (FAIO_utility_functions.GetClosestPoint(predPosAdjustedStart, predPosAdjustedEnd, Input.GetWorldCursorPos(), segmentClamp) - Entity.GetAbsOrigin(myHero))
				if FAIO_skillHandler.skillIsCastable(Q, fissureRange, enemy, fastPoint, false) == true then
					FAIO_skillHandler.executeSkillOrder(Q, enemy, fastPoint)
					return
				end
			end
		end
	end

	if Menu.IsEnabled(FAIO_options.optionHeroEarthshakerRefresher) then
		local refresher = NPC.GetItem(myHero, "item_refresher", true)
		if refresher and Ability.IsCastable(refresher, myMana) then
			if ult and Ability.SecondsSinceLastUse(ult) > 0.15 and Ability.SecondsSinceLastUse(ult) < 2.15 and FAIO_skillHandler.skillIsReady(Q) == false then
				if myMana > Ability.GetManaCost(refresher) + Ability.GetManaCost(ult) then
					if FAIO_earthshaker.calculateEchoSlamInstances(myHero, enemy) >= Menu.GetValue(FAIO_options.optionHeroEarthshakerUltEchoes) then
						Ability.CastNoTarget(refresher)
						FAIO_earthshaker.mainTick = os.clock() + 0.055 + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
						return
					end
				end
			end
		end
	end		
		
	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

function FAIO_earthshaker.calculateEchoSlamInstances(myHero, enemy)

	if not myHero then return 0 end
	if not enemy then return 0 end

	local enemyIndex = Entity.GetIndex(enemy)

	local enemyTable = Entity.GetHeroesInRadius(myHero, 1150, Enum.TeamType.TEAM_ENEMY)
	local tempEnemyTable = {}
		for _, target in ipairs(enemyTable) do
			if target and Entity.IsHero(target) and not Entity.IsDormant(target) and Entity.IsAlive(target) and not NPC.IsIllusion(target) then
				if tempEnemyTable[target] == nil then
					tempEnemyTable[target] = 0
				end
			else
				if tempEnemyTable[target] ~= nil then
					tempEnemyTable[target] = nil
				end
			end
		end

		if next(enemyTable) == nil then
			tempEnemyTable = {}
		end

	local unitTable = Entity.GetUnitsInRadius(myHero, 575, Enum.TeamType.TEAM_ENEMY)
	local tempUnitTable = {}
		for i, target in ipairs(unitTable) do
			if target and Entity.IsNPC(target) and not Entity.IsDormant(target) and Entity.IsAlive(target) and not NPC.IsWaitingToSpawn(target) and NPC.GetUnitName(target) ~= "npc_dota_neutral_caster" then
				if FAIO_utility_functions.utilityIsInTable(tempUnitTable, target) == false then
					table.insert(tempUnitTable, target)
				end
			else
				if tempTable[i] ~= nil then
					table.insert(tempUnitTable, i)
				end
			end
		end

		if next(unitTable) == nil then
			tempUnitTable = {}
		end

	for i, v in ipairs(tempUnitTable) do
		if v and Entity.IsHero(v) and not NPC.IsIllusion(v) then
			for k, l in pairs(tempEnemyTable) do
				if k and Entity.IsHero(k) and v ~= k and NPC.IsEntityInRange(v, k, 575) then
					tempEnemyTable[k] = tempEnemyTable[k] + 2
				end
			end
		else
			for k, l in pairs(tempEnemyTable) do
				if k and Entity.IsNPC(k) and v ~= k and NPC.IsEntityInRange(v, k, 575) then
					tempEnemyTable[k] = tempEnemyTable[k] + 1
				end
			end
		end
	end

	if tempEnemyTable[enemy] ~= nil then
		return tempEnemyTable[enemy]
	end		

	return 0

end

return FAIO_earthshaker