zuus_cloud_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_zuus_cloud_oaa", "abilities/oaa_zuus_cloud.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_zuus_bolt_true_sight", "abilities/oaa_zuus_cloud.lua", LUA_MODIFIER_MOTION_NONE )

function zuus_cloud_oaa:GetAOERadius()
  return self:GetSpecialValueFor("cloud_radius")
end

function zuus_cloud_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local nimbus_duration = self:GetSpecialValueFor("cloud_duration")
  local nimbus = CreateUnitByName("npc_dota_zeus_cloud", self:GetCursorPosition(), false, caster, caster, caster:GetTeamNumber())
  nimbus:SetOwner(caster)
  nimbus:SetControllableByPlayer(caster:GetPlayerOwnerID(), false)
  nimbus:AddNewModifier(caster, self, "modifier_zuus_cloud_oaa", {})
  nimbus:AddNewModifier(caster, self, "modifier_kill", {duration = nimbus_duration})
  nimbus:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = nimbus_duration + MANUAL_GARBAGE_CLEANING_TIME})
  nimbus:AddNewModifier(caster, self, "modifier_phased", {})
  --FindClearSpaceForUnit(nimbus, self:GetCursorPosition(), true)
end

function zuus_cloud_oaa:OnHeroCalculateStatBonus()
	local caster = self:GetCaster()

	if caster:HasScepter() or self:IsStolen() then
		self:SetHidden( false )
		if self:GetLevel() <= 0 then
			self:SetLevel( 1 )
		end
	else
		self:SetHidden( true )
	end
end

function zuus_cloud_oaa:GetAssociatedSecondaryAbilities()
  return "zuus_lightning_bolt"
end

function zuus_cloud_oaa:OnStolen(hSourceAbility)
  local caster = self:GetCaster()
  local lightning_bolt_ability = caster:FindAbilityByName("zuus_lightning_bolt")

  -- If the stealer is not morphling then hide lightning bolt
  if lightning_bolt_ability and not caster:FindAbilityByName("morphling_replicate") then
    lightning_bolt_ability:SetHidden(true)
    lightning_bolt_ability:SetStolen(true)
  end
end

------------------------------------------------------------------------------------------------------------------------------------------------

modifier_zuus_cloud_oaa = class( ModifierBaseClass )

function modifier_zuus_cloud_oaa:IsHidden()
  return true
end

function modifier_zuus_cloud_oaa:IsDebuff()
  return false
end

function modifier_zuus_cloud_oaa:IsPurgable()
  return false
end

function modifier_zuus_cloud_oaa:RemoveOnDeath()
  return true
end

function modifier_zuus_cloud_oaa:OnCreated( kv )
  if IsServer() then
    local parent = self:GetParent()
    self.ability = self:GetAbility()
    self.lightning_bolt_ability = self:GetCaster():FindAbilityByName("zuus_lightning_bolt")

    self.Interval = self.ability:GetSpecialValueFor("cloud_bolt_interval")
    self.Radius = self.ability:GetSpecialValueFor("cloud_radius")
    self.cloud_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud.vpcf", PATTACH_ABSORIGIN, parent)
    ParticleManager:SetParticleControl(self.cloud_particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.cloud_particle, 1, Vector(self.Radius, 1, 1))

    ParticleManager:SetParticleControlEnt(self.cloud_particle, 2, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    self:StartIntervalThink( 0.1 )
    -- Sound
    parent:EmitSound("Hero_Zuus.Cloud.Cast")
  end
end

function modifier_zuus_cloud_oaa:OnDestroy()
  if IsServer() then
    ParticleManager:DestroyParticle(self.cloud_particle, false)
    ParticleManager:ReleaseParticleIndex(self.cloud_particle)
    self.cloud_particle = nil
  end
end

function modifier_zuus_cloud_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_EVENT_ON_ATTACKED,
  }
end

function modifier_zuus_cloud_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_zuus_cloud_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_zuus_cloud_oaa:GetAbsoluteNoDamagePure()
  return 1
end

if IsServer() then
  function modifier_zuus_cloud_oaa:OnAttacked(event)
    local parent = self:GetParent()
    if event.target ~= parent then
      return
    end

    local attacker = event.attacker
    if not attacker or attacker:IsNull() then
      return
    end
    -- These damage values are ok if total hp of nimbus is 16.
    local damage = 1
    if attacker:IsRealHero() then
      damage = 4
      if attacker:IsRangedAttacker() then
        damage = 2
      end
    end
    -- To prevent dead nimbuses staying in memory (preventing SetHealth(0) or SetHealth(-value) )
    if parent:GetHealth() - damage <= 0 then
      if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
        parent:ForceKillOAA(false)
      else
        parent:Kill(self.ability, attacker)
      end
    else
      parent:SetHealth(parent:GetHealth() - damage)
    end
  end
