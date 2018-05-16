FAIO_attackHandler = {}

FAIO_attackHandler.actionTable = {}
FAIO_attackHandler.mainTick = 0

function FAIO_attackHandler.resetter()

	if not Menu.IsKeyDown(FAIO_options.optionComboKey) then
		if next(FAIO_attackHandler.actionTable) ~= nil then
			FAIO_attackHandler.actionTable = {}
			FAIO_attackHandler.mainTick = 0
		end
	end

end

function FAIO_attackHandler.actionTracker(source, time, order, target, delay)

	if not source then return false end
	if not time then return false end
	if not order then return false end
	if not target then return false end

	local timing = delay
		if timing == nil then
			timing = 0
		end

	if os.clock() < FAIO_attackHandler.mainTick + timing then
		return false
	end

	if FAIO_attackHandler.actionTable[Entity.GetIndex(source)] == nil then return true end

	local index = Entity.GetIndex(source)

	local lastTime = FAIO_attackHandler.actionTable[index]["time"]
	local lastOrder = FAIO_attackHandler.actionTable[index]["order"]
	local lastTarget = FAIO_attackHandler.actionTable[index]["target"]

	if os.clock() < lastTime + timing then
		return false
	end

	if order == "attack" then
		if lastOrder == order and lastTarget == target then
			return false
		end
	end

	if order == "attack move" then
		if lastOrder == order then
			if target ~= nil then
				if (target - lastTarget):Length2D() < 70 then
					return false
				end
			end
		end
	end

	if order == "move" then
		if lastOrder == order then
			if target ~= nil then
				if (target - lastTarget):Length2D() < 70 then
					return false
				end
			end
		end
	end

	return true

end

function FAIO_attackHandler.createActionTable(npc)

	if not npc then return end

	if FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] == nil then
		FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] = { time = 0, order = nil, target = nil, recurring = 0 }
	end

	if FAIO_orbwalker.orbwalkerInAttackAnimation() == true then
		FAIO_attackHandler.actionTable[Entity.GetIndex(npc)]["recurring"] = os.clock()
	end

	if FAIO_orbwalker.orbwalkerIsInAttackBackswing(npc) == true then
		FAIO_attackHandler.actionTable[Entity.GetIndex(npc)]["recurring"] = os.clock()
	end

	if not NPC.IsRunning(npc) and not Entity.IsTurning(npc) then
		if os.clock() > FAIO_attackHandler.actionTable[Entity.GetIndex(npc)]["recurring"] + 0.15 then
			FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] = { time = 0, order = nil, target = nil, recurring = 0 }
		end
	end	

	if FAIO_utility_functions.inSkillAnimation(npc) == true then
		FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] = { time = 0, order = nil, target = nil, recurring = 0 }
	end
			
	return

end

function FAIO_attackHandler.GenericMainAttack(npc, attackType, target, position)
	
	if not npc then return end
	if not target and not position then return end

	FAIO_attackHandler.createActionTable(npc)

	if FAIO_attackHandler.isHeroChannelling(npc) == true then return end
	if FAIO_attackHandler.heroCanCastItems(npc) == false then return end
	if FAIO_utility_functions.inSkillAnimation(npc) == true then return end

	if Menu.IsEnabled(FAIO_options.optionOrbwalkEnable) then
		if target ~= nil then
			if NPC.HasModifier(npc, "modifier_windrunner_focusfire") then
				FAIO_attackHandler.GenericAttackIssuer(attackType, target, position, npc)
			elseif NPC.HasModifier(npc, "modifier_item_hurricane_pike_range") then
				FAIO_attackHandler.GenericAttackIssuer(attackType, target, position, npc)
			else
				if npc == Heroes.GetLocal() then
					FAIO_orbwalker.OrbWalker(npc, target)
				else
					FAIO_attackHandler.GenericAttackIssuer(attackType, target, position, npc)
				end
			end
		else
			FAIO_attackHandler.GenericAttackIssuer(attackType, target, position, npc)
		end
	else
		FAIO_attackHandler.GenericAttackIssuer(attackType, target, position, npc)
	end

end

function FAIO_attackHandler.GenericAttackIssuer(attackType, target, position, npc)

	if not npc then return end
	if not target and not position then return end

	if attackType == "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET" then
		if FAIO_attackHandler.actionTracker(npc, os.clock(), "attack", target, 0.25) == true then
			Player.AttackTarget(Players.GetLocal(), npc, target, false)
			FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] = { time = os.clock(), order = "attack", target = target, recurring = os.clock() }
			FAIO_attackHandler.mainTick = os.clock()
		end
	end

	if attackType == "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE" then
		if FAIO_attackHandler.actionTracker(npc, os.clock(), "attack move", position, 0.25) == true then	
			Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE, target, position, ability, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, npc)
			FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] = { time = os.clock(), order = "attack move", target = position, recurring = os.clock() }
			FAIO_attackHandler.mainTick = os.clock()
		end
	end

	if attackType == "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION" then
		if FAIO_attackHandler.actionTracker(npc, os.clock(), "move", position, 0.125) == true then
			NPC.MoveTo(npc, position, false, true)
			FAIO_attackHandler.actionTable[Entity.GetIndex(npc)] = { time = os.clock(), order = "move", target = position, recurring = os.clock() }
			FAIO_attackHandler.mainTick = os.clock()
		end
	end

end

return FAIO_attackHandler