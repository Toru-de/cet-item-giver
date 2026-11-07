local VERSION = "0.1.0"
local MAX_ID_LENGTH = 255
local MAX_AMOUNT = 1000000
local MAX_NONSTACKABLE_AMOUNT = 50

local presets = {
    { "Militech Canto Mk.6 (Tier 5)", "Items.HauntedCyberdeck_Legendary", 1 },
    { "Militech Canto Mk.6 crafting spec", "Items.Recipe_Legendary_HauntedCyberdeck", 1 },
    { "Erebus", "Items.Preset_Borg4a_HauntedGun", 1 },
    { "Decoded Cerberus component", "Items.Q305_Cerberus_core_cracked", 1 },
    { "Tier 5 item components", "Items.LegendaryMaterial1", 50 },
    { "Tier 5 quickhack components", "Items.QuickHackLegendaryMaterial1", 20 },
    { "Eddies", "Items.money", 10000 },
    { "Handgun ammo", "Ammo.HandgunAmmo", 100 },
    { "Rifle ammo", "Ammo.RifleAmmo", 200 },
    { "Shotgun ammo", "Ammo.ShotgunAmmo", 50 },
    { "Sniper rifle ammo", "Ammo.SniperRifleAmmo", 50 },
    { "Malorian Arms 3516", "Items.Preset_Silverhand_3516", 1 },
    { "Satori", "Items.Preset_Katana_Saburo", 1 },
}

local overlay = false
local itemID, quantity = "", 1
local pending
local status = "Choose a quick pick or enter an item ID."

local function normalizeID(input)
    local id = input:match("^%s*(.-)%s*$")
    if not id:match("^[%w_][%w_.]*$") or id:sub(-1) == "." or id:find("..", 1, true) then
        return nil
    end
    if not id:find(".", 1, true) then id = "Items." .. id end
    if #id <= MAX_ID_LENGTH then return id end
end

local function queueGrant()
    local id = normalizeID(itemID)
    if not id then
        status = "Enter a valid item ID such as Items.money."
        return
    end
    if quantity < 1 or quantity > MAX_AMOUNT or quantity ~= math.floor(quantity) then
        status = string.format("Quantity must be a whole number from 1 to %d.", MAX_AMOUNT)
        return
    end
    pending = { id = id, amount = quantity }
    status = "Request queued."
end

local function isStackable(record)
    local structure = record:ItemStructure()
    if not IsDefined(structure) then return false end
    local kind = structure:Type().value
    return kind == "Stackable" or kind == "BlueprintStackable"
end

local function giveItem(request)
    local player = Game.GetPlayer()
    if not IsDefined(player) or not player:IsAttached() or player:IsDead() then
        return "Load a save with V alive, then try again."
    end

    local id = TweakDBID.new(request.id)
    local record = TweakDB:GetRecord(id)
    if not IsDefined(record) or not record:IsA("gamedataItem_Record") then
        return "Item ID not found in this game. Check the spelling and capitalization."
    end
    if request.amount > MAX_NONSTACKABLE_AMOUNT and not isStackable(record) then
        return string.format("This item is limited to %d per grant.", MAX_NONSTACKABLE_AMOUNT)
    end

    local transaction = Game.GetTransactionSystem()
    if not IsDefined(transaction) then return "Inventory is unavailable. Try again in game." end
    if not transaction:GiveItemByTDBID(player, id, request.amount) then
        return "The game rejected the grant. Check the item and quantity."
    end

    local result = string.format("Grant accepted for %s x%d", request.id, request.amount)
    spdlog.info(result)
    return result
end

registerForEvent("onInit", function()
    spdlog.info("CET Item Giver " .. VERSION .. " loaded with CET " .. GetVersion())
end)
registerForEvent("onOverlayOpen", function() overlay = true end)
registerForEvent("onOverlayClose", function() overlay = false end)

registerForEvent("onUpdate", function()
    if not pending then return end
    local request = pending
    pending = nil
    local ok, result = pcall(giveItem, request)
    if ok then
        status = result
    else
        status = "Grant interrupted. Check your inventory before retrying."
        spdlog.error(tostring(result))
    end
end)

registerForEvent("onDraw", function()
    if not overlay then return end
    if ImGui.Begin("CET Item Giver") then
        ImGui.Text("v" .. VERSION)
        ImGui.SetNextItemWidth(340)
        if ImGui.BeginCombo("Quick picks", "Choose an item") then
            for _, preset in ipairs(presets) do
                if ImGui.Selectable(preset[1]) then
                    itemID, quantity = preset[2], preset[3]
                end
            end
            ImGui.EndCombo()
        end

        ImGui.SetNextItemWidth(340)
        itemID = ImGui.InputText("Item ID", itemID, MAX_ID_LENGTH + 1)
        ImGui.SetNextItemWidth(160)
        quantity = ImGui.InputInt("Quantity", quantity, 1, 100)

        ImGui.BeginDisabled(pending ~= nil)
        if ImGui.Button("Give Item") and not pending then queueGrant() end
        ImGui.EndDisabled()
        ImGui.TextWrapped(status)
    end
    ImGui.End()
end)
