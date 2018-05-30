FAIO_rattletrap = {}

local Q = nil
local W = nil
local E = nil
local ult = nil

local blademail = nil

local hookshotCheck = false

function FAIO_rattletrap.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroClock) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	E = NPC.GetAbilityByIndex(myHero, 2)
	ult = NPC.GetAbility(myHero, "rattletrap_hookshot")

	blademail = NPC.GetItem(myHero, "item_blade_mail", true)

	local myMana = NPC.GetMana(myHero)
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	local cogsTargeter = 155
		if NPC.IsRunning(enemy) then
			cogsTargeter = 90
		end

	if FAIO_rattletrap.hookshotChecker(myHero, myMana, enemy, ult) == true then
		hookshotCheck = true
	else
		hookshotCheck = false
	end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	local switch = FAIO_rattletrap.comboExecutionTimer(myHero)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then

		FAIO_rattletrap.system(switch, function (continue, wait)

			continue(FAIO_rattletrap.comboExecute(myHero, enemy, myMana, cogsTargeter))
			wait()

		end)()
		
	end

	return

end

function FAIO_rattletrap.comboExecute(myHero, enemy, myMana, cogsTargeter)

	if FAIO_skillHandler.skillIsReady(ult) == true then
		if not NPC.IsEntityInRange(myHero, enemy, cogsTargeter) then
			if hookshotCheck == true then
				local pred = Ability.GetCastPoint(ult) + (Entity.GetAbsOrigin(enemy):__sub(Entity.GetAbsOrigin(myHero)):Length2D() / Ability.GetLevelSpecialValueFor(ult, "speed")) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
				local predPos = FAIO_utility_functions.castPrediction(myHero, enemy, pred)
				if FAIO_skillHandler.skillIsCastable(ult, Ability.GetCastRange(ult), enemy, predPos, false) then
					FAIO_skillHandler.executeSkillOrder(ult, enemy, predPos)
					return
				end
			end
		end
	end

	if FAIO_skillHandler.skillIsCastable(W, cogsTargeter, enemy, nil, false) then
		FAIO_skillHandler.executeSkillOrder(W, enemy)
		return
	end

	if FAIO_skillHandler.skillIsCastable(Q, cogsTargeter, enemy, nil, false) then
		FAIO_skillHandler.executeSkillOrder(Q, myHero)
		return
	end

	if blademail and Ability.IsCastable(blademail, myMana) and NPC.IsEntityInRange(myHero, enemy, cogsTargeter) then
		Ability.CastNoTarget(blademail)
		FAIO_rattletrap.mainTick = os.clock() + 0.055 + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
		return
	end

	if FAIO_skillHandler.skillIsCastable(E, cogsTargeter, enemy, Entity.GetAbsOrigin(enemy), false) then
		FAIO_skillHandler.executeSkillOrder(E, enemy, Entity.GetAbsOrigin(enemy))
		return
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

function FAIO_rattletrap.hookshotChecker(myHero, myMana, enemy, ult)

	if not myHero then return false end
	if not enemy then return false end

	if not ult then return false end
		if FAIO_skillHandler.skillIsReady(ult) == false then return false end

	local latchRadius = 135
	local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D() - 125
		if distance < 75 then return false end
		if distance + 150 > Ability.GetCastRange(ult) then return false end

	for i = 1, math.floor(distance / latchRadius) do
		local checkVec = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Normalized()
		local checkPos = Entity.GetAbsOrigin(myHero) + checkVec:Scaled(i*latchRadius)
		local unitsAround = NPCs.InRadius(checkPos, latchRadius, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_BOTH)
		local check = false
			for _, unit in ipairs(unitsAround) do
				if unit and Entity.IsNPC(unit) and unit ~= enemy and unit ~= myHero and Entity.IsAlive(unit) and not Entity.IsDormant(unit) and not NPC.IsStructure(unit) and not NPC.IsBarracks(unit) and not NPC.IsWaitingToSpawn(unit) and NPC.GetUnitName(unit) ~= "npc_dota_neutral_caster" and NPC.GetUnitName(unit) ~= nil then
					if not NPC.HasModifier(myHero, "modifier_life_stealer_infest_effect") then
						check = true
						break
					else
						if NPC.GetUnitName(unit) ~= "npc_dota_hero_life_stealer" then
							check = true
							break
						end
					end
				end
			end

		if check then
			return false
		end
	end

	return true
			
end

function FAIO_rattletrap.drawings(myHero)

	if not myHero then return end
	if not Menu.IsEnabled(FAIO_options.optionHeroClockDrawIndicator) then return end
	
	if hookshotCheck == false then return end

	local enemy = FAIO_rattletrap.targetChecker(Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY))
		if not enemy then return end
		if not NPC.IsPositionInRange(enemy, Input.GetWorldCursorPos(), 500, 0) then return end

	local pos = Entity.GetAbsOrigin(enemy)
	local posY = NPC.GetHealthBarOffset(enemy)
		pos:SetZ(pos:GetZ() + posY)
			
	local x, y, visible = Renderer.WorldToScreen(pos)

	if visible then
		Renderer.SetDrawColor(50,205,50,255)
		Renderer.DrawText(FAIO_rattletrap.font, x-40, y-80, "hookable", 0)
	end

	return
		
end

return FAIO_rattletrap