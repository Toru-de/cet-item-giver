local events = {}
registerForEvent = function(name, callback) events[name] = callback end
IsDefined = function(value) return type(value) == "table" end
GetVersion = function() return "v1.38.1" end

local messages, errors, grants = {}, {}, {}
spdlog = {
    info = function(message) messages[#messages + 1] = message end,
    error = function(message) errors[#errors + 1] = message end,
}

local player = { attached = true, dead = false }
function player:IsAttached() return self.attached end
function player:IsDead() return self.dead end

local availablePlayer = player
local reject, throw = false, false
local transaction = {
    GiveItemByTDBID = function(_, recipient, id, amount)
        assert(recipient == player and id.key and amount == math.floor(amount))
        if throw then error("simulated transaction error") end
        if reject then return false end
        grants[#grants + 1] = { id.key, amount }
        return true
    end,
}
Game = {
    GetPlayer = function() return availablePlayer end,
    GetTransactionSystem = function() return transaction end,
}

local function record(kind, isItem)
    return {
        IsA = function(_, class) return isItem and class == "gamedataItem_Record" end,
        ItemStructure = function()
            return { Type = function() return { value = kind } end }
        end,
    }
end
local records = {
    ["Items.money"] = record("Stackable", true),
    ["Ammo.RifleAmmo"] = record("Stackable", true),
    ["Items.HauntedCyberdeck_Legendary"] = record("Unique", true),
    ["Character.Judy"] = record("Unique", false),
}
TweakDBID = { new = function(id) return { key = id } end }
TweakDB = { GetRecord = function(_, id) return records[id.key] end }

local editedID, editedAmount, clicked, selected, visibleStatus
local noop = function() end
ImGui = {
    Begin = function() return true end,
    End = noop, BeginDisabled = noop, EndDisabled = noop, SetNextItemWidth = noop, Text = noop,
    TextWrapped = function(status) visibleStatus = status end,
    BeginCombo = function() return selected ~= nil end,
    EndCombo = noop,
    Selectable = function(label) return label == selected end,
    InputText = function(_, value) return editedID or value, editedID ~= nil end,
    InputInt = function(_, value) return editedAmount or value, editedAmount ~= nil end,
    Button = function() return clicked end,
}

dofile("bin/x64/plugins/cyber_engine_tweaks/mods/CETItemGiver/init.lua")
events.onInit()

local function click(id, amount)
    editedID, editedAmount, clicked = id, amount, true
    events.onDraw()
    editedID, editedAmount, clicked = nil, nil, false
end

local function statusContains(part)
    events.onDraw()
    assert(visibleStatus:find(part, 1, true), visibleStatus)
end

local function attempt(id, amount, expectedStatus, count)
    click(id, amount)
    events.onUpdate()
    statusContains(expectedStatus)
    assert(#grants == count)
end

click("Items.money", 100)
events.onUpdate()
assert(#grants == 0) -- Closed overlay never queues a grant.

events.onOverlayOpen()
click("  money  ", 10000)
click("Ammo.RifleAmmo", 20)
assert(#grants == 0)
events.onUpdate()
events.onUpdate()
assert(#grants == 1 and grants[1][1] == "Items.money" and grants[1][2] == 10000)
statusContains("Grant accepted")

selected = "Militech Canto Mk.6 (Tier 5)"
events.onDraw()
events.onUpdate()
assert(#grants == 1)
selected = nil
attempt(nil, nil, "Grant accepted", 2)
assert(grants[2][1] == "Items.HauntedCyberdeck_Legendary" and grants[2][2] == 1)

attempt("Items.money", -1, "Quantity must be", 2)
attempt("Items.money", 1.5, "Quantity must be", 2)
attempt("Items.money", 1000001, "Quantity must be", 2)
attempt("Items..money", 1, "Enter a valid item ID", 2)
attempt("Items." .. string.rep("x", 256), 1, "Enter a valid item ID", 2)
attempt("Items.Nonexistent", 1, "Item ID not found", 2)
attempt("Character.Judy", 1, "Item ID not found", 2)
attempt("Items.HauntedCyberdeck_Legendary", 51, "limited to 50", 2)

availablePlayer = nil
attempt("Items.money", 1, "Load a save", 2)
availablePlayer = player
player.dead = true
attempt("Items.money", 1, "Load a save", 2)
player.dead = false
reject = true
attempt("Ammo.RifleAmmo", 20, "game rejected", 2)
reject = false
throw = true
attempt("Items.money", 1, "Grant interrupted", 2)
throw = false
events.onUpdate()
assert(#errors == 1 and #grants == 2)
attempt("Ammo.RifleAmmo", 20, "Grant accepted", 3)
assert(grants[3][1] == "Ammo.RifleAmmo" and #messages == 4)

print("PASS: overlay, quick picks, item ID and amount validation, session checks, and transaction results")
