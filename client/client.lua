local RSGCore = exports['rsg-core']:GetCoreObject()
local butcher
local name

-- prompts
Citizen.CreateThread(function()
    for butcher, v in pairs(Config.ButcherLocations) do
        local name = v.name
        exports['rsg-core']:createPrompt(v.location, v.coords, RSGCore.Shared.Keybinds['J'], 'Open ' .. v.name, {
            type = 'client',
            event = 'rsg-butcher:client:menu',
            args = { name },
        })
        if v.showblip == true then
            local ButcherBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords)
            SetBlipSprite(ButcherBlip, GetHashKey(Config.Blip.blipSprite), true)
            SetBlipScale(ButcherBlip, Config.Blip.blipScale)
            Citizen.InvokeNative(0x9CB1A1623062F402, ButcherBlip, Config.Blip.blipName)
        end
    end
end)

-- butcher menu
RegisterNetEvent('rsg-butcher:client:menu', function(butchername)
    exports['rsg-menu']:openMenu({
        {
            header = butchername,
            isMenuHeader = true,
        },
        {
            header = "Sell Animal",
            txt = "sell your animal to the butcher",
            icon = "fas fa-paw",
            params = {
                event = 'rsg-butcher:client:sellanimal',
                isServer = false,
                args = {}
            }
        },
        {
            header = "Open Shop",
            txt = "buy items from the butcher",
            icon = "fas fa-shopping-basket",
            params = {
                event = 'rsg-butcher:client:OpenButcherShop',
                isServer = false,
                args = {}
            }
        },
        {
            header = "Close Menu",
            txt = '',
            params = {
                event = 'rsg-menu:closeMenu',
            }
        },
    })
end)

RegisterNetEvent('rsg-butcher:client:sellanimal')
AddEventHandler('rsg-butcher:client:sellanimal', function()
    local ped = PlayerPedId()
    local holding = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped) -- GetFirstEntityPedIsCarrying
    local model = GetEntityModel(holding)
    local quality = Citizen.InvokeNative(0x7BCC6087D130312A, holding)
    if Config.Debug == true then
        print("model: "..tostring(model))
        print("quality: "..tostring(quality))
    end
    if holding ~= false then
        for i, row in pairs(Config.Animal) do
            if model == Config.Animal[i]["model"] then
                local reward = Config.Animal[i]["reward"]
                local name = Config.Animal[i]["name"]
                if Config.Debug == true then
                    print("reward: "..tostring(reward))
                    print("name: "..tostring(name))
                end
                RSGCore.Functions.Progressbar('sell-carcass', 'Selling '..name..'..', Config.SellTime, false, true, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function() -- Done
                    local deleted = DeleteThis(holding)
                    if deleted then
                        if quality == 0 then
                            TriggerServerEvent("rsg-butcher:server:reward", reward, 'poor') -- poor quality reward
                        elseif quality == 1 then
                            TriggerServerEvent("rsg-butcher:server:reward", reward, 'good') -- good quality reward
                        elseif quality == 2 then
                            TriggerServerEvent("rsg-butcher:server:reward", reward, 'perfect') -- perfect quality reward
                        elseif quality == -1 then
                            TriggerServerEvent("rsg-butcher:server:reward", reward, 'perfect') -- perfect quality reward
                        else
                            RSGCore.Functions.Notify('something went wrong!', 'error')
                        end
                    else
                        RSGCore.Functions.Notify('something went wrong!', 'error')
                    end
                end)
            end
        end
    end
end)

function DeleteThis(holding)
    NetworkRequestControlOfEntity(holding)
    SetEntityAsMissionEntity(holding, true, true)
    Wait(100)
    DeleteEntity(holding)
    Wait(500)
    local entitycheck = Citizen.InvokeNative(0xD806CD2A4F2C2996, PlayerPedId())
    local holdingcheck = GetPedType(entitycheck)
    if holdingcheck == 0 then
        return true
    else
        return false
    end
end

RegisterNetEvent('rsg-butcher:client:OpenButcherShop')
AddEventHandler('rsg-butcher:client:OpenButcherShop', function()
    local ShopItems = {}
    ShopItems.label = "Butcher Shop"
    ShopItems.items = Config.ButcherShop
    ShopItems.slots = #Config.ButcherShop
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "ButcherShop_"..math.random(1, 99), ShopItems)
end)

--  0: "PED_QUALITY_LOW"
--  1: "PED_QUALITY_MEDIUM"
--  2: "PED_QUALITY_HIGH"
-- -1: you should interpret as "PED_QUALITY_HIGH"
