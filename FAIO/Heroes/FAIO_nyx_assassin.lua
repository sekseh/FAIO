FAIO_nyx_assassin = {}

local Q = nil
local W = nil

function FAIO_nyx_assassin.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroNyx) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_nyx_assassin.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_nyx_assassin.system(switch, function (continue, wait)
	
			continue(FAIO_nyx_assassin.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
	
	end

	return

end

function FAIO_nyx_assassin.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroNyxBlink) then
		FAIO_nyx_assassin.blinkHandler(myHero, enemy, 500, 100, false)
	end

	if FAIO_skillHandler.skillIsReady(Q) == true then
		local impaleRange = Ability.GetCastRange(Q) - 15
			if NPC.HasModifier(myHero, "modifier_nyx_assassin_burrow") then
				impaleRange = impaleRange + 500
			end
		if FAIO_utility_functions.TargetGotDisableModifier(myHero, enemy) == false then	
			local pred = 0.4 + (Entity.GetAbsOrigin(enemy):__sub(Entity.GetAbsOrigin(myHero)):Length2D() / 1600) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
			local predPos = FAIO_utility_functions.castLinearPrediction(myHero, enemy, pred)
			if NPC.IsPositionInRange(myHero, predPos, impaleRange, 0) then
				local predPosAdjustedStart = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(50)
				local predPosAdjustedEnd = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(impaleRange)
				local fastPoint = Entity.GetAbsOrigin(myHero) + (FAIO_utility_functions.GetClosestPoint(predPosAdjustedStart, predPosAdjustedEnd, Input.GetWorldCursorPos(), segmentClamp) - Entity.GetAbsOrigin(myHero))
				if FAIO_skillHandler.skillIsCastable(Q, impaleRange, enemy, fastPoint, false) == true then
					FAIO_skillHandler.executeSkillOrder(Q, enemy, fastPoint)
					return
				end
			end
		end
	end

	local manaBurnRange = Ability.GetCastRange(W)
		if NPC.HasModifier(myHero, "modifier_nyx_assassin_burrow") then
			manaBurnRange = manaBurnRange + 450
		end

	if FAIO_skillHandler.skillIsCastable(W, manaBurnRange, enemy, nil, false) == true then
		FAIO_skillHandler.executeSkillOrder(W, enemy, nil)
		return
	end

	if not NPC.HasModifier(myHero, "modifier_nyx_assassin_burrow") then
		FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
		return
	end

	return

end

return FAIO_nyx_assassin