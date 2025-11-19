-- Blox Fruits Auto Bounty Hunter v10 (Core)
-- Requires the config file to be loaded first (config.lua). The core reads _G.config.
-- Place this file in your executor and run it AFTER loading config.lua
-- NOTE: Some functions depend on exploit-provided features (syn, secure virtual input, http request),
-- the script attempts multiple fallbacks. Adjust in _G.config if needed.

-- Basic safety checks
if not _G or not _G.config then
    warn("[BountyCore] Missing _G.config - please load config.lua before running core.")
    return
end

local config = _G.config

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- State
local state = {
    enabled = true,
    in_pvp = false,
    current_target = nil,
    last_bounty = 0,
    hunting = false,
    last_hop_time = tick(),
    last_target_time = tick(),
    noclip_enabled = false,
}

-- Utilities / Executor compatibility
local request_fn = nil
if syn and syn.request then request_fn = syn.request
elseif http and http.request then request_fn = http.request
elseif (function_exists and function_exists("request")) and request then request_fn = request end

local send_key_event
do
    -- try various send-key APIs available on common executors
    local vim = rawget(game, "VirtualInputManager") -- many exploits expose Global VirtualInputManager
    if type(vim) == "table" and vim.SendKeyEvent then
        send_key_event = function(key, down)
            pcall(function() vim:SendKeyEvent(down, key, false, game) end)
        end
    elseif syn and syn.send_key then
        send_key_event = function(key, down)
            pcall(function() syn.send_key(key, down) end)
        end
    elseif function_exists and function_exists("sendkey") then
        send_key_event = function(key, down)
            pcall(function() sendkey(key, down) end)
        end
    else
        -- Best-effort fallback: try VirtualUser to emulate mouse/key (not precise)
        local vu = game:GetService("VirtualUser")
        send_key_event = function(key, down)
            -- VirtualUser only supports mouse button and touch events, so this is a noop for keys.
            -- We keep it so core can run even if key events do nothing.
        end
    end
end

-- Basic webhook sender
local function send_webhook(title, description, fields)
    if not config.webhook or not config.webhook.Enabled or not config.webhook.Url or config.webhook.Url == "" then
        return
    end
    local data = {
        username = config.webhook.Username or "BountyHunter",
        avatar_url = config.webhook.AvatarUrl or "",
        embeds = {{
            title = title or "BountyBot",
            description = description or "",
            color = 0x7A00FF,
            fields = {},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    if type(fields) == "table" then
        for _, f in ipairs(fields) do
            table.insert(data.embeds[1].fields, f)
        end
    end
    local body = HttpService:JSONEncode(data)
    local headers = { ["Content-Type"] = "application/json" }
    if request_fn then
        pcall(function()
            request_fn({ Url = config.webhook.Url, Method = "POST", Body = body, Headers = headers })
        end)
    else
        -- Attempt old http request
        if pcall(function() return (http_request or request) end) then
            pcall(function()
                (http_request or request)({
                    Url = config.webhook.Url,
                    Method = "POST",
                    Headers = headers,
                    Body = body
                })
            end)
        end
    end
end

-- Helper: get player's bounty (attempt multiple paths)
local function get_player_bounty(player)
    if not player then return 0 end
    -- common paths tried in top scripts
    local success, value = pcall(function()
        if player:FindFirstChild("Data") and player.Data:FindFirstChild("Bounty") then
            return player.Data.Bounty.Value
        elseif player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Bounty") then
            return player.leaderstats.Bounty.Value
        elseif player:FindFirstChild("Bounty") and player.Bounty:IsA("IntValue") then
            return player.Bounty.Value
        end
        return 0
    end)
    if success and type(value) == "number" then
        return value
    end
    return 0
end

local function get_player_level(player)
    if not player then return 0 end
    local success, value = pcall(function()
        if player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") then
            return player.Data.Level.Value
        elseif player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
            return player.leaderstats.Level.Value
        end
        return 0
    end)
    if success and type(value) == "number" then return value end
    return 0
end

-- Select best bounty target based on config
local function select_best_target()
    local me = LocalPlayer
    if not me.Character or not me.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = me.Character.HumanoidRootPart.Position
    local best, bestScore = nil, -math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Team ~= me.Team then
            local bounty = get_player_bounty(p)
            if bounty and bounty > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist <= (config.targeting.max_target_distance or 2000) then
                    local level = get_player_level(p)
                    local levelDiff = math.abs(level - get_player_level(me))
                    local score = 0
                    -- prefer higher bounty
                    score = score + (config.targeting.prefer_higher_bounty and bounty or 0) * 1.5
                    -- closer gets better
                    score = score - dist * 0.5
                    -- similar level preferred
                    if config.targeting.prefer_close_level then
                        score = score - math.max(0, levelDiff - (config.targeting.level_tolerance or 20)) * 10
                    end
                    -- penalize blacklisted players
                    if config.serverhop and config.serverhop.BlacklistPlayers then
                        for _, id in ipairs(config.serverhop.BlacklistPlayers) do
                            if p.UserId == id then score = score - 999999 end
                        end
                    end
                    if score > bestScore then bestScore, best = score, p end
                end
            end
        end
    end
    return best
end

-- Movement: Tween to target with optional flight (body velocities), returns instance of tween or coroutine
local function move_to_target_cframe(targetPos, followDistance)
    followDistance = followDistance or config.targeting.follow_distance or 6
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetCF = CFrame.new(targetPos) * CFrame.new(0, 0, -followDistance)
    local dist = (hrp.Position - targetPos).Magnitude
    local tweenInfo = TweenInfo.new(math.clamp(dist / 80, 0.2, 6), Enum.EasingStyle.Linear)
    pcall(function()
        TweenService:Create(hrp, tweenInfo, {CFrame = targetCF}):Play()
    end)
end

-- Try to enable PvP using common remote or command
local function try_enable_pvp(on)
    if not config.auto_toggle_pvp then return end
    pcall(function()
        -- Common toggle via remote:
        local success, _ = pcall(function()
            if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
                -- Many top scripts call "Toggle PVP" or "SetPVP" - we attempt safe invocations and ignore errors
                -- This is just an attempt; adjust to the correct remote signature if needed
                local comm = ReplicatedStorage.Remotes:FindFirstChild("CommF_")
                if comm then
                    -- generic "TogglePVP" may not exist; we'll also try to call client event (when available)
                    pcall(function() comm:InvokeServer("TogglePvp") end)
                    pcall(function() comm:InvokeServer("SetPVP", on) end)
                end
            end
        end)
        -- Some games require sending a chat command or UI click; we keep simple
    end)
end

-- NoClip: repeatedly set CanCollide = false on character parts
local function set_noclip(enabled)
    state.noclip_enabled = enabled
    if enabled then
        state._noclip_connection = RunService.Stepped:Connect(function()
            local ch = LocalPlayer.Character
            if ch then
                for _, part in ipairs(ch:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if state._noclip_connection then
            state._noclip_connection:Disconnect()
            state._noclip_connection = nil
        end
        -- restore collisions best-effort
        local ch = LocalPlayer.Character
        if ch then
            for _, part in ipairs(ch:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Simple flight (using BodyVelocity/BodyGyro) to a desired height when going safe
local function ascend_to_height(height)
    local ch = LocalPlayer.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- create BodyVelocity
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1500
    bv.Velocity = Vector3.new(0, 50, 0)
    bv.Parent = hrp
    local start = tick()
    local ok, err = pcall(function()
        repeat
            task.wait(0.2)
            if hrp.Position.Y >= height - 5 then break end
            bv.Velocity = Vector3.new(0, 50, 0)
        until tick() - start > 6
    end)
    pcall(function() bv:Destroy() end)
end

-- Auto-activate haki/ken (best-effort by sending the key)
local function auto_activate_ken()
    if not config.autoken then return end
    -- Many players have Observation Haki bound to 'V' or 'F' or by UI button.
    -- We'll attempt to send a few common keys quickly to toggle haki on.
    local keys = {'F', 'V', 'G', 'H'}
    for _, k in ipairs(keys) do
        pcall(function() send_key_event(k, true) end)
        task.wait(0.05)
        pcall(function() send_key_event(k, false) end)
        task.wait(0.1)
    end
end

-- Skill macro runner for a target. Runs configured sequences for weapon type (Melee, Sword, Blox Fruit, Gun)
local function run_skill_macro_for(target)
    if not target or not target.Character then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end

    -- Utility to press a key with hold time and repeat number
    local function press_key(key, count, hold)
        count = tonumber(count) or 1
        hold = tonumber(hold) or 0.12
        for i = 1, count do
            pcall(function() send_key_event(key, true) end)
            task.wait(hold)
            pcall(function() send_key_event(key, false) end)
            task.wait(config.methodclicks.Delay or 0.18)
        end
    end

    -- Based on which weapon the player has we choose macro; this is heuristic.
    -- We'll attempt Melee macro first, then Sword, Fruit, Gun.
    local function try_run_set(set)
        if not set or not set.Enable then return false end
        for key, info in pairs(set.Skills) do
            if info.Enable then
                press_key(key, info.Number, info.HoldTime)
            end
        end
        return true
    end

    -- Attempt sequences
    if config.custom["Blox Fruit"] and config.custom["Blox Fruit"].Enable then
        try_run_set(config.custom["Blox Fruit"])
    end
    if config.custom.Sword and config.custom.Sword.Enable then
        try_run_set(config.custom.Sword)
    end
    if config.custom.Melee and config.custom.Melee.Enable then
        try_run_set(config.custom.Melee)
    end
    if config.custom.Gun and config.custom.Gun.Enable then
        try_run_set(config.custom.Gun)
    end
end

-- Server hop implementation (basic): fetch server list from Roblox public API and teleport to a different server.
local function server_hop()
    if not config.serverhop or not config.serverhop.Enabled then return end
    if not config.advanced.use_teleport_service then return end

    local placeId = game.PlaceId
    local api = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    -- Attempt paged search until find different server instance id
    local visited = {}
    local myJobId = game.JobId

    local success, body = pcall(function() return game:HttpGet(api) end)
    if not success or not body then
        return
    end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not decoded or not decoded.data then return end

    for _, s in ipairs(decoded.data) do
        if s.playing and s.id and s.id ~= myJobId and (not s.public) == false then
            -- Teleport to this server
            if request_fn and config.webhook and config.webhook.Enabled and config.webhook.NotifyOnHop then
                send_webhook("Server Hop", ("Hopping to server %s (%d players)"):format(s.id, s.playing), {
                    { name = "Region", value = tostring(config.server_to_hop_region or "Unknown"), inline = true },
                    { name = "Current JobId", value = tostring(myJobId), inline = true },
                })
            end
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, s.id, LocalPlayer)
            end)
            return
        end
    end
end

-- Core hunt loop (runs in background)
spawn(function()
    -- UI initialization (minimal, draggable)
    -- Build a small GUI to show status, bounty, FPS/ping and control
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BountyHunterUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 340, 0, 180)
    mainFrame.Position = UDim2.new(0, 12, 0, 70)
    mainFrame.BackgroundColor3 = config.ui.theme.background or Color3.fromRGB(20,18,28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    -- draggable
    local dragging, dragInput, dragStart, startPos
    mainFrame.Active = true
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "Bounty Hunter v10"
    title.TextColor3 = config.ui.theme.text
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -10, 0, 30)
    statusLabel.Position = UDim2.new(0, 5, 0, 34)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = config.ui.theme.text
    statusLabel.Text = "Status: Idle"
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame

    local bountyLabel = Instance.new("TextLabel")
    bountyLabel.Name = "Bounty"
    bountyLabel.Size = UDim2.new(1, -10, 0, 26)
    bountyLabel.Position = UDim2.new(0, 5, 0, 68)
    bountyLabel.BackgroundTransparency = 1
    bountyLabel.TextColor3 = config.ui.theme.text
    bountyLabel.Text = "Bounty: 0"
    bountyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bountyLabel.Parent = mainFrame

    local logLabel = Instance.new("TextLabel")
    logLabel.Name = "Log"
    logLabel.Size = UDim2.new(1, -10, 0, 56)
    logLabel.Position = UDim2.new(0, 5, 0, 100)
    logLabel.BackgroundTransparency = 1
    logLabel.TextColor3 = config.ui.theme.text
    logLabel.Text = "Log: Ready"
    logLabel.TextWrapped = true
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.TextYAlignment = Enum.TextYAlignment.Top
    logLabel.Parent = mainFrame

    local function ui_log(s)
        if logLabel and logLabel.Parent then
            logLabel.Text = ("Log: %s"):format(tostring(s))
        end
    end

    -- Main hunting loop
    while state.enabled do
        pcall(function()
            -- refresh local values
            local myHealth = 0
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local hum = LocalPlayer.Character.Humanoid
                local maxH = hum.MaxHealth > 0 and hum.MaxHealth or 100
                myHealth = (hum.Health / maxH) * 100
            end

            -- safety: if health low, ascend and stop fighting
            if myHealth <= (config.safezone.LowestHealth or 35) then
                ui_log("Low HP, going safe...")
                set_noclip(true)
                ascend_to_height(config.targeting.flight_height or 80)
                try_enable_pvp(false)
                task.wait(2)
                -- let healing happen
                task.wait(5)
            else
                set_noclip(false)
            end

            -- choose or refresh target
            local target = state.current_target
            if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") or (tick() - state.last_target_time) > (config.time_to_skip or 80) then
                target = select_best_target()
                state.current_target = target
                state.last_target_time = tick()
            end

            -- update UI bounty
            local myB = 0
            if LocalPlayer and LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Bounty") then
                myB = LocalPlayer.Data.Bounty.Value
            end
            bountyLabel.Text = ("Bounty: %s"):format(tostring(myB))

            -- webhook on bounty change
            if config.webhook and config.webhook.Enabled and config.webhook.NotifyOnBountyChange and myB ~= state.last_bounty then
                local delta = myB - (state.last_bounty or 0)
                send_webhook("Bounty Changed", ("Your bounty is now %d (Δ %s)"):format(myB, (delta>=0 and "+" or "")..tostring(delta)), {
                    { name = "Server", value = tostring(config.server_to_hop_region or "Unknown"), inline = true },
                    { name = "Player", value = LocalPlayer.Name, inline = true }
                })
                state.last_bounty = myB
            end

            -- if target selected: engage
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                ui_log(("Hunting %s (Bounty=%d)"):format(target.Name, get_player_bounty(target)))
                -- enable pvp
                try_enable_pvp(true)
                -- attempt to get close to target
                local targetPos = target.Character.HumanoidRootPart.Position
                move_to_target_cframe(targetPos, config.targeting.follow_distance or 6)
                -- small wait to approach
                task.wait(math.clamp((LocalPlayer.Character.HumanoidRootPart.Position - targetPos).Magnitude / 90, 0.2, 1.5))
                -- run skill macro
                run_skill_macro_for(target)
                -- auto haki occasionally
                if config.autoken and math.random() < 0.25 then auto_activate_ken() end
                -- check distance and attack if close
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
                if dist <= (config.targeting.follow_distance or 6) + 2 then
                    -- Try a strong attack via VirtualInput or VirtualUser left click
                    pcall(function()
                        -- Left mouse button down/up to attack
                        local vu = game:GetService("VirtualUser")
                        vu:Button1Down(Vector2.new(0,0))
                        task.wait(0.05)
                        vu:Button1Up(Vector2.new(0,0))
                    end)
                end
            else
                ui_log("No target found. Waiting...")
                -- if no target for a while, hop server or refresh
                if (tick() - state.last_hop_time) > (config.time_to_hop or 600) then
                    state.last_hop_time = tick()
                    ui_log("Time to hop. Attempting server hop...")
                    if config.serverhop and config.serverhop.Enabled then
                        send_webhook("Server Hop", "No suitable targets found, attempting server hop.", nil)
                        server_hop()
                    end
                end
                task.wait(2)
            end

        end)
        task.wait(0.4)
    end
end)

-- Graceful stop function
local function stop_all()
    state.enabled = false
    set_noclip(false)
    try_enable_pvp(false)
    send_webhook("BountyScript", "Script stopped by player.", nil)
end

-- Expose stop function to _G for external control
_G.BountyHunterStop = stop_all

-- Notify started
send_webhook("BountyScript Started", ("Bounty Hunter v10 started for %s"):format(LocalPlayer.Name), {
    { name = "Config", value = HttpService:JSONEncode({ team = config.team, server = config.server_to_hop_region }), inline = true }
})

print("[BountyCore] Bounty Hunter v10 loaded. Use _G.BountyHunterStop() to stop.")