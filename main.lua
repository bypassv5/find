-- Auto-reinject on teleport + save last JobId
local scriptURL = "https://raw.githubusercontent.com/bypassv5/find/refs/heads/main/main.lua"
local lastJobId = game.JobId

if queue_on_teleport then
    queue_on_teleport("lastJobId = '"..game.JobId.."'\nloadstring(game:HttpGet('"..scriptURL.."'))()")
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Webhook URLs
local webhooks = {
    under500k      = "https://discord.com/api/webhooks/1403878141621043271/lemMmGTrF2EU_DMgOPyzvuwkXHCtBlXiFhu3TTWQf3JrCYd2yvJYwNU3zdU0dxrzm7LT",
    range500k_1m   = "https://discord.com/api/webhooks/1403878181244637346/6pxFD6sBGH3Sct9F6z_502ScTV8W44nLZ1ozDy9wTWqeRt_uRRcdysOozEKPvOkta7p-",
    range1m_10m    = "https://discord.com/api/webhooks/1403878211925835906/l_XN8IEVW7ovtC2Ic-U2XAWRNFFFdmCItIHZ7NOm4ab0Iea7xokofDl36g7_3vrMaYoQ",
    range10m_100m  = "https://discord.com/api/webhooks/1403878245912547329/P0YB20ckkYYnIeBM4vslA5ZIYqySkrNQxx3TBBFqLzl-LXUN_yz_SOYbjNkK-I1ATJdK",
    range100mplus  = "https://discord.com/api/webhooks/1403878280926331021/LavIqWCitDjr2KnldHMNElKYY6zCIJ86jH57eHB1DKsWlgj89vaHlRyZ8mClfvY9cuET"
}

-- Role IDs
local rolePingIds = {
    everything = "<@&1403882039299539135>",
    over500k   = "<@&1403882094408630472>",
    over1m     = "<@&1403882113215758477>",
    over10m    = "<@&1403882129930059916>",
    over100m   = "<@&1403882159151911024>"
}

local function sendWebhook(url, embed, content)
    local payloadTable = { embeds = { embed } }
    if content and content ~= "" then payloadTable.content = content end
    local payload = HttpService:JSONEncode(payloadTable)
    local req = (syn and syn.request) or http_request or (fluxus and fluxus.request)
    if not req then warn("No HTTP request function found."); return end
    pcall(function()
        req({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
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
            { name = "Join Game", value = "[Click Here](https://chillihub1.github.io/chillihub-joiner/?placeId="..tostring(game.PlaceId).."&gameInstanceId="..tostring(game.JobId)..")", inline = false }
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
                local webhookToSend, content
                if fullPrice < 500_000 then webhookToSend, content = webhooks.under500k, rolePingIds.everything
                elseif fullPrice < 1_000_000 then webhookToSend, content = webhooks.range500k_1m, rolePingIds.over500k
                elseif fullPrice < 10_000_000 then webhookToSend, content = webhooks.range1m_10m, rolePingIds.over1m
                elseif fullPrice < 100_000_000 then webhookToSend, content = webhooks.range10m_100m, rolePingIds.over10m
                else webhookToSend, content = webhooks.range100mplus, rolePingIds.over100m end
                local embed = buildEmbed(nameText, baseOwner, mutationText, traitAmount, priceText, fullPrice)
                print("NEW SECRET BRAINROT FOUND!", nameText, baseOwner, fullPrice)
                sendWebhook(webhookToSend, embed, content)
            end
        end
    end
end

local function getServers()
    local servers = {}
    local cursor = ""
    repeat
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"..(cursor ~= "" and "&cursor="..cursor or "")
        local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
        if ok and res and res.data then
            for _, server in ipairs(res.data) do
                if server.id ~= game.JobId and server.id ~= lastJobId then
                    table.insert(servers, server.id)
                end
            end
            cursor = res.nextPageCursor or ""
        else
            cursor = ""
        end
        task.wait(0.2)
    until cursor == "" or #servers >= 200
    return servers
end

local function tryTeleport(serverId)
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
    if not success then
        warn("[Teleport Error]", err)
        task.wait(1)
        return false
    end
    return true
end

local function hopLoop()
    while true do
        findAndNotifySecrets()
        task.wait(1)
        local servers = getServers()
        if #servers == 0 then
            print("[HOP] No new servers found, retrying in 10 seconds...")
            task.wait(2)
        else
            local target = servers[math.random(#servers)]
            lastJobId = target
            if tryTeleport(target) then
                print("[HOP] Teleporting to:", target)
                break
            end
        end
    end
end

TeleportService.TeleportInitFailed:Connect(function()
    print("[Teleport Failed] Retrying...")
    task.wait(1)
    hopLoop()
end)

coroutine.wrap(hopLoop)()
