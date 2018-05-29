FAIO_chaos_knight = {}

local Q = nil
local W = nil
local ult = nil

function FAIO_chaos_knight.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroCK) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	ult = NPC.GetAbility(myHero, "chaos_knight_phantasm")

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_chaos_knight.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_chaos_knight.system(switch, function (continue, wait)

			continue(FAIO_chaos_knight.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_chaos_knight.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroCKBlink) then
		FAIO_chaos_knight.blinkHandler(myHero, enemy, 700, 100, false)
	end

	if FAIO_skillHandler.skillIsCastable(Q, Ability.GetCastRange(Q), enemy, nil, false) then
		if FAIO_utility_functions.TargetGotDisableModifier(myHero, enemy) == false then
			FAIO_skillHandler.executeSkillOrder(Q, enemy)
			return
		end
	end

	if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, true) then
		FAIO_skillHandler.executeSkillOrder(W, enemy)
		return
	end

	if Menu.IsEnabled(FAIO_options.optionHeroCKUlt) then
		if Menu.GetValue(FAIO_options.optionHeroCKUltStyle) < 1 then
			if FAIO_skillHandler.skillIsCastable(ult, 0, myHero, nil, false) == true then
				if NPC.IsEntityInRange(myHero, enemy, Menu.GetValue(FAIO_options.optionHeroCKUltTrigger)) then
					FAIO_skillHandler.executeSkillOrder(ult, myHero)
					return
				end
			end
		else
			if Menu.IsKeyDown(FAIO_options.optionHeroCKUltKey) then
				if FAIO_skillHandler.skillIsCastable(ult, 0, myHero, nil, false) == true then
					if NPC.IsEntityInRange(myHero, enemy, Menu.GetValue(FAIO_options.optionHeroCKUltTrigger)) then
						FAIO_skillHandler.executeSkillOrder(ult, myHero)
						return
					end
				end
			end
		end
	end	

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

return FAIO_chaos_knight