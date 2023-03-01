modifier_drunk_oaa = class(ModifierBaseClass)

function modifier_drunk_oaa:IsHidden()
  return false
end

function modifier_drunk_oaa:IsDebuff()
  return false
end

function modifier_drunk_oaa:IsPurgable()
  return false
end

function modifier_drunk_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_drunk_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

function modifier_drunk_oaa:OnCreated()
  self.attack_crit_chance = 12
  self.spell_crit_chance = 12
  self.avoid_chance = 12
  self.crit_multiplier = 3
  self.miss_spell_chance = 25

  self:StartIntervalThink(1)
end

function modifier_drunk_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if not parent:IsIdle() then
    return
  end

  local position = parent:GetAbsOrigin() + RandomVector(1):Normalized() * RandomFloat(50, 200)

  -- The land is moving, not me
  parent:MoveToPosition(position)
end

function modifier_drunk_oaa:GetModifierAvoidDamage(event)
  if RandomInt(1, 100) <= self.avoid_chance then
    return 1
  end

  return 0
end

function modifier_drunk_oaa:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

if IsServer() then
  function modifier_drunk_oaa:GetModifierPreAttack_CriticalStrike(event)
    local target = event.target

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return 0
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return 0
    end

    -- Don't affect buildings, wards, invulnerable and dead units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() or not target:IsAlive() then
      return 0
    end

    if RandomInt(1, 100) <= self.attack_crit_chance then
      return self.crit_multiplier * 100
    end
  end

  function modifier_drunk_oaa:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.original_damage

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage
    --if damaged_unit == parent then
      --return
    --end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards, invulnerable and dead units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() or not damaged_unit:IsAlive() then
      return
    end

    -- Ignore damage with no-reflect flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage with HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage with no-spell-amplification flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      return
    end

    -- Can't crit on 0 or negative damage
    if damage <= 0 then
      return
    end

    -- Ignore attacks
    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    if RandomInt(1, 100) <= self.spell_crit_chance then
      local damage_table = {}
      damage_table.victim = damaged_unit
      damage_table.attacker = parent
      damage_table.damage = (self.crit_multiplier - 1) * damage
      damage_table.damage_type = event.damage_type
      damage_table.damage_flags = bit.bor(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION)

      ApplyDamage(damage_table)

      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, damaged_unit, damage_table.damage, nil)
    end
  end

  function modifier_drunk_oaa:OnAbilityExecuted(event)
    local parent = self:GetParent()
    local casting_unit = event.unit
    local target = event.target
    local ability = event.ability

    -- Check if caster of the executed ability exists
    if not casting_unit or casting_unit:IsNull() then
      return
    end

    -- Check if target of the executed ability exists
    if not target or target:IsNull() then
      return
    end

		-- Check if caster has this modifier
		if casting_unit ~= parent then
			return
		end

		-- Check if target of the executed ability is an ally of the target
		--if target:GetTeamNumber() == parent:GetTeamNumber() then
			--return
		--end

    -- Check if sober
    if RandomInt(1, 100) > self.miss_spell_chance then
      return
    end

    -- Stop it you are drunk
    local new_target
    local ally = self:FindRandomAlly(ability)
    local enemy = self:FindRandomEnemy(ability, target)
    local rand = RandomInt(1, 3)
    if rand == 1 then
      new_target = parent
    elseif rand == 2 then
      if ally then
        new_target = ally
      else
        new_target = enemy or parent
      end
    else
      if enemy then
        new_target = enemy
      else
        new_target = ally or target
      end
    end

		-- Redirect to the new_target (this method doesn't work for every unit target ability and item)
		casting_unit:SetCursorCastTarget(new_target)
  end

  function modifier_drunk_oaa:FindRandomAlly(ability)
    local random_ally
    local parent = self:GetParent()

    local allies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      ability:GetEffectiveCastRange(parent:GetAbsOrigin(), parent),
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      ability:GetAbilityTargetType(),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, ally in pairs(allies) do
      if ally and not ally:IsNull() and ally ~= parent then
        random_ally = ally
        break
      end
    end

    return random_ally
  end

  function modifier_drunk_oaa:FindRandomEnemy(ability, target)
    local random_enemy
    local parent = self:GetParent()

    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      ability:GetEffectiveCastRange(parent:GetAbsOrigin(), nil),
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      ability:GetAbilityTargetType(),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and enemy ~= target then
        random_enemy = enemy
        break
      end
    end

    return random_enemy
  end

end

function modifier_drunk_oaa:GetStatusEffectName()
  return "particles/status_fx/status_effect_brewmaster_cinder_brew.vpcf"
end

function modifier_drunk_oaa:StatusEffectPriority()
  return 5
end

function modifier_drunk_oaa:GetEffectName()
  return "particles/units/heroes/hero_brewmaster/brewmaster_cinder_brew_debuff.vpcf"
end

function modifier_drunk_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_drunk_oaa:GetTexture()
  return "brewmaster_drunken_brawler"
end