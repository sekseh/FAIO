FAIO_disruptor = {}

FAIO_disruptor.glimpsePositionTable = {}

FAIO_disruptor.glimpseParticle = 0
FAIO_disruptor.glimpseParticleTarget = nil

FAIO_disruptor.stormImage = 0
FAIO_disruptor.glimpseImage = 0
FAIO_disruptor.fieldImage = 0

local Q = nil
local W = nil
local E = nil
local ult = nil

local glimpseCheck = true
local glimpseTarget = nil

function FAIO_disruptor.combo(myHero, enemy)

	if not Menu.IsEnabled(FAIO_options.optionHeroDisruptor) then return end

	Q = NPC.GetAbilityByIndex(myHero, 0)
 	W = NPC.GetAbilityByIndex(myHero, 1)
	E = NPC.GetAbilityByIndex(myHero, 2)
	ult = NPC.GetAbility(myHero, "disruptor_static_storm")

	local myMana = NPC.GetMana(myHero)

	FAIO_disruptor.trackGlimpsePos(myHero)
	FAIO_disruptor.drawGlimpseParticle(myHero)
	glimpseTarget = FAIO_disruptor.getComboTarget(myHero)
	FAIO_disruptor.glimpseCheck(myHero, myMana)

	local switch = FAIO_disruptor.comboExecutionTimer(myHero)

	if Menu.IsEnabled(FAIO_options.optionHeroDisruptorGlimpseCombo) then
		if Menu.IsKeyDown(FAIO_options.optionHeroDisruptorGlimpseComboKey) then

			FAIO_disruptor.system(switch, function (continue, wait)

				continue(FAIO_disruptor.glimpseCombo(myHero, myMana))
				wait()

			end)()
			
		end
	end

	if Menu.IsEnabled(FAIO_options.optionHeroDisruptorUltCombo) then
		if Menu.IsKeyDown(FAIO_options.optionHeroDisruptorUltComboKey) then

			FAIO_disruptor.system(switch, function (continue, wait)

				continue(FAIO_disruptor.ultCombo(myHero, myMana))
				wait()

			end)()

			
		end
	end		
	
	if not enemy then return end
	if not NPC.IsEntityInRange(myHero, enemy, 3000)	then return end

	FAIO_itemHandler.itemUsage(myHero, enemy)

	if Menu.IsKeyDown(FAIO_options.optionComboKey) and Entity.IsAlive(enemy) then
		FAIO_disruptor.system(switch, function (continue, wait)

			continue(FAIO_disruptor.comboExecute(myHero, enemy, myMana))
			wait()

		end)()
		
	end

	return

end

function FAIO_disruptor.comboExecute(myHero, enemy, myMana)

	if Menu.IsEnabled(FAIO_options.optionHeroDisruptorBlink) then
		FAIO_disruptor.blinkHandler(myHero, enemy, 900, Menu.GetValue(FAIO_options.optionHeroDisruptorBlinkRange), false)
	end
		
	if FAIO_skillHandler.skillIsCastable(Q, Ability.GetCastRange(Q), enemy, nil, false) then
		FAIO_skillHandler.executeSkillOrder(Q, enemy, nil)
		return
	end

	FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET", enemy, nil)
	return

end

