item_frostivus_oaa = class(ItemBaseClass)

function item_frostivus_oaa:GetBuiltInAbilityName()
  return ""
end

function item_frostivus_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local abilityname = self:GetBuiltInAbilityName()

  local temporary = caster:AddAbility(abilityname)
  temporary:SetHidden(true)
  temporary:SetLevel(1)
  temporary:CastAbility()
  Timers:CreateTimer(1, function()
    caster:RemoveAbility(abilityname)
  end)
  self:SpendCharge()
end

function item_frostivus_oaa:ProcsMagicStick()
  return false
end

function item_frostivus_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

item_snowball_oaa = class(item_frostivus_oaa)

function item_snowball_oaa:GetBuiltInAbilityName()
  return "seasonal_throw_snowball"
end

---------------------------------------------------------------------------------------------------

item_summon_snowman_oaa = class(item_frostivus_oaa)

function item_summon_snowman_oaa:GetBuiltInAbilityName()
  return "seasonal_summon_snowman"
end

---------------------------------------------------------------------------------------------------

item_summon_penguin_oaa = class(item_frostivus_oaa)

function item_summon_penguin_oaa:GetBuiltInAbilityName()
  return "seasonal_summon_penguin"
end

---------------------------------------------------------------------------------------------------

item_decorate_tree_oaa = class(item_frostivus_oaa)

function item_decorate_tree_oaa:GetBuiltInAbilityName()
  return "seasonal_decorate_tree"
end

---------------------------------------------------------------------------------------------------

item_frostivus_firework_oaa = class(item_frostivus_oaa)

function item_frostivus_firework_oaa:GetBuiltInAbilityName()
  return "seasonal_festive_firework"
end

---------------------------------------------------------------------------------------------------

item_frostivus_stocking_oaa = class(ItemBaseClass)

function item_frostivus_stocking_oaa:GetIntrinsicModifierName()
  return "modifier_item_frostivus_stocking_oaa"
end

LinkLuaModifier("modifier_item_frostivus_stocking_oaa", "frostivus/items.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

modifier_item_frostivus_stocking_oaa = class(ModifierBaseClass)

function modifier_item_frostivus_stocking_oaa:IsHidden()
  return true
end

function modifier_item_frostivus_stocking_oaa:IsDebuff()
  return false
end

function modifier_item_frostivus_stocking_oaa:IsPurgable()
  return false
end

function modifier_item_frostivus_stocking_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_frostivus_stocking_oaa:OnCreated(event)

end

function modifier_item_frostivus_stocking_oaa:OnRefresh(event)

end

function modifier_item_frostivus_stocking_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
  return funcs
end

function modifier_item_frostivus_stocking_oaa:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("magic_resistance")
end

---------------------------------------------------------------------------------------------------

item_frostivus_skates_oaa = class(ItemBaseClass)

function item_frostivus_skates_oaa:GetIntrinsicModifierName()
  return "modifier_item_frostivus_skates_oaa"
end

LinkLuaModifier("modifier_item_frostivus_skates_oaa", "frostivus/items.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

modifier_item_frostivus_skates_oaa = class(ModifierBaseClass)

function modifier_item_frostivus_skates_oaa:IsHidden()
  return true
end

function modifier_item_frostivus_skates_oaa:IsDebuff()
  return false
end

function modifier_item_frostivus_skates_oaa:IsPurgable()
  return false
end

function modifier_item_frostivus_skates_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
  }
  return funcs
end

function modifier_item_frostivus_skates_oaa:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("bonus_movement_speed_percent")
end

function modifier_item_frostivus_skates_oaa:GetModifierTurnRate_Percentage()
  return self:GetAbility():GetSpecialValueFor("turn_rate")
end

function modifier_item_frostivus_skates_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_UNSLOWABLE] = true,
  }
  return state
end

---------------------------------------------------------------------------------------------------

item_frostivus_suprise_oaa = class(ItemBaseClass)

function item_frostivus_suprise_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local item1 = "item_snowball_oaa"
  local item2 = "item_summon_snowman_oaa"
  local item3 = "item_summon_penguin_oaa"
  local item4 = "item_decorate_tree_oaa"
  local item5 = "item_frostivus_firework_oaa"
  if caster:IsRealHero() then
    caster:AddItemByName(item1)
    caster:AddItemByName(item2)
    caster:AddItemByName(item3)
    caster:AddItemByName(item4)
  end
  self:SpendCharge()
end

function item_frostivus_suprise_oaa:ProcsMagicStick()
  return false
end

function item_frostivus_suprise_oaa:IsStealable()
  return false
end
