local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

-- Webhook URLs
local webhooks = {
    under500k      = "https://discord.com/api/webhooks/1403878141621043271/lemMmGTrF2EU_DMgOPyzvuwkXHCtBlXiFhu3TTWQf3JrCYd2yvJYwNU3zdU0dxrzm7LT",
    range500k_1m   = "https://discord.com/api/webhooks/1403878181244637346/6pxFD6sBGH3Sct9F6z_502ScTV8W44nLZ1ozDy9wTWqeRt_uRRcdysOozEKPvOkta7p-",
    range1m_10m    = "https://discord.com/api/webhooks/1403878211925835906/l_XN8IEVW7ovtC2Ic-U2XAWRNFFFdmCItIHZ7NOm4ab0Iea7xokofDl36g7_3vrMaYoQ",
    range10m_100m  = "https://discord.com/api/webhooks/1403878245912547329/P0YB20ckkYYnIeBM4vslA5ZIYqySkrNQxx3TBBFqLzl-LXUN_yz_SOYbjNkK-I1ATJdK",
    range100mplus  = "https://discord.com/api/webhooks/1403878280926331021/LavIqWCitDjr2KnldHMNElKYY6zCIJ86jH57eHB1DKsWlgj89vaHlRyZ8mClfvY9cuET"
}

local function sendWebhook(url, embed)
    local payload = HttpService:JSONEncode({ embeds = { embed } })
    syn.request({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload
    })
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
            { name = "Price Label", value = priceText, inline = true },
            { name = "Full Price", value = tostring(fullPrice), inline = true },
            { name = "Join Game", value = "[Click Here](https://chillihub1.github.io/chillihub-joiner/?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId) .. ")", inline = false }
        },
        timestamp = os.date("!%Y-%m-%dT%TZ"),
        footer = { text = "Secret Brainrot Detector" }
    }
end

local function findAndNotifySecrets()
    local PlayerName = Player.DisplayName

    for _, v in ipairs(workspace.Plots:GetChildren()) do
        local sign = v:FindFirstChild("PlotSign")
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

        local podiums = v:FindFirstChild("AnimalPodiums")
        if not podiums then continue end

        for _, b in ipairs(podiums:GetChildren()) do
            local spawn = b:FindFirstChild("Base") and b.Base:FindFirstChild("Spawn")
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
                local cost = overhead:FindFirstChild("Price")
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

-- Server hopping logic with safe error handling and retry, without stopping script
local function getSuitableServer()
    local servers
    local success, err = pcall(function()
        servers = HttpService:JSONDecode(HttpService:GetAsync(
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        ))
    end)
    if not success or not servers or not servers.data then
        warn("Failed to get server list:", err)
        return nil
    end

    for _, server in ipairs(servers.data) do
        if server.playing >= 3 and server.playing <= 5 and server.id ~= game.JobId then
            return server
        end
    end

    return nil
end

local function teleportToServer(server)
    if server then
        print("Teleporting to server:", server.id, "with", server.playing, "players")
        -- Proper function usage of queue_on_teleport as per your instruction:
        queue_on_teleport(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bypassv5/find/refs/heads/main/main.lua"))()
        end)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
    else
        warn("No suitable server found, retrying in 10 seconds...")
        wait(2)
        local newServer = getSuitableServer()
        teleportToServer(newServer)
    end
end

-- Main loop to scan and notify, and then server hop
while true do
    findAndNotifySecrets()

    local serverToJoin = getSuitableServer()
    if serverToJoin then
        print("Attempting to teleport to server:", serverToJoin.id, "with", serverToJoin.playing, "players")

        -- Use queue_on_teleport to ensure the script reinjects after teleport
        queue_on_teleport(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bypassv5/find/refs/heads/main/main.lua"))()
        end)

        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverToJoin.id, Player)
        break -- Break the loop because teleporting
    else
        warn("No suitable server found, retrying in 10 seconds...")
        task.wait(10)
    end
end

-- Teleport failure handler to retry joining current server
TeleportService.TeleportInitFailed:Connect(function()
    warn("Teleport failed, retrying join current server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)

