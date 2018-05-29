FAIO_lion = {}

local Q = nil
local W = nil
local ult = nil

function FAIO_lion.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroLion) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	ult = NPC.GetAbility(myHero, "lion_finger_of_death")

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_lion.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_lion.system(switch, function (continue, wait)
	
			continue(FAIO_lion.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
	
	end

	return

end

function FAIO_lion.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroLionBlink) then
		FAIO_lion.blinkHandler(myHero, enemy, 750, Menu.GetValue(FAIO_options.optionHeroLionBlinkRange), false)
	end

	if FAIO_skillHandler.skillIsReady(W) == true then
		if FAIO_utility_functions.TargetGotDisableModifier(myHero, enemy) == false and FAIO_utility_functions.TargetIsHexed(myHero, enemy) == false then
			local specialBonus = NPC.GetAbility(myHero, "special_bonus_unique_lion_4")
			local specialCheck = false
				if specialBonus and Ability.GetLevel(specialBonus) > 0 then
					specialCheck = true
				end

			if not specialCheck then
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, false) == true then
					FAIO_skillHandler.executeSkillOrder(W, enemy, nil)
					return
				end
			else
				local bestPos = FAIO_utility_functions.getBestPosition(Heroes.InRadius(Entity.GetAbsOrigin(enemy), 620, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY), 310)
				if bestPos ~= nil then
					if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, bestPos, false) == true then
						FAIO_skillHandler.executeSkillOrder(W, enemy, bestPos)
						return
					end
				end
			end
		end
	end

	if FAIO_skillHandler.skillIsReady(Q) == true then
		
		if FAIO_utility_functions.TargetGotDisableModifier(myHero, enemy) == false then
			local check = true
				if FAIO_utility_functions.HexTimeLeft(myHero, enemy) > 0 then
					local timingOffset = ((Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D() - 125) / 1600
					if FAIO_utility_functions.HexTimeLeft(myHero, enemy) > timingOffset + 0.35 then
						check = false
					end
				end	

				if W and Ability.SecondsSinceLastUse(W) > -1 and Ability.SecondsSinceLastUse(W) < 0.25 then
					check = false
				end
			
			if check then
				local pred = 0.3 + (Entity.GetAbsOrigin(enemy):__sub(Entity.GetAbsOrigin(myHero)):Length2D() / 1600) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
				local predPos = FAIO_utility_functions.castLinearPrediction(myHero, enemy, pred)
				if NPC.IsPositionInRange(myHero, predPos, Ability.GetCastRange(Q) + 285, 0) then
					local predPosAdjustedStart = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(50)
					local predPosAdjustedEnd = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(Ability.GetCastRange(Q))
					local fastPoint = Entity.GetAbsOrigin(myHero) + (FAIO_utility_functions.GetClosestPoint(predPosAdjustedStart, predPosAdjustedEnd, Input.GetWorldCursorPos(), segmentClamp) - Entity.GetAbsOrigin(myHero))
					if FAIO_skillHandler.skillIsCastable(Q, Ability.GetCastRange(Q), enemy, fastPoint, false) == true then
						FAIO_skillHandler.executeSkillOrder(Q, enemy, fastPoint)
						Log.Write(os.clock() .. "impale")
						return
					end
				end
			end
		end
	end

	if Menu.IsEnabled(FAIO_options.optionHeroLionUlt) then
		if Menu.GetValue(FAIO_options.optionHeroLionUltStyle) < 1 then
			if FAIO_skillHandler.skillIsCastable(ult, Ability.GetCastRange(ult), enemy, nil, true) == true then
				FAIO_skillHandler.executeSkillOrder(ult, enemy)
				return
			end
		else
			if Menu.IsKeyDown(FAIO_options.optionHeroLionUltKey) then
				if FAIO_skillHandler.skillIsCastable(ult, Ability.GetCastRange(ult), enemy, nil, true) == true then
					FAIO_skillHandler.executeSkillOrder(ult, enemy)
					return
				end
			end
		end
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

return FAIO_lion