FAIO_witch_doctor = {}

local Q = nil
local E = nil

function FAIO_witch_doctor.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroWD) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	E = NPC.GetAbilityByIndex(myHero, 2)

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_witch_doctor.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_witch_doctor.system(switch, function (continue, wait)

			continue(FAIO_witch_doctor.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_witch_doctor.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroWDBlink) then
		FAIO_witch_doctor.blinkHandler(myHero, enemy, 999, Menu.GetValue(FAIO_options.optionHeroWDBlinkRange), false)
	end
	
	if FAIO_skillHandler.skillIsCastable(Q, Ability.GetCastRange(Q), enemy, nil, false) then
		FAIO_skillHandler.executeSkillOrder(Q, enemy, nil)
		return
	end

	if FAIO_skillHandler.skillIsReady(E) == true then
		local pred = 0.4 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
		local predPos = FAIO_utility_functions.castPrediction(myHero, enemy, pred)
		if FAIO_skillHandler.skillIsCastable(E, Ability.GetCastRange(E), enemy, predPos, false) then
			FAIO_skillHandler.executeSkillOrder(E, enemy, predPos)
			return
		end
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

return FAIO_witch_doctor