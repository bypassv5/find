-- Auto-reinject on teleport
local scriptURL = "https://raw.githubusercontent.com/bypassv5/find/refs/heads/main/ryad.csc"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Webhooks
local webhookAllSecrets = "https://discord.com/api/webhooks/1410685085916860446/X8js0Yg_9TTBo06WMazapwXz9HKmk9i3BQuc5peZ1LHQmvUjkbQxHmb0i2r9LIcXacYb"
local webhook2mPlus = "https://discordapp.com/api/webhooks/1410683291660451980/By4T7n2YfIGDmUISa4RkP0jk3zLUxz5Ku2l2FIydNpbt9PYtuQNxx8O9eqbBIprFB6Is"

local function sendWebhook(url, embed)
    local payloadTable = { embeds = { embed } }
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
        title = "NEW SECRET FOUND!",
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
        if not label or label.Text == "Empty Base" then continue end

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

            if rarity.Text == "Secret" and stolen.Text ~= "FUSING" then
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

                -- parse price
                local cleanPrice = priceText:gsub("%$", ""):gsub("/s", ""):gsub("%s+", "")
                local multipliers = { K = 1_000, M = 1_000_000, B = 1_000_000_000 }
                local letter = cleanPrice:sub(-1)
                local numberPart
                if multipliers[letter] then
                    numberPart = tonumber(cleanPrice:sub(1, -2)) or 0
                else
                    numberPart = tonumber(cleanPrice) or 0
                    letter = nil
                end
                local fullPrice = numberPart * (multipliers[letter] or 1)

                local embed = buildEmbed(nameText, baseOwner, mutationText, traitAmount, priceText, fullPrice)
                print("NEW SECRET FOUND! Name:", nameText, "Owner:", baseOwner, "Price:", fullPrice)

                -- always send to "all secrets"
                sendWebhook(webhookAllSecrets, embed)

                -- also send to 2m+ webhook if price >= 2,000,000
                if fullPrice >= 2_000_000 then
                    sendWebhook(webhook2mPlus, embed)
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
