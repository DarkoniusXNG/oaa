LinkLuaModifier( "modifier_techies_spoons_stash_oaa", "abilities/oaa_techies_spoons_stash.lua", LUA_MODIFIER_MOTION_NONE )

techies_spoons_stash_oaa = class(AbilityBaseClass)

function techies_spoons_stash_oaa:GetIntrinsicModifierName()
  return "modifier_techies_spoons_stash_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_techies_spoons_stash_oaa = class(ModifierBaseClass)

function modifier_techies_spoons_stash_oaa:IsHidden()
  return true
end

function modifier_techies_spoons_stash_oaa:IsDebuff()
  return false
end

function modifier_techies_spoons_stash_oaa:IsPurgable()
  return false
end

function modifier_techies_spoons_stash_oaa:RemoveOnDeath()
  return false
end

function modifier_techies_spoons_stash_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_techies_spoons_stash_oaa:OnIntervalThink()
  local unit = self:GetParent()
  if unit.GetItemInSlot ~= nil and unit:HasInventory() then
    -- for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      -- local item = unit:GetItemInSlot(i)
      -- if item then
        -- item:SetItemState(1)
      -- end
    -- end

    for j = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
      local backpack_item = unit:GetItemInSlot(j)
      if backpack_item then
        backpack_item:SetItemState(1)
        --backpack_item:SetCanBeUsedOutOfInventory(true)
      end
    end

    -- local neutral_item = unit:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
    -- if neutral_item then
      -- neutral_item:SetItemState(1)
    -- end
  end

end

-- function modifier_techies_spoons_stash_oaa:CheckState()
  -- return {
    -- [MODIFIER_STATE_CAN_USE_BACKPACK_ITEMS] = true,
  -- }
-- end