end

function modifier_zuus_cloud_oaa:OnIntervalThink()
  if self.LastStrike == nil or GameRules:GetDOTATime(false, false) - self.LastStrike > self.Interval then
    local caster = self:GetCaster()
    -- Find closest unit, doesn't matter if its a hero or not
    local targets = FindUnitsInRadius(
      caster:GetTeamNumber(),
      self:GetParent():GetAbsOrigin(),
      nil,
      self.Radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE, -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_CLOSEST,
      false
    )

    if #targets > 0 then
      self:CastLightningBolt(targets[1])
      self.LastStrike = GameRules:GetDOTATime(false, false)
    end
  end
end

function modifier_zuus_cloud_oaa:CastLightningBolt(target)
  local caster = self:GetCaster()
  local parent = self:GetParent()
  local lightning_bolt_ability = caster:FindAbilityByName('zuus_lightning_bolt') or self.lightning_bolt_ability
  local sight_radius =  0

  -- Rubick stole Nimbus but he doesn't have Lightning Bolt for some reason
  if not lightning_bolt_ability then
    return
  end
  -- Rubick stole something else while cloud still exists
  if lightning_bolt_ability:IsNull() then
    return
  end
  if GameRules:IsDaytime() then
    sight_radius = lightning_bolt_ability:GetSpecialValueFor("sight_radius_day")
  else
    sight_radius = lightning_bolt_ability:GetSpecialValueFor("sight_radius_night")
  end
  local sight_duration = lightning_bolt_ability:GetSpecialValueFor("sight_duration")

  if lightning_bolt_ability:GetLevel() > 0 then

    local caster_team = caster:GetTeamNumber()

    -- Reveal the area
    AddFOWViewer(caster_team, target:GetAbsOrigin(), sight_radius, sight_duration, false)

    CreateModifierThinker( caster, lightning_bolt_ability, "modifier_zuus_bolt_true_sight", { duration = sight_duration }, target:GetAbsOrigin(), caster_team, false )

    -- Renders the particle on the sigil
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud_strike.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())

    -- Sound at the end (because light is faster than sound)
    target:EmitSound("Hero_Zuus.LightningBolt.Cloud")

    -- Calculate mini-stun duration
    local ministun_duration = self.ability:GetSpecialValueFor("ministun_duration")

    -- Keep status resistance in mind
    ministun_duration = target:GetValueChangedByStatusResistance(ministun_duration)

    if target:IsAlive() and not target:IsMagicImmune() then
      -- Apply mini-stun modifier
      target:AddNewModifier(caster, lightning_bolt_ability, "modifier_stunned", {duration = ministun_duration})

      -- Damage table for Lightning Bolt
      local damage_table = {
        attacker = parent,
        victim = target,
        damage = lightning_bolt_ability:GetAbilityDamage(),
        damage_type = lightning_bolt_ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        ability = lightning_bolt_ability,
      }

      -- Static Field damage comes from Zeus but cannot be reflected back to him
      --[[
      if not caster:PassivesDisabled() then
        local static_field_damage = 0
        -- Check for Static Field if its leveled up
        local static_field_ability = caster:FindAbilityByName("zuus_static_field")
        if static_field_ability and static_field_ability:GetLevel() > 0 then
          static_field_damage = static_field_ability:GetSpecialValueFor("damage_health_pct")
        end

        -- Damage table for Static Field
        local damage_table_2 = {
          attacker = caster,
          victim = target,
          damage = (target:GetHealth()/100)*static_field_damage,
          damage_type = DAMAGE_TYPE_MAGICAL,
          damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
          ability = static_field_ability,
        }

        -- Apply Static Field damage (before lightning bolt damage) to non-boss units
        if not target:IsOAABoss() then
          ApplyDamage(damage_table_2)
        end
      end
      ]]

      -- Apply Lightning Bolt damage
      ApplyDamage(damage_table)
    end
  end
end


modifier_zuus_bolt_true_sight = class(ModifierBaseClass)

function modifier_zuus_bolt_true_sight:IsHidden()
  return true
end

function modifier_zuus_bolt_true_sight:IsPurgable()
  return false
end

function modifier_zuus_bolt_true_sight:IsAura()
  return true
end

function modifier_zuus_bolt_true_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_zuus_bolt_true_sight:GetAuraRadius()
  local lightning_bolt_ability = self:GetAbility()
  if GameRules:IsDaytime() then
    return lightning_bolt_ability:GetSpecialValueFor("sight_radius_day")
  else
    return lightning_bolt_ability:GetSpecialValueFor("sight_radius_night")
  end
end

function modifier_zuus_bolt_true_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_zuus_bolt_true_sight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_zuus_bolt_true_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end
