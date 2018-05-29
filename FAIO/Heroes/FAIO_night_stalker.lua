FAIO_night_stalker = {}

local Q = nil
local W = nil

function FAIO_night_stalker.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroNS) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_night_stalker.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_night_stalker.system(switch, function (continue, wait)

			continue(FAIO_night_stalker.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_night_stalker.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroNSBlink) then
		FAIO_night_stalker.blinkHandler(myHero, enemy, 600, 100, false)
	end

	if FAIO_skillHandler.skillIsCastable(Q, Ability.GetCastRange(Q), enemy, nil, false) then
		FAIO_skillHandler.executeSkillOrder(Q, enemy)
		return
	end

	if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, true) then
		if FAIO_utility_functions.TargetIsStunnedOrSilenced(myHero, enemy) == false then
			FAIO_skillHandler.executeSkillOrder(W, enemy)
			return
		end
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

return FAIO_night_stalker