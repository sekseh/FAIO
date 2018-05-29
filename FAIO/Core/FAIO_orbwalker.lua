FAIO_orbwalker = {}

FAIO_orbwalker.orbwalkerOrderTime = 0
FAIO_orbwalker.orbwalkerHumanizerTimer = 0
FAIO_orbwalker.orbwalkerAnimationCaptureTime = 0
FAIO_orbwalker.orbwalkerRangedAnimationEnd = 0
FAIO_orbwalker.orbwalkerMeleeAnimationEnd = 0

FAIO_orbwalker.orbwalkerAttackPoint = 0
FAIO_orbwalker.orbwalkerOrbwalkSkill = nil
FAIO_orbwalker.orbwalkerMoveOrderTimer = 0

function FAIO_orbwalker.OnUnitAnimation(animation)

	if animation.type == 1 then
		FAIO_orbwalker.orbwalkerAnimationCaptureTime = os.clock()
		FAIO_orbwalker.orbwalkerMeleeAnimationEnd = os.clock() + animation.castpoint
	end

end

function FAIO_orbwalker.OnProjectile(projectile)

	if projectile.isAttack then 

		FAIO_orbwalker.orbwalkerRangedAnimationEnd = os.clock()

	end

end

function FAIO_orbwalker.OrbWalker(myHero, enemy)

	if not myHero then return end
	if not enemy then return end

	if NPC.IsChannellingAbility(myHero) then return end
	if FAIO_utility_functions.isHeroChannelling(myHero) == true then return end
	if FAIO_orbwalker.orbwalkerCanAttack(myHero, enemy) == false then return end
	if FAIO_utility_functions.inSkillAnimation(myHero) == true then return end

	if FAIO_orbwalker.orbwalkerAttackPoint == 0 then
		FAIO_orbwalker.orbwalkerInit(myHero)
	end

	if FAIO_data.orbAttackTable[NPC.GetUnitName(myHero)] ~= nil then
		if FAIO_orbwalker.orbwalkerOrbwalkSkill == nil then
			if NPC.GetAbility(myHero, FAIO_data.orbAttackTable[NPC.GetUnitName(myHero)]) ~= nil and Ability.GetLevel(NPC.GetAbility(myHero, FAIO_data.orbAttackTable[NPC.GetUnitName(myHero)])) > 0 then
				FAIO_orbwalker.orbwalkerOrbwalkSkill = NPC.GetAbility(myHero, FAIO_data.orbAttackTable[NPC.GetUnitName(myHero)])
			end
		end
	end

	local myMana = NPC.GetMana(myHero)

	local attackRange = NPC.GetAttackRange(myHero)
	local movementSpeed = NPC.GetMoveSpeed(myHero)

	local turnTime180degrees = (0.03 * math.pi) / NPC.GetTurnRate(myHero)

	local breakPoint
		if NPC.IsRanged(myHero) then
			breakPoint = attackRange * (Menu.GetValue(FAIO_options.optionOrbwalkDistance) / 100)
		else
			breakPoint = attackRange
		end

	local moveDistance = 0
		if FAIO_orbwalker.orbwalkerCanMove(myHero) == true then

			moveDistance = NPC.GetMoveSpeed(myHero) * (FAIO_orbwalker.orbwalkerBackswingTimer(myHero) - NPC.GetTimeToFace(myHero, enemy)) * (1 - (Menu.GetValue(FAIO_options.optionOrbwalkOffset) / 100))

			local estimatedPos = Entity.GetAbsOrigin(myHero) + (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(moveDistance)
			local humanizerTiming = FAIO_orbwalker.humanizerMouseDelayCalc(estimatedPos)
		
				if humanizerTiming > 0 then
					moveDistance = moveDistance - (NPC.GetMoveSpeed(myHero) * humanizerTiming)
				end

				if humanizerTiming * 2 + FAIO_orbwalker.humanizerLingerTime > FAIO_orbwalker.orbwalkerBackswingTimer(myHero) - NPC.GetTimeToFace(myHero, enemy) then
					moveDistance = 0
				end

			if NPC.IsRanged(myHero) then
				if (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() > breakPoint and (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() <= breakPoint + moveDistance then
					moveDistance = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() - breakPoint
				end
			end

		end

	local kiteDistance = 0
		if Menu.IsEnabled(FAIO_options.optionOrbwalkKiting) and FAIO_orbwalker.orbwalkerCanMove(myHero) == true then

			if (2 * turnTime180degrees) < (FAIO_orbwalker.orbwalkerBackswingTimer(myHero)) * (1 - (Menu.GetValue(FAIO_options.optionOrbwalkOffset) / 100)) then
				kiteDistance = ((FAIO_orbwalker.orbwalkerBackswingTimer(myHero)) * (1 - (Menu.GetValue(FAIO_options.optionOrbwalkOffset) / 100)) - (2 * turnTime180degrees)) * NPC.GetMoveSpeed(myHero)

				local estimatedPos = Entity.GetAbsOrigin(myHero) + (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Normalized():Scaled(kiteDistance)
				local humanizerTiming = FAIO_orbwalker.humanizerMouseDelayCalc(estimatedPos)
					if humanizerTiming > 0 then
						kiteDistance = kiteDistance - (NPC.GetMoveSpeed(myHero) * humanizerTiming)
					end
			end

		end
		
	local styleSelector = 0
		if Menu.GetValue(FAIO_options.optionOrbwalkStyle) == 0 then
			styleSelector = 1
		else
			if Menu.GetValue(FAIO_options.optionOrbwalkMouseStyle) == 1 then
				styleSelector = 2
			else
				if NPC.IsRanged(myHero) then			
					styleSelector = 2
				else
					styleSelector = 1
				end
			end
		end

	local orbwalkStatus = 0
		if FAIO_orbwalker.orbwalkerAwaitingAnimation() == true then
			orbwalkStatus = 1
		end
		if FAIO_orbwalker.orbwalkerInAttackAnimation() == true then
			orbwalkStatus = 2
		end	
		if FAIO_orbwalker.orbwalkerIsInAttackBackswing(myHero) == true then
			orbwalkStatus = 3
		end
		if FAIO_orbwalker.orbwalkerAwaitingMovement(myHero) == true then
			orbwalkStatus = 4
		end

		if orbwalkStatus == 1 then

				if os.clock() > FAIO_orbwalker.orbwalkerOrderTime + NPC.GetTimeToFace(myHero, enemy) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2) + FAIO_orbwalker.humanizerMaxTime/1000 then
					if FAIO_orbwalker.orbwalkerOrderTime > FAIO_orbwalker.orbwalkerAnimationCaptureTime then
						if not NPC.IsRunning(myHero) then
							orbwalkStatus = 0
						end
					end
				end

		end

	if orbwalkStatus == 2 then return end
	if orbwalkStatus == 1 then return end
	if os.clock() < FAIO_orbwalker.orbwalkerHumanizerTimer then return end

	local orderSwitch = false
		if FAIO_orbwalker.orbwalkerAnimationCaptureTime == 0 then
			orderSwitch = true
		else
			if os.clock() > FAIO_orbwalker.orbwalkerAnimationCaptureTime then
				if os.clock() < FAIO_orbwalker.orbwalkerAnimationCaptureTime + NPC.GetAttackTime(myHero) then
					if FAIO_orbwalker.orbwalkerAnimationCaptureTime + NPC.GetAttackTime(myHero) - os.clock() < 0.1 then
						orderSwitch = true
					end
				end
			end
		end

	if styleSelector < 2 then

		if FAIO_orbwalker.orbwalkerCanCastOrbwalkSkill(myHero, enemy) and orderSwitch then
			Ability.CastTarget(FAIO_orbwalker.orbwalkerOrbwalkSkill, enemy)
			FAIO_orbwalker.orbwalkerOrderTime = os.clock()
			FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(Entity.GetAbsOrigin(enemy)) + 0.05
			return
		else

			if orbwalkStatus == 0 then
				Player.AttackTarget(Players.GetLocal(), myHero, enemy, false)
				FAIO_orbwalker.orbwalkerOrderTime = os.clock()
				FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(Entity.GetAbsOrigin(enemy)) + 0.05
				return
			end

		end

		if orbwalkStatus == 3 then

			if NPC.IsRanged(myHero) then
				if (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() > breakPoint then
					if moveDistance > 25 then
						local targetVector = Entity.GetAbsOrigin(myHero) + (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(moveDistance)
						NPC.MoveTo(myHero, targetVector, false, true)
						FAIO_orbwalker.orbwalkerMoveOrderTimer = os.clock()
						FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(targetVector) + 0.05
						return
					end
				end

				if Menu.IsEnabled(FAIO_options.optionOrbwalkKiting) then
					if NPC.IsRanged(myHero) then
						if (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() < breakPoint - 50 then
							if kiteDistance > 50 then
								local targetVector = Entity.GetAbsOrigin(myHero) + (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Normalized():Scaled(kiteDistance)
								NPC.MoveTo(myHero, targetVector, false, true)
								FAIO_orbwalker.orbwalkerMoveOrderTimer = os.clock()
								FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(targetVector) + 0.05
								return
							end
						end
					end
				end
			
			else
				if (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length2D() > breakPoint then
					local distanceToEnemy = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D() - NPC.GetHullRadius(myHero) - NPC.GetHullRadius(enemy)
					if math.min(moveDistance, distanceToEnemy) > 25 then
						local targetVector = Entity.GetAbsOrigin(myHero) + (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(math.min(moveDistance, distanceToEnemy))
						NPC.MoveTo(myHero, targetVector, false, true)
						FAIO_orbwalker.orbwalkerMoveOrderTimer = os.clock()
						FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(targetVector) + 0.05
						return
					end
				end
				
			end
		end
	else
		local mousePos = Input.GetWorldCursorPos()
		local breakPoint2
			if NPC.IsRanged(myHero) then
				breakPoint2 = attackRange * (Menu.GetValue(FAIO_options.optionOrbwalkDistanceMouse) / 100)
			else
				breakPoint2 = attackRange
			end

		local moveDistance2 = NPC.GetMoveSpeed(myHero) * (FAIO_orbwalker.orbwalkerBackswingTimer(myHero) - NPC.GetTimeToFace(myHero, enemy) - FAIO_utility_functions.TimeToFacePosition(myHero, mousePos)) * (1 - (Menu.GetValue(FAIO_options.optionOrbwalkOffset) / 100))		
		
		if FAIO_orbwalker.orbwalkerCanCastOrbwalkSkill(myHero, enemy) and orderSwitch then
			Ability.CastTarget(FAIO_orbwalker.orbwalkerOrbwalkSkill, enemy)
			FAIO_orbwalker.orbwalkerOrderTime = os.clock()
			FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(Entity.GetAbsOrigin(enemy)) + 0.05
			return
		else

			if orbwalkStatus == 0 then
				Player.AttackTarget(Players.GetLocal(), myHero, enemy, false)
				FAIO_orbwalker.orbwalkerOrderTime = os.clock()
				FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(Entity.GetAbsOrigin(enemy)) + 0.05
				return
			end
		end

		if orbwalkStatus == 3 then
			local myDisToMouse = (Entity.GetAbsOrigin(myHero) - mousePos):Length2D()
			if moveDistance2 > 25 and myDisToMouse > Menu.GetValue(FAIO_options.optionOrbwalkMouseHold) then
				local targetVector = Entity.GetAbsOrigin(myHero) + (mousePos - Entity.GetAbsOrigin(myHero)):Normalized():Scaled(moveDistance2)
				if not NPC.IsPositionInRange(enemy, targetVector, breakPoint2, 0) then
					NPC.MoveTo(myHero, targetVector, false, true)
					FAIO_orbwalker.orbwalkerMoveOrderTimer = os.clock()
					FAIO_orbwalker.orbwalkerHumanizerTimer = os.clock() + FAIO_orbwalker.humanizerMouseDelayCalc(targetVector) + 0.05
					return
				end
			end
		end
	end

	return

end

function FAIO_orbwalker.orbwalkerResetter()

	if not Menu.IsKeyDown(FAIO_options.optionComboKey) then
		if FAIO_orbwalker.orbwalkerOrderTime > 0 then

			FAIO_orbwalker.orbwalkerOrderTime = 0
			FAIO_orbwalker.orbwalkerAnimationCaptureTime = 0
			FAIO_orbwalker.orbwalkerRangedAnimationEnd = 0
			FAIO_orbwalker.orbwalkerMeleeAnimationEnd = 0
			FAIO_orbwalker.orbwalkerMoveOrderTimer = 0

		end
	end

	if FAIO_orbwalker.LockedTarget == nil then
		if FAIO_orbwalker.orbwalkerOrderTime > 0 then
		
			FAIO_orbwalker.orbwalkerOrderTime = 0
			FAIO_orbwalker.orbwalkerAnimationCaptureTime = 0
			FAIO_orbwalker.orbwalkerRangedAnimationEnd = 0
			FAIO_orbwalker.orbwalkerMeleeAnimationEnd = 0
			FAIO_orbwalker.orbwalkerMoveOrderTimer = 0

		end
	end

	if FAIO_utility_functions.inSkillAnimation(Heroes.GetLocal()) == true then
		if FAIO_orbwalker.orbwalkerOrderTime > 0 then

			FAIO_orbwalker.orbwalkerOrderTime = 0
			FAIO_orbwalker.orbwalkerAnimationCaptureTime = 0
			FAIO_orbwalker.orbwalkerRangedAnimationEnd = 0
			FAIO_orbwalker.orbwalkerMeleeAnimationEnd = 0
			FAIO_orbwalker.orbwalkerMoveOrderTimer = 0

		end
	end
		
	return

end

function FAIO_orbwalker.orbwalkerAwaitingAnimation()

	if FAIO_orbwalker.orbwalkerOrderTime == 0 then return false end

	if os.clock() < FAIO_orbwalker.orbwalkerOrderTime + 0.1 then return true end

	if os.clock() >= FAIO_orbwalker.orbwalkerOrderTime then
		if FAIO_orbwalker.orbwalkerOrderTime > FAIO_orbwalker.orbwalkerAnimationCaptureTime then
			return true
		end
	end

	return false

end

function FAIO_orbwalker.orbwalkerInAttackAnimation()

	if FAIO_orbwalker.orbwalkerAnimationCaptureTime == 0 then return false end
	if os.clock() < FAIO_orbwalker.orbwalkerAnimationCaptureTime then return false end

	local animationEndTimer = 0
		if Heroes.GetLocal() then
			if NPC.IsRanged(Heroes.GetLocal()) then
				animationEndTimer = FAIO_orbwalker.orbwalkerRangedAnimationEnd
			else
				animationEndTimer = FAIO_orbwalker.orbwalkerMeleeAnimationEnd
			end
		end

	if Heroes.GetLocal() then
		if NPC.IsRanged(Heroes.GetLocal()) then
			if os.clock() >= FAIO_orbwalker.orbwalkerAnimationCaptureTime then
				if FAIO_orbwalker.orbwalkerAnimationCaptureTime > animationEndTimer then
					if os.clock() < FAIO_orbwalker.orbwalkerAnimationCaptureTime + FAIO_orbwalker.orbwalkerAttackPoint + 0.2 then
						return true
					end
				end	
			end
		else
			if os.clock() >= FAIO_orbwalker.orbwalkerAnimationCaptureTime then
				if os.clock() < FAIO_orbwalker.orbwalkerAnimationCaptureTime + FAIO_orbwalker.orbwalkerAttackPoint + 0.2 then
					return true
				end
			end
		end
	end

	return false

end

function FAIO_orbwalker.orbwalkerIsInAttackBackswing(myHero)

	if not myHero then return false end

	if FAIO_orbwalker.orbwalkerAwaitingAnimation() == true then return false end
	if FAIO_orbwalker.orbwalkerInAttackAnimation() == true then return false end

	local backswingTimer = FAIO_orbwalker.orbwalkerBackswingTimer(myHero)

	local attackTime = NPC.GetAttackTime(myHero)

	if os.clock() < FAIO_orbwalker.orbwalkerAnimationCaptureTime + attackTime then
		return true
	end

	return false

end

function FAIO_orbwalker.orbwalkerBackswingTimer(myHero)

	if FAIO_orbwalker.orbwalkerAttackPoint == 0 then return 0 end

	local attackTime = NPC.GetAttackTime(myHero)
		if not attackTime then return 0 end

	return attackTime - FAIO_orbwalker.orbwalkerAttackPoint

end

function FAIO_orbwalker.orbwalkerAwaitingMovement(myHero)

	if FAIO_orbwalker.orbwalkerMoveOrderTimer == 0 then return false end
	if FAIO_orbwalker.orbwalkerOrderTime == 0 then return false end

	if os.clock() < FAIO_orbwalker.orbwalkerMoveOrderTimer + 0.1 then return true end

	if FAIO_orbwalker.orbwalkerMoveOrderTimer > FAIO_orbwalker.orbwalkerOrderTime then
		if FAIO_orbwalker.orbwalkerIsInAttackBackswing(myHero) == true then
			return true
		end
	end

	return false

end

function FAIO_orbwalker.orbwalkerInit(myHero)

	if not myHero then return end

	if FAIO_orbwalker.orbwalkerAttackPoint == 0 then
		
		local increasedAS = NPC.GetIncreasedAttackSpeed(myHero)

		for i, v in pairs(FAIO_data.attackPointTable) do
			if i == NPC.GetUnitName(myHero) then
				FAIO_orbwalker.orbwalkerAttackPoint = v[1] / (1 + (increasedAS/100))
				break
			end
		end
	
	end

	return

end

function FAIO_orbwalker.orbwalkerCanCastOrbwalkSkill(myHero, enemy)

	if not myHero then return false end
	if not enemy then return false end

	if FAIO_orbwalker.orbwalkerInAttackAnimation() == true then return false end

	if not FAIO_orbwalker.orbwalkerOrbwalkSkill then return false end

	local myMana = NPC.GetMana(myHero)
		if not Ability.IsCastable(FAIO_orbwalker.orbwalkerOrbwalkSkill, myMana) then return false end

	if Entity.IsSameTeam(myHero, enemy) then
		return false
	end
	
	if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
		return false
	end

	if FAIO_utility_functions.heroCanCastSpells(myHero, enemy) == false then
		return false
	end

	if Ability.GetName(FAIO_orbwalker.orbwalkerOrbwalkSkill) == "viper_poison_attack" then
		if NPC.HasModifier(enemy, "modifier_viper_poison_attack_slow") then
			local dieTime = Modifier.GetDieTime(NPC.GetModifier(enemy, "modifier_viper_poison_attack_slow"))
			if dieTime - GameRules.GetGameTime() > 1.0 then
				return false
			end
		end
		if Ability.SecondsSinceLastUse(FAIO_orbwalker.orbwalkerOrbwalkSkill) > -1 and Ability.SecondsSinceLastUse(FAIO_orbwalker.orbwalkerOrbwalkSkill) < NPC.GetAttackTime(myHero) * 1.5 then
			return false
		end
	end

	return true
	
end

function FAIO_orbwalker.orbwalkerCanAttack(myHero, enemy)

	if not myHero then return false end
	if not enemy then return false end

	if NPC.HasModifier(myHero, "modifier_stunned") then return false end
	if NPC.HasModifier(myHero, "modifier_bashed") then return false end
	if NPC.HasModifier(myHero, "modifier_alchemist_unstable_concoction") then return false end
	if NPC.HasModifier(myHero, "modifier_ancientapparition_coldfeet_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(myHero, "modifier_bloodseeker_rupture") then return false end
	if NPC.HasModifier(myHero, "modifier_rattletrap_hookshot") then return false end
	if NPC.HasModifier(myHero, "modifier_earthshaker_fissure_stun") then return false end
	if NPC.HasModifier(myHero, "modifier_earth_spirit_boulder_smash") then return false end
	if NPC.HasModifier(myHero, "modifier_enigma_black_hole_pull") then return false end

	if NPC.HasModifier(myHero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_jakiro_ice_path_stun") then return false end
	if NPC.HasModifier(myHero, "modifier_keeper_of_the_light_mana_leak_stun") then return false end
	if NPC.HasModifier(myHero, "modifier_kunkka_torrent") then return false end
	if NPC.HasModifier(myHero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(myHero, "modifier_lion_impale") then return false end
	if NPC.HasModifier(myHero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(myHero, "modifier_medusa_stone_gaze_stone") then return false end

	if NPC.HasModifier(myHero, "modifier_morphling_adaptive_strike") then return false end
	if NPC.HasModifier(myHero, "modifier_nyx_assassin_impale") then return false end	
	if NPC.HasModifier(myHero, "modifier_pudge_dismember") then return false end	
	if NPC.HasModifier(myHero, "modifier_sandking_impale") then return false end	
	if NPC.HasModifier(myHero, "modifier_shadow_shaman_shackles") then return false end	
	if NPC.HasModifier(myHero, "modifier_techies_stasis_trap_stunned") then return false end	
	if NPC.HasModifier(myHero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(myHero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(myHero, "modifier_storm_spirit_electric_vortex_pull") then return false end	
	if NPC.HasModifier(myHero, "modifier_crystal_maiden_frostbite") then return false end	
	if NPC.HasModifier(myHero, "modifier_ember_spirit_searing_chains") then return false end	
	if NPC.HasModifier(myHero, "modifier_treant_natures_guise") then return false end	
	if NPC.HasModifier(myHero, "modifier_treant_overgrowth") then return false end	

	if NPC.HasModifier(myHero, "modifier_eul_cyclone") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(myHero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end

		if NPC.HasModifier(enemy, "modifier_eul_cyclone") then return false end
		if NPC.HasModifier(enemy, "modifier_shadow_demon_disruption") then return false end	
		if NPC.HasModifier(enemy, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end

	return true

end

function FAIO_orbwalker.orbwalkerCanMove(myHero)

	if not myHero then return false end

	if NPC.HasModifier(myHero, "modifier_stunned") then return false end
	if NPC.HasModifier(myHero, "modifier_bashed") then return false end
	if NPC.HasModifier(myHero, "modifier_alchemist_unstable_concoction") then return false end
	if NPC.HasModifier(myHero, "modifier_ancientapparition_coldfeet_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(myHero, "modifier_bloodseeker_rupture") then return false end
	if NPC.HasModifier(myHero, "modifier_rattletrap_hookshot") then return false end
	if NPC.HasModifier(myHero, "modifier_earthshaker_fissure_stun") then return false end
	if NPC.HasModifier(myHero, "modifier_earth_spirit_boulder_smash") then return false end
	if NPC.HasModifier(myHero, "modifier_enigma_black_hole_pull") then return false end

	if NPC.HasModifier(myHero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_jakiro_ice_path_stun") then return false end
	if NPC.HasModifier(myHero, "modifier_keeper_of_the_light_mana_leak_stun") then return false end
	if NPC.HasModifier(myHero, "modifier_kunkka_torrent") then return false end
	if NPC.HasModifier(myHero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(myHero, "modifier_lion_impale") then return false end
	if NPC.HasModifier(myHero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(myHero, "modifier_medusa_stone_gaze_stone") then return false end

	if NPC.HasModifier(myHero, "modifier_morphling_adaptive_strike") then return false end
	if NPC.HasModifier(myHero, "modifier_nyx_assassin_impale") then return false end	
	if NPC.HasModifier(myHero, "modifier_pudge_dismember") then return false end	
	if NPC.HasModifier(myHero, "modifier_sandking_impale") then return false end	
	if NPC.HasModifier(myHero, "modifier_shadow_shaman_shackles") then return false end	
	if NPC.HasModifier(myHero, "modifier_techies_stasis_trap_stunned") then return false end	
	if NPC.HasModifier(myHero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(myHero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(myHero, "modifier_storm_spirit_electric_vortex_pull") then return false end	
	if NPC.HasModifier(myHero, "modifier_crystal_maiden_frostbite") then return false end	
	if NPC.HasModifier(myHero, "modifier_ember_spirit_searing_chains") then return false end	
	if NPC.HasModifier(myHero, "modifier_treant_natures_guise") then return false end	
	if NPC.HasModifier(myHero, "modifier_treant_overgrowth") then return false end	

	if NPC.HasModifier(myHero, "modifier_eul_cyclone") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(myHero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end

	if NPC.HasModifier(myHero, "modifier_naga_siren_ensnare") then return false end	
	if NPC.HasModifier(myHero, "modifier_rooted") then return false end	
	if NPC.HasModifier(myHero, "modifier_meepo_earthbind") then return false end
	if NPC.HasModifier(myHero, "modifier_lone_druid_spirit_bear_entangle_effect") then return false end	
	if NPC.HasModifier(myHero, "modifier_slark_pounce_leash") then return false end	
	if NPC.HasModifier(myHero, "modifier_abyssal_underlord_pit_of_malice_ensare") then return false end
	if NPC.HasModifier(myHero, "modifier_item_rod_of_atos_debuff") then return false end

	return true

end

return FAIO_orbwalker