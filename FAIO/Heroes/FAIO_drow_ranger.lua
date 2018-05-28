FAIO_drow_ranger = {}

local Q = nil
local W = nil
local E = nil

FAIO_drow_ranger.harassTicker = 0

function FAIO_drow_ranger.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroDrow) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	E = NPC.GetAbilityByIndex(myHero, 2)

	local myMana = NPC.GetMana(myHero)

	if Menu.IsEnabled(FAIO_options.optionHeroDrowHarass) then
		if Menu.IsKeyDown(FAIO_options.optionHeroDrowHarassKey) then
			FAIO_drow_ranger.DrowAutoHarass(myHero, myMana)
		end
	end
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_drow_ranger.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then
		FAIO_drow_ranger.system(switch, function (continue, wait)

			continue(FAIO_drow_ranger.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_drow_ranger.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroDrowBlink) then
		FAIO_drow_ranger.blinkHandler(myHero, enemy, 900, Menu.GetValue(FAIO_options.optionHeroDrowBlinkRange), false)
	end

	if Menu.IsEnabled(FAIO_options.optionHeroDrowGust) then
		if Menu.GetValue(FAIO_options.optionHeroDrowGustMode) > 0 then
			local pred = 0.25 + ((Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D() / 2000) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
			local predPos = FAIO_utility_functions.castPrediction(myHero, enemy, pred)
			if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), enemy, predPos, false) then
				if not NPC.IsSilenced(enemy) and FAIO_utility_functions.TargetDisableTimer(myHero, enemy) <= 0 then
					FAIO_skillHandler.executeSkillOrder(W, enemy, predPos)
					FAIO_itemHandler.lastDefItemPop = os.clock()
					return
				end
			end
		else	

			local check = false
			local target = nil
			if FAIO_skillHandler.skillIsReady(W) == true then
				for _, v in ipairs(Entity.GetHeroesInRadius(myHero, 400, Enum.TeamType.TEAM_ENEMY)) do
					if v and Entity.IsHero(v) and not Entity.IsDormant(v) and not NPC.IsIllusion(v) then
						if NPC.IsAttacking(v) then
							if NPC.IsEntityInRange(myHero, v, NPC.GetAttackRange(v) + 140) then
								if NPC.FindFacingNPC(v) == myHero then
									if enemy then
										if NPC.IsEntityInRange(myHero, enemy, 400) then
											check = true
											target = enemy
											break
										else
											if NPC.IsEntityInRange(myHero, v, 400) then
												check = true
												target = v
												break
											end
										end
									else
										if NPC.IsEntityInRange(myHero, v, 400) then
											check = true
											target = v
											break
										end
									end	
								end
							end
						end
						for ability, info in pairs(FAIO_data.RawDamageAbilityEstimation) do
							if NPC.HasAbility(v, ability) and Ability.IsInAbilityPhase(NPC.GetAbility(v, ability)) then
								local abilityRange = math.max(Ability.GetCastRange(NPC.GetAbility(v, ability)), info[2])
								local abilityRadius = info[3]
								if FAIO_dodgeIT.dodgeIsTargetMe(myHero, v, abilityRadius, abilityRange) then
									if next(FAIO_dodgeIT.dodgeItTable) == nil then
										if enemy then
											if NPC.IsEntityInRange(myHero, enemy, 400) then
												check = true
												target = enemy
												break
											end
										else
											if NPC.IsEntityInRange(myHero, v, 400) then
												check = true
												target = v
												break
											end
										end
									end
								end
							end
						end
					end	
				end
			end

			if check and target then
				local pred = 0.25 + ((Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(target)):Length2D() / 2000) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
				local predPos = FAIO_utility_functions.castPrediction(myHero, target, pred)
				if FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(W), target, predPos, false) then
					if not NPC.IsSilenced(target) and FAIO_utility_functions.TargetDisableTimer(myHero, target) == 0 then
						FAIO_skillHandler.executeSkillOrder(W, enemy, predPos)
						FAIO_itemHandler.lastDefItemPop = os.clock()
						return
					end
				end
			end
		end
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

function FAIO_drow_ranger.DrowAutoHarass(myHero, myMana)

	if not myHero then return end

	if not Q then return end
		if Ability.GetLevel(Q) < 1 then return end

	if FAIO_utility_functions.heroCanCastSpells(myHero, enemy) == false then return end
	if FAIO_utility_functions.isHeroChannelling(myHero) == true then return end 
	if FAIO_utility_functions.IsHeroInvisible(myHero) == true then return end

	local harassTarget = nil
		for _, hero in ipairs(NPC.GetHeroesInRadius(myHero, NPC.GetAttackRange(myHero), Enum.TeamType.TEAM_ENEMY)) do
			if hero and Entity.IsHero(hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) then 
				if Entity.IsAlive(hero) and not NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
        				harassTarget = hero
					break
				end
      			end			
		end

	local mousePos = Input.GetWorldCursorPos()
	if harassTarget ~= nil then
		if FAIO_orbwalker.orbwalkerIsInAttackBackswing(myHero) == false then
			if FAIO_orbwalker.orbwalkerInAttackAnimation() == false and Ability.IsCastable(Q, myMana) then
				if os.clock() > FAIO_drow_ranger.harassTicker then
					Ability.CastTarget(Q, harassTarget)
					FAIO_drow_ranger.harassTicker = os.clock() + 0.2
					return
				end
			end
		else
			if not NPC.IsPositionInRange(myHero, mousePos, 50, 0) then
				FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, mousePos)
				return
			end
		end
	else
		if not NPC.IsPositionInRange(myHero, mousePos, 50, 0) then
			FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, mousePos)
			return
		end
	end

	return

end

return FAIO_drow_ranger