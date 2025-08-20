-- Auto-reinject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/find/refs/heads/main/main.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Webhook URLs for different price ranges
local webhooks = {
    under500k = "https://discord.com/api/webhooks/1403878141621043271/lemMmGTrF2EU_DMgOPyzvuwkXHCtBlXiFhu3TTWQf3JrCYd2yvJYwNU3zdU0dxrzm7LT",
    range500k_1m = "https://discord.com/api/webhooks/1403878181244637346/6pxFD6sBGH3Sct9F6z_502ScTV8W44nLZ1ozDy9wTWqeRt_uRRcdysOozEKPvOkta7p-",
    range1m_10m = "https://discord.com/api/webhooks/1403878211925835906/l_XN8IEVW7ovtC2Ic-U2XAWRNFFFdmCItIHZ7NOm4ab0Iea7xokofDl36g7_3vrMaYoQ",
    range10m_100m = "https://discord.com/api/webhooks/1403878245912547329/P0YB20ckkYYnIeBM4vslA5ZIYqySkrNQxx3TBBFqLzl-LXUN_yz_SOYbjNkK-I1ATJdK",
    range100mplus = "https://discord.com/api/webhooks/1403878280926331021/LavIqWCitDjr2KnldHMNElKYY6zCIJ86jH57eHB1DKsWlgj89vaHlRyZ8mClfvY9cuET"
}

-- Role IDs to ping on Discord by price tier
local rolePingIds = {
    everything = "<@&1403882039299539135>",
    over500k = "<@&1403882094408630472>",
    over1m = "<@&1403882113215758477>",
    over10m = "<@&1403882129930059916>",
    over100m = "<@&1403882159151911024>"
}

-- Special brainrots (gold only, always 100m webhook)
local specialGoldBrainrots = {
    ["BULBITO BANDITO TRAKTORITO"] = true,
    ["GATTATINO NYANINO"] = true,
    ["PIPI CORNI"] = true,
    ["PIPI AVOCADO"] = true,
    ["TI TI TI SAHUR"] = true,
    ["PANDACCINI BANANINI"] = true,
    ["TIGRILINI WATERMELINI"] = true,
    ["TRACODUCOTULU DELAPELADUSTUZ"] = true,
    ["TRALALITA TRALALA"] = true,
    ["ESPRESSO SIGNORA"] = true,
    ["TUKANNO BANANNO"] = true,
    ["LOS ORCALITOS"] = true,
}

-- Keep these as normal (use price logic, not forced 100m gold)
local keepNormal = {
    ["MATTEO"] = true,
    ["GATTATINO NYANINO"] = true,
    ["BULBITO BANDITO TRAKTORITO"] = true,
}

local function sendWebhook(url, embed, content)
    local payloadTable = { embeds = { embed } }
    if content and content ~= "" then
        payloadTable.content = content
    end
    local payload = HttpService:JSONEncode(payloadTable)

    local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not req then
        warn("No HTTP request function found.")
        return
    end

    pcall(function()
        req({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
end

local function buildEmbed(nameText, baseOwner, mutationText, traitAmount, priceText, fullPrice)
    return {
        title = "NEW SECRET BRAINROT FOUND!",
        color = 0x1ABC9C,
        fields = {
            { name = "Name", value = nameText, inline = true },
            { name = "Owner", value = baseOwner, inline = true },
            { name = "Mutation", value = mutationText, inline = true },
            { name = "Trait Count", value = tostring(traitAmount), inline = true },
            { name = "Price", value = priceText, inline = true },
            { name = "Join Game", value = "[Click Here](https://chillihub1.github.io/chillihub-joiner/?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId) .. ")", inline = false }
        },
        footer = { text = "FinderX | Roblox Server Hopping Tool" }
    }
end

local function findAndNotifySecrets()
    local PlayerName = LocalPlayer.DisplayName

    for _, plot in ipairs(workspace.Plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if not sign then continue end

        local surf = sign:FindFirstChild("SurfaceGui")
        if not surf then continue end

        local frame = surf:FindFirstChild("Frame")
        if not frame then continue end

        local label = frame:FindFirstChild("TextLabel")
        if not label then continue end

        if label.Text == "Empty Base" then continue end
        local baseOwner = string.split(label.Text, "'")[1]
        if baseOwner == PlayerName then continue end

        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end

        for _, podium in ipairs(podiums:GetChildren()) do
            local spawn = podium:FindFirstChild("Base") and podium.Base:FindFirstChild("Spawn")
            if not spawn then continue end

            local attach = spawn:FindFirstChild("Attatchment") or spawn:FindFirstChild("Attachment")
            if not attach then continue end

            local overhead = attach:FindFirstChild("AnimalOverhead")
            if not overhead then continue end

            local rarity = overhead:FindFirstChild("Rarity")
            local stolen = overhead:FindFirstChild("Stolen")
            if not rarity or not stolen then continue end

            if (rarity.Text == "Secret" or rarity.Text == "Normal") and stolen.Text ~= "FUSING" then
                local mutation = overhead:FindFirstChild("Mutation")
                local price = overhead:FindFirstChild("Generation")
                local name = overhead:FindFirstChild("DisplayName")
                local traits = overhead:FindFirstChild("Traits")

                local mutationText = (mutation and mutation.Visible and mutation.Text) or "Normal"
                local priceText = price and price.Text or "?"
                local nameText = name and name.Text or "?"

                local traitAmount = 0
                if traits then
                    for _, n in ipairs(traits:GetChildren()) do
                        if n:IsA("ImageLabel") and n.Name == "Template" and n.Visible then
                            traitAmount += 1
                        end
                    end
                end

                local upperName = string.upper(nameText)

                -- GOLD SPECIAL HANDLING
                if specialGoldBrainrots[upperName] and not keepNormal[upperName] then
                    if mutationText:lower():find("gold") then
                        local embed = buildEmbed(nameText, baseOwner, mutationText, traitAmount, priceText, 1000000000)
                        print("SPECIAL GOLD BRAINROT FOUND! Name:", nameText, "Owner:", baseOwner)
                        sendWebhook(webhooks.range100mplus, embed, rolePingIds.over100m)
                    end
                else
                    -- NORMAL LOGIC
                    priceText = priceText:gsub("%$", ""):gsub("/s", ""):gsub("%s+", "")
                    local multipliers = { K = 1_000, M = 1_000_000, B = 1_000_000_000 }
                    local letter = priceText:sub(-1)
                    local numberPart
                    if multipliers[letter] then
                        numberPart = tonumber(priceText:sub(1, -2)) or 0
                    else
                        numberPart = tonumber(priceText) or 0
                        letter = nil
                    end
                    local fullPrice = numberPart * (multipliers[letter] or 1)

                    local webhookToSend
                    local content = ""
                    if fullPrice < 500_000 then
                        webhookToSend = webhooks.under500k
                        content = rolePingIds.everything
                    elseif fullPrice < 1_000_000 then
                        webhookToSend = webhooks.range500k_1m
                        content = rolePingIds.over500k
                    elseif fullPrice < 10_000_000 then
                        webhookToSend = webhooks.range1m_10m
                        content = rolePingIds.over1m
                    elseif fullPrice < 100_000_000 then
                        webhookToSend = webhooks.range10m_100m
                        content = rolePingIds.over10m
                    else
                        webhookToSend = webhooks.range100mplus
                        content = rolePingIds.over100m
                    end

                    local embed = buildEmbed(nameText, baseOwner, mutationText, traitAmount, priceText, fullPrice)
                    print("NEW SECRET/NORMAL BRAINROT FOUND! Name:", nameText, "Owner:", baseOwner, "Price:", fullPrice)
                    sendWebhook(webhookToSend, embed, content)
                end
            end
        end
    end
end

-- Server hopping logic
local running = true
local teleporting = false
local triedServers = {}
local hopRequested = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Q then
        print("[MANUAL HOP] Q pressed, requesting hop retry.")
        hopRequested = true
    end
end)

local function getSuitableServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if not ok or not res or not res.data then return {} end

    local list = {}
    for _, server in ipairs(res.data) do
        if server.id ~= game.JobId then
            table.insert(list, server.id)
        end
    end
    return list
end

local function tryTeleport(serverId)
    if teleporting then return false end
    teleporting = true
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
    teleporting = false
    if not success then
        warn("[Teleport Error]", err)
    end
    return success
end

local function hopLoop()
    while running do
        findAndNotifySecrets()

        local servers = getSuitableServers()
        if #servers == 0 then
            print("[HOP] No suitable servers found, retrying immediately...")
            task.wait(0.5)
        else
            if #triedServers == #servers then
                triedServers = {}
            end

            local serverToTry
            if #servers >= 30 and not table.find(triedServers, servers[30]) then
                serverToTry = servers[30]
            else
                local available = {}
                for _, sid in ipairs(servers) do
                    if not table.find(triedServers, sid) then
                        table.insert(available, sid)
                    end
                end
                if #available == 0 then
                    triedServers = {}
                    available = servers
                end
                serverToTry = available[math.random(#available)]
            end

            table.insert(triedServers, serverToTry)
            if tryTeleport(serverToTry) then
                print("[HOP] Teleporting to server:", serverToTry)
                break
            else
                print("[HOP] Failed to teleport to server:", serverToTry, "Trying again in 1 second...")
                local waited = 0
                while waited < 1 do
                    task.wait(0.1)
                    waited = waited + 0.1
                    if hopRequested then
                        print("[MANUAL HOP] Forced hop requested during wait.")
                        hopRequested = false
                        break
                    end
                end
            end
        end

        if hopRequested then
            print("[MANUAL HOP] Hop requested, restarting hop attempt.")
            hopRequested = false
        else
            task.wait(0.5)
        end
    end
end

TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

coroutine.wrap(hopLoop)()