function FAIO_disruptor.glimpseCombo(myHero, myMana)

	if not myHero then return end
			
	if not glimpseCheck then
		if Menu.IsEnabled(FAIO_options.optionHeroDisruptorGlimpseComboMove) then
			if not Menu.IsEnabled(FAIO_options.optionHeroDisruptorGlimpseComboMoveDis) then
				FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Input.GetWorldCursorPos())
				return
			else
				if FAIO_skillHandler.skillIsReady(W) == true then
					FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Input.GetWorldCursorPos())
					return
				end
			end
		end
	else
		if glimpseTarget then
			local index = Entity.GetIndex(glimpseTarget)
			local glimpsePos = nil
				if FAIO_disruptor.glimpsePositionTable[index] ~= nil then
					local glimpseTime = math.floor(os.clock() * 10) / 10 - 4
					if FAIO_disruptor.glimpsePositionTable[index][glimpseTime] ~= nil then
						glimpsePos = FAIO_disruptor.glimpsePositionTable[index][glimpseTime]
					end
				end

			if glimpsePos ~= nil then
				local fieldAdjustmentPos = glimpsePos
					if not NPC.IsPositionInRange(myHero, fieldAdjustmentPos, Ability.GetCastRange(E), 0) then
						fieldAdjustmentPos = Entity.GetAbsOrigin(myHero) + (glimpsePos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(Ability.GetCastRange(E) - 10)
					end
				FAIO_skillHandler.executeSkillOrder(E, glimpseTarget, fieldAdjustmentPos)
				FAIO_skillHandler.executeSkillOrder(W, glimpseTarget, nil)
				return
			end
		end
	end
		
	return

end

function FAIO_disruptor.ultCombo(myHero, myMana)

	if not myHero then return end
	if not ult then return end

	local glimpsePos = nil
		if glimpseTarget then
			local index = Entity.GetIndex(glimpseTarget)
			if FAIO_disruptor.glimpsePositionTable[index] ~= nil then
				local glimpseTime = math.floor(os.clock() * 10) / 10 - 4
				if FAIO_disruptor.glimpsePositionTable[index][glimpseTime] ~= nil then
					glimpsePos = FAIO_disruptor.glimpsePositionTable[index][glimpseTime]
				end
			end
		end

	local check = glimpseCheck
		if check == true then
			if FAIO_skillHandler.skillIsReady(ult) == false and Ability.SecondsSinceLastUse(ult) > 1 then
				check = false
			end
			if not NPC.IsPositionInRange(myHero, glimpsePos, Ability.GetCastRange(ult) + 175, 0) then
				check = false
			end
			if myMana < Ability.GetManaCost(W) + Ability.GetManaCost(E) + Ability.GetManaCost(ult) then
				check = false
			end
		end

		if W and E then
			if Ability.SecondsSinceLastUse(E) > -1 and Ability.SecondsSinceLastUse(E) < 1.5 then
				if Ability.SecondsSinceLastUse(ult) < 0 then
					check = true
				end
			end
		end

	if not check then
		if Menu.IsEnabled(FAIO_options.optionHeroDisruptorGlimpseComboMove) then
			if not Menu.IsEnabled(FAIO_options.optionHeroDisruptorUltComboMoveDis) then
				FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Input.GetWorldCursorPos())
				return
			else
				if FAIO_skillHandler.skillIsReady(ult) == true then
					FAIO_attackHandler.GenericMainAttack(myHero, "Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION", nil, Input.GetWorldCursorPos())
					return
				end
			end	
		end
	else
		if glimpseTarget then
			if glimpsePos ~= nil then
				local fieldAdjustmentPos = glimpsePos
					if not NPC.IsPositionInRange(myHero, fieldAdjustmentPos, Ability.GetCastRange(ult), 0) then
						fieldAdjustmentPos = Entity.GetAbsOrigin(myHero) + (glimpsePos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(Ability.GetCastRange(ult) - 10)
					end
				FAIO_skillHandler.executeSkillOrder(E, glimpseTarget, fieldAdjustmentPos)
				FAIO_skillHandler.executeSkillOrder(W, glimpseTarget, nil)
				FAIO_skillHandler.executeSkillOrder(ult, glimpseTarget, fieldAdjustmentPos)
				return
			end
		end
	end
		
	return

end

function FAIO_disruptor.glimpseCheck(myHero, myMana)

	if not myHero then
		glimpseCheck = false
		return 
	end
	if not W then
		glimpseCheck = false
		return
	end
	if not E then
		glimpseCheck = false
		return
	end

		if FAIO_skillHandler.skillIsReady(W) == false and Ability.SecondsSinceLastUse(W) > 1 then
			glimpseCheck = false
			return
		elseif FAIO_skillHandler.skillIsReady(E) == false and Ability.SecondsSinceLastUse(E) > 1 then
			glimpseCheck = false
			return
		end

		if myMana < Ability.GetManaCost(W) + Ability.GetManaCost(E) then
			glimpseCheck = false
			return
		end

	local target = glimpseTarget
		if target == nil then
			glimpseCheck = false
			return
		elseif FAIO_skillHandler.skillIsCastable(W, Ability.GetCastRange(E) + 175, target, nil, true) == false then
			glimpseCheck = false
			return
		elseif not NPC.IsEntityInRange(myHero, target, Ability.GetCastRange(W)) then
			glimpseCheck = false
			return
		end

	local glimpsePos = nil
		if target then
			local index = Entity.GetIndex(target)
			if FAIO_disruptor.glimpsePositionTable[index] ~= nil then
				local glimpseTime = math.floor(os.clock() * 10) / 10 - 4
				if FAIO_disruptor.glimpsePositionTable[index][glimpseTime] ~= nil then
					glimpsePos = FAIO_disruptor.glimpsePositionTable[index][glimpseTime]
				end
			end
		end

		if glimpsePos == nil then
			glimpseCheck = false
			return
		elseif not NPC.IsPositionInRange(myHero, glimpsePos, Ability.GetCastRange(E) + 175, 0) then
			glimpseCheck = false
			return
		end	 

	local glimpseTiming = 1.8
		if target and glimpsePos then
			local distCurToBacktrack = (Entity.GetAbsOrigin(target) - glimpsePos):Length2D()
			local flyTime = math.min((distCurToBacktrack / 600), 1.8)
			if flyTime < 1.8 then
				glimpseTiming = flyTime
			end
		end

	glimpseCheck = true
	return

end

function FAIO_disruptor.trackGlimpsePos(myHero)

	if not myHero then return end

	if not W then return end
		if Ability.GetLevel(W) < 1 then return end

	local glimpseRange = Ability.GetCastRange(W)

	for i = 1, Heroes.Count() do
		local hero = Heroes.Get(i)
		local heroPos = Entity.GetAbsOrigin(hero)

		if not Entity.IsAlive(hero) then
			if FAIO_disruptor.glimpsePositionTable[Entity.GetIndex(hero)] ~= nil then
				FAIO_disruptor.glimpsePositionTable[Entity.GetIndex(hero)] = nil
			end
		end
		
		if Entity.IsHero(hero) and not Entity.IsDormant(hero) and not Entity.IsSameTeam(myHero, hero) and Entity.IsAlive(hero) and not NPC.IsIllusion(hero) and NPC.IsEntityInRange(myHero, hero, (glimpseRange * 2)) then
			if FAIO_disruptor.glimpsePositionTable[Entity.GetIndex(hero)] == nil then
				FAIO_disruptor.glimpsePositionTable[Entity.GetIndex(hero)] = {}
			end

			if FAIO_disruptor.glimpsePositionTable[Entity.GetIndex(hero)][math.floor(os.clock() * 10) / 10] == nil then
				FAIO_disruptor.glimpsePositionTable[Entity.GetIndex(hero)][math.floor(os.clock() * 10) / 10] = heroPos
			end
		end

	end
			
	for i, v in pairs(FAIO_disruptor.glimpsePositionTable) do
		for k, l in pairs(v) do
			if math.floor(os.clock() * 10) / 10 - k >= 5 then
				FAIO_disruptor.glimpsePositionTable[i][k] = nil
			end
		end
		if next(v) == nil then
			FAIO_disruptor.glimpsePositionTable[i] = nil
		end	
	end

	return

end

function FAIO_disruptor.drawGlimpseParticle(myHero)

	if not myHero then return end

	if not Menu.IsEnabled(FAIO_options.optionHeroDisruptorGlimpseParticle) then
		if FAIO_disruptor.glimpseParticle > 0 then
			Particle.Destroy(FAIO_disruptor.glimpseParticle)
			FAIO_disruptor.glimpseParticle = 0
			FAIO_disruptor.glimpseParticleTarget = nil
			return
		else
			return
		end
	end

	if FAIO_skillHandler.skillIsReady(W) == false then
		if FAIO_disruptor.glimpseParticle > 0 then
			Particle.Destroy(FAIO_disruptor.glimpseParticle)
			FAIO_disruptor.glimpseParticle = 0
			FAIO_disruptor.glimpseParticleTarget = nil
			return
		else
			return
		end
	end

	local target = glimpseTarget
	
	if target then
		local index = Entity.GetIndex(target)
		if FAIO_disruptor.glimpsePositionTable[index] ~= nil then
			local glimpsePos = nil
				if FAIO_disruptor.glimpsePositionTable[index] ~= nil then
					local glimpseTime = math.floor(os.clock() * 10) / 10 - 4
					if FAIO_disruptor.glimpsePositionTable[index][glimpseTime] ~= nil then
						glimpsePos = FAIO_disruptor.glimpsePositionTable[index][glimpseTime]
					end
				end

			if glimpsePos ~= nil then
				if FAIO_disruptor.glimpseParticle == 0 then

					local glimpseParticle = Particle.Create("particles/ui_mouseactions/range_finder_targeted_aoe_rings.vpcf", Enum.ParticleAttachment.PATTACH_WORLDORIGIN, glimpsePos)
				
					FAIO_disruptor.glimpseParticle = glimpseParticle
					FAIO_disruptor.glimpseParticleTarget = target
					Particle.SetControlPoint(FAIO_disruptor.glimpseParticle, 2, glimpsePos)

				else

					Particle.SetControlPoint(FAIO_disruptor.glimpseParticle, 2, glimpsePos)

					if target ~= FAIO_disruptor.glimpseParticleTarget then
						Particle.Destroy(FAIO_disruptor.glimpseParticle)
						FAIO_disruptor.glimpseParticle = 0
						FAIO_disruptor.glimpseParticleTarget = nil

					end

				end
			else
				if FAIO_disruptor.glimpseParticle > 0 then
					Particle.Destroy(FAIO_disruptor.glimpseParticle)
					FAIO_disruptor.glimpseParticle = 0
					FAIO_disruptor.glimpseParticleTarget = nil
				end
			end
		else
			if FAIO_disruptor.glimpseParticle > 0 then
				Particle.Destroy(FAIO_disruptor.glimpseParticle)
				FAIO_disruptor.glimpseParticle = 0
				FAIO_disruptor.glimpseParticleTarget = nil
			end
		end
	else
		if FAIO_disruptor.glimpseParticle > 0 then
			Particle.Destroy(FAIO_disruptor.glimpseParticle)
			FAIO_disruptor.glimpseParticle = 0
			FAIO_disruptor.glimpseParticleTarget = nil
		end
	end

	return

end

function FAIO_disruptor.drawings(myHero)

	if not Menu.IsEnabled(FAIO_options.optionHeroDisruptorComboIndicator) then return end

	if not myHero then return end

	local imageHandleStorm = 0
	if FAIO_disruptor.stormImage > 0 then
		imageHandleStorm = FAIO_disruptor.stormImage
	else
		imageHandleStorm = Renderer.LoadImage("resource/flash3/images/spellicons/" .. "disruptor_static_storm" .. ".png")
		FAIO_disruptor.stormImage = imageHandleStorm
	end

	local imageHandleField = 0
	if FAIO_disruptor.fieldImage > 0 then
		imageHandleField = FAIO_disruptor.fieldImage
	else
		imageHandleField = Renderer.LoadImage("resource/flash3/images/spellicons/" .. "disruptor_kinetic_field" .. ".png")
		FAIO_disruptor.fieldImage = imageHandleField
	end

	local imageHandleGlimpse = 0
	if FAIO_disruptor.glimpseImage > 0 then
		imageHandleGlimpse = FAIO_disruptor.glimpseImage
	else
		imageHandleGlimpse = Renderer.LoadImage("resource/flash3/images/spellicons/" .. "disruptor_glimpse" .. ".png")
		FAIO_disruptor.glimpseImage = imageHandleGlimpse
	end

	if not FAIO_skillHandler.skillIsReady(W) then return end

	if next(FAIO_disruptor.glimpsePositionTable) == nil then return end

	local hero = glimpseTarget

	if hero then
		if glimpseCheck then
			local index = Entity.GetIndex(hero)
			local glimpsePos = nil
				if FAIO_disruptor.glimpsePositionTable[index] ~= nil then
					local glimpseTime = math.floor(os.clock() * 10) / 10 - 4
					if FAIO_disruptor.glimpsePositionTable[index][glimpseTime] ~= nil then
						glimpsePos = FAIO_disruptor.glimpsePositionTable[index][glimpseTime]
					end
				end

			if glimpsePos ~= nil then
				local pos = Entity.GetAbsOrigin(hero)
				local posY = NPC.GetHealthBarOffset(hero)
					pos:SetZ(pos:GetZ() + posY)

				local x, y, visible = Renderer.WorldToScreen(pos)

				if visible then
					if FAIO_skillHandler.skillIsReady(ult) and NPC.IsPositionInRange(myHero, glimpsePos, Ability.GetCastRange(ult) + 175, 0) then
						Renderer.SetDrawColor(255, 255, 255, 255)
						Renderer.DrawImage(imageHandleGlimpse, x-45, y-80, 30, 30)
						Renderer.DrawImage(imageHandleStorm, x-15, y-80, 30, 30)
						Renderer.DrawImage(imageHandleField, x+15, y-80, 30, 30)
					else
						Renderer.SetDrawColor(255, 255, 255, 255)
						Renderer.DrawImage(imageHandleGlimpse, x-30, y-80, 30, 30)
						Renderer.DrawImage(imageHandleField, x, y-80, 30, 30)		
					end
				end
			end
		end
	end

	return

end

return FAIO_disruptor