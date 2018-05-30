FAIO_shadow_shaman = {}

local Q = nil
local W = nil
local E = nil				

function FAIO_shadow_shaman.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroSS) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
	W = NPC.GetAbilityByIndex(myHero, 1)
 	E = NPC.GetAbilityByIndex(myHero, 2)

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_shadow_shaman.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_shadow_shaman.system(switch, function (continue, wait)

			continue(FAIO_shadow_shaman.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_shadow_shaman.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroSSBlink) then
		FAIO_shadow_shaman.blinkHandler(myHero, enemy, 999, Menu.GetValue(FAIO_options.optionHeroSSBlinkRange), false)
	end

	if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, false) then
		FAIO_skillHandler.executeSkillOrder(W, enemy)
		return
	end

	if FAIO_skillHandler.skillIsReady(Q) == true then
		local shockRange = Ability.GetCastRange(Q)
			if Menu.IsEnabled(FAIO_options.optionHeroSSForceHex) then
				if FAIO_skillHandler.skillIsReady(Q) == true then
					shockRange = shockRange - 105
				end
			end
		if FAIO_skillHandler.skillIsCastable(Q, shockRange, enemy, nil, false) then
			FAIO_skillHandler.executeSkillOrder(Q, enemy)
			return
		end
	end

	if FAIO_skillHandler.skillIsReady(E) == true then
		if FAIO_utility_functions.TargetGotDisableModifier(myHero, enemy) == false then
			local check = true
				if FAIO_utility_functions.HexTimeLeft(myHero, enemy) > 0 then
					local timingOffset = ((Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D() - 125) / 1600
					if FAIO_utility_functions.HexTimeLeft(myHero, enemy) > 0.45 then
						check = false
					end
				end	

				if W and Ability.SecondsSinceLastUse(W) > -1 and Ability.SecondsSinceLastUse(W) < 0.25 then
					check = false
				end
		
			if check then
				if FAIO_skillHandler.skillIsCastable(E, Ability.GetCastRange(E), enemy, nil, false) then
					FAIO_skillHandler.executeSkillOrder(E, enemy)
					return
				end
			end
		end
	end	

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

return FAIO_shadow_shaman