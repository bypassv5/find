-- Auto-reinject on teleport  
local scriptURL = "https://raw.githubusercontent.com/bypassv5/find/refs/heads/main/main.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Webhook URLs for different price ranges
local webhooks = {
    under500k      = "https://discord.com/api/webhooks/1403878141621043271/lemMmGTrF2EU_DMgOPyzvuwkXHCtBlXiFhu3TTWQf3JrCYd2yvJYwNU3zdU0dxrzm7LT",
    range500k_1m   = "https://discord.com/api/webhooks/1403878181244637346/6pxFD6sBGH3Sct9F6z_502ScTV8W44nLZ1ozDy9wTWqeRt_uRRcdysOozEKPvOkta7p-",
    range1m_10m    = "https://discord.com/api/webhooks/1403878211925835906/l_XN8IEVW7ovtC2Ic-U2XAWRNFFFdmCItIHZ7NOm4ab0Iea7xokofDl36g7_3vrMaYoQ",
    range10m_100m  = "https://discord.com/api/webhooks/1403878245912547329/P0YB20ckkYYnIeBM4vslA5ZIYqySkrNQxx3TBBFqLzl-LXUN_yz_SOYbjNkK-I1ATJdK",
    range100mplus  = "https://discord.com/api/webhooks/1403878280926331021/LavIqWCitDjr2KnldHMNElKYY6zCIJ86jH57eHB1DKsWlgj89vaHlRyZ8mClfvY9cuET"
}

local function sendWebhook(url, embed)
    local payload = HttpService:JSONEncode({ embeds = { embed } })
    local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not req then warn("No HTTP request function found."); return end

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
        color = 0x1ABC9C, -- teal color
        fields = {
            { name = "Name", value = nameText, inline = true },
            { name = "Owner", value = baseOwner, inline = true },
            { name = "Mutation", value = mutationText, inline = true },
            { name = "Trait Count", value = tostring(traitAmount), inline = true },
            { name = "Price Label", value = priceText, inline = true },
            { name = "Full Price", value = tostring(fullPrice), inline = true },
            { name = "Join Game", value = "[Click Here](https://chillihub1.github.io/chillihub-joiner/?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId) .. ")", inline = false }
        },
        timestamp = os.date("!%Y-%m-%dT%TZ"),
        footer = { text = "Secret Brainrot Detector" }
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

        if label.Text == "Empty Base" then
            continue
        end

        local baseOwner = string.split(label.Text, "'")[1]
        if baseOwner == PlayerName then
            continue
        end

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
                if fullPrice < 500_000 then
                    webhookToSend = webhooks.under500k
                elseif fullPrice < 1_000_000 then
                    webhookToSend = webhooks.range500k_1m
                elseif fullPrice < 10_000_000 then
                    webhookToSend = webhooks.range1m_10m
                elseif fullPrice < 100_000_000 then
                    webhookToSend = webhooks.range10m_100m
                else
                    webhookToSend = webhooks.range100mplus
                end

                local embed = buildEmbed(nameText, baseOwner, mutationText, traitAmount, priceText, fullPrice)

                print("NEW SECRET BRAINROT FOUND! Name:", nameText, "Owner:", baseOwner, "Price:", fullPrice)
                sendWebhook(webhookToSend, embed)
            end
        end
    end
end

-- Server hopping logic from your template script
local running = true
local teleporting = false

local function getSuitableServers()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if not ok or not res or not res.data then return {} end

    local list = {}
    for _, server in ipairs(res.data) do
        if server.id ~= game.JobId and server.playing >= 3 and server.playing <= 5 then
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
        task.wait(1) -- slight delay to avoid spamming

        local servers = getSuitableServers()
        if #servers > 0 then
            local serverId = servers[1]
            if tryTeleport(serverId) then
                print("[HOP] Teleporting to server:", serverId)
                break -- break loop because teleporting
            else
                task.wait(1)
            end
        else
            print("[HOP] No suitable servers found, retrying in 10 seconds...")
            task.wait(10)
        end
    end
end

-- Teleport failure fallback
TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Rejoining current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- Start the hopping loop immediately
coroutine.wrap(hopLoop)()
