FAIO_pugna = {}

local Q = nil
local W = nil
local E = nil
local ult = nil

FAIO_pugna.invisDelay = 0

function FAIO_pugna.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroPugna) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	E = NPC.GetAbilityByIndex(myHero, 2)

	ult = NPC.GetAbility(myHero, "pugna_life_drain")

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_pugna.comboExecutionTimer(myHero)
		if ult then
			if Ability.SecondsSinceLastUse(ult) > -1 and Ability.SecondsSinceLastUse(ult) < 0.15 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)) then
				switch = false
			elseif Ability.IsChannelling(ult) then
				switch = false
			end
		end

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then
		FAIO_pugna.system(switch, function (continue, wait)

			continue(FAIO_pugna.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_pugna.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroPugnaBlink) then
		FAIO_pugna.blinkHandler(myHero, enemy, 700, Menu.GetValue(FAIO_options.optionHeroPugnaBlinkRange), false)
	end

	local dagon = NPC.GetItem(myHero, "item_dagon", true)
		if not dagon then
			for i = 2, 5 do
				dagon = NPC.GetItem(myHero, "item_dagon_" .. i, true)
				if dagon then 
					break 
				end
			end
		end

	if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, nil, false) then
		local check = false

			if FAIO_skillHandler.skillIsReady(Q) == true and NPC.IsEntityInRange(myHero, enemy, 585) then
				check = true
			end
			if dagon and FAIO_skillHandler.skillIsCastable(dagon, Ability.GetCastRange(dagon), enemy, nil, true) then
				check = true
			end

			if FAIO_skillHandler.skillIsCastable(ult, Ability.GetCastRange(ult), enemy, nil, false) then
				check = true
			end

		if check then
			FAIO_skillHandler.executeSkillOrder(W, enemy, nil)
			return
		end
	end

	if FAIO_skillHandler.skillIsReady(Q) == true then
		local pred = 1.1 + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
		local predPos = FAIO_utility_functions.castPrediction(myHero, enemy, pred)

		if not NPC.IsPositionInRange(myHero, predPos, Ability.GetCastRange(Q), 0) then
			if NPC.IsPositionInRange(myHero, predPos, Ability.GetCastRange(Q) + 185, 0) then
				predPos = Entity.GetAbsOrigin(myHero) + (predPos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(Ability.GetCastRange(Q) - 10)
			end			
		end

		if FAIO_skillHandler.skillIsCastable(Q, Ability.GetCastRange(Q), enemy, predPos, false) then
			FAIO_skillHandler.executeSkillOrder(Q, enemy, predPos)
			return
		end
	
	end

	if Menu.IsEnabled(FAIO_options.optionHeroPugnaWard) then
		if FAIO_skillHandler.skillIsReady(E) == true then
			if #Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY) >= Menu.GetValue(FAIO_options.optionHeroPugnaWardCount) then
				if FAIO_skillHandler.skillIsCastable(E, Ability.GetCastRange(E), enemy, Entity.GetAbsOrigin(myHero), false) then
					FAIO_skillHandler.executeSkillOrder(E, enemy, Entity.GetAbsOrigin(myHero))
					return
				end
			end
		end
	end

	if FAIO_skillHandler.skillIsReady(ult) == true then
		local check = true

		if Menu.GetValue(FAIO_options.optionItemDagon) > 0 then
			if dagon and FAIO_skillHandler.skillIsCastable(dagon, Ability.GetCastRange(ult), enemy, nil, true) then
				check = false
			end
		end

		if check then
			if FAIO_skillHandler.skillIsCastable(ult, Ability.GetCastRange(ult), enemy, nil, false) then

				if Menu.IsEnabled(FAIO_options.optionHeroPugnaInvis) then
					local glimmer = NPC.GetItem(myHero, "item_glimmer_cape", true)
					local blade = NPC.GetItem(myHero, "item_invis_sword", true)
					local silver = NPC.GetItem(myHero, "item_silver_edge", true)
					if not FAIO_utility_functions.IsHeroInvisible(myHero) and os.clock() > FAIO_pugna.invisDelay then
						if glimmer and Ability.IsCastable(glimmer, myMana) then
							Ability.CastTarget(glimmer, myHero)
							FAIO_pugna.invisDelay = os.clock() + 1
							return
						end

						if blade and Ability.IsCastable(blade, myMana) then
							Ability.CastNoTarget(blade)
							FAIO_pugna.invisDelay = os.clock() + 1
							return
						end

						if silver and Ability.IsCastable(silver, myMana) then
							Ability.CastNoTarget(silver)
							FAIO_pugna.invisDelay = os.clock() + 1
							return
						end
					end
				end

				FAIO_skillHandler.executeSkillOrder(ult, enemy, nil)
				FAIO.mainTick = os.clock() + 0.2
				return
			else
				if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_ATTACK_IMMUNE) then
					if not NPC.IsEntityInRange(myHero, enemy, Ability.GetCastRange(ult)) then
						FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Entity.GetAbsOrigin(enemy))
						return
					end
				end
			end	
		else
			if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_ATTACK_IMMUNE) then
				if not NPC.IsEntityInRange(myHero, enemy, Ability.GetCastRange(ult)) then
					FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Entity.GetAbsOrigin(enemy))
					return
				end
			end
		end	
	end

	if not NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_ATTACK_IMMUNE) then
		FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
		return
	else
		if FAIO_skillHandler.skillIsReady(Q) == true then
			FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Entity.GetAbsOrigin(enemy))
			return
		end
	end

	return

end

return FAIO_pugna