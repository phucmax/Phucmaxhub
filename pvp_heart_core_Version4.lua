-- Blox Fruits AUTO BOUNTY "TRÁI TIM V10" | Full UI, Ken không hiệu ứng, Race V3/V4, webhook, PvP, bounty

local config = _G.config
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-------------------- UI vuông tím fancy, kéo thả, toggle, logo, FPS/ping, bounty, log --------------------
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PvPHUB_UI"
ScreenGui.ResetOnSpawn = false
local dragFrame = Instance.new("Frame", ScreenGui)
dragFrame.Size = UDim2.new(0,340,0,174)
dragFrame.Position = UDim2.new(0, 20, 0, 48)
dragFrame.BackgroundColor3 = Color3.fromRGB(57,10,101)
dragFrame.BorderSizePixel = 2
dragFrame.BorderColor3 = Color3.fromRGB(172,82,237)
dragFrame.Active = true
dragFrame.Draggable = true

local logo = Instance.new("ImageLabel", dragFrame)
logo.Size = UDim2.new(0, 48, 0, 48)
logo.Position = UDim2.new(0, 14, 0, 8)
logo.BackgroundTransparency = 1
logo.Image = config.webhook.Logo

local title = Instance.new("TextLabel", dragFrame)
title.Size = UDim2.new(0, 230, 0, 30)
title.Position = UDim2.new(0, 72, 0, 14)
title.BackgroundTransparency = 1
title.TextStrokeTransparency = 0.2
title.TextStrokeColor3 = Color3.fromRGB(138,82,237)
title.TextColor3 = Color3.fromRGB(232,202,255)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Text = "PvP Hunter Hub v10"

local fpslabel = Instance.new("TextLabel", dragFrame)
fpslabel.Size = UDim2.new(0, 140, 0, 22)
fpslabel.Position = UDim2.new(0, 22, 0, 56)
fpslabel.BackgroundTransparency = 1
fpslabel.TextColor3 = Color3.fromRGB(176,138,247)
fpslabel.TextSize = 17
fpslabel.Font = Enum.Font.GothamSemibold
fpslabel.Text = "FPS: ... Ping: ..."

local scriptinfo = Instance.new("TextLabel", dragFrame)
scriptinfo.Size = UDim2.new(0, 160, 0, 24)
scriptinfo.Position = UDim2.new(0, 170, 0, 56)
scriptinfo.BackgroundTransparency = 1
scriptinfo.TextColor3 = Color3.fromRGB(187,158,254)
scriptinfo.TextSize = 17
scriptinfo.Font = Enum.Font.Gotham
scriptinfo.Text = "Đang khởi động..."

local bountylabel = Instance.new("TextLabel", dragFrame)
bountylabel.Size = UDim2.new(0, 288, 0, 32)
bountylabel.Position = UDim2.new(0, 22, 0, 90)
bountylabel.BackgroundTransparency = 1
bountylabel.TextStrokeTransparency = 0.1
bountylabel.TextStrokeColor3 = Color3.fromRGB(120,36,195)
bountylabel.TextColor3 = Color3.fromRGB(202,151,252)
bountylabel.TextSize = 20
bountylabel.Font = Enum.Font.GothamBlack
bountylabel.Text = "Bounty: ... "

local toggleButton = Instance.new("TextButton", dragFrame)
toggleButton.Size = UDim2.new(0, 30, 0, 30)
toggleButton.Position = UDim2.new(1, -36, 0, 2)
toggleButton.Text = "◼"
toggleButton.BackgroundColor3 = Color3.fromRGB(172,82,237)
toggleButton.TextColor3 = Color3.fromRGB(255,255,255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.ZIndex = 6
toggleButton.MouseButton1Click:Connect(function() dragFrame.Visible = not dragFrame.Visible end)

RunService.RenderStepped:Connect(function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    fpslabel.Text = "FPS: " .. fps .. " | Ping: " .. tostring(LocalPlayer:GetNetworkPing()*1000):sub(1,4).."ms"
end)

local lastBounty = 0
function getBounty()
    local stat = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Bounty")
    return stat and stat.Value or 0
end
function updateBountyLabel()
    bountylabel.Text = "Bounty: <b>" .. tostring(getBounty()) .. "</b>"
end

function sendWebhook(logtxt)
    if config.webhook and config.webhook.Enabled then
        pcall(function()
            local http = game:GetService("HttpService")
            local data = {
                ["content"] = "",
                ["embeds"] = {{
                    ["title"] = "Bounty Update",
                    ["description"] = "**Bounty hiện tại:** "..getBounty().."\n"..(logtxt or ""),
                    ["color"] = 13882084,
                    ["thumbnail"] = {["url"]=config.webhook.Logo}
                }}
            }
            http:PostAsync(config.webhook.Url, http:JSONEncode(data))
        end)
    end
end
spawn(function()
    while task.wait(4) do
        local curr = getBounty()
        if curr ~= lastBounty then
            local diff = curr - lastBounty
            sendWebhook((diff > 0 and "Tăng bounty +" or "Giảm bounty ") .. math.abs(diff))
            lastBounty = curr
        end
        updateBountyLabel()
    end
end)
function setScriptInfo(msg) scriptinfo.Text = msg end

-------------------- AUTO KEN (Observation | Haki Quan Sát) không hiệu ứng --------------------
function getKenStatus()
    local kenStats = LocalPlayer.Character:FindFirstChild("Ken")
    if kenStats then
        return kenStats.Value
    end
    return nil
end

function autoKenNoEffect()
    spawn(function()
        while config.autoKenNoEffect do
            pcall(function()
                local kenStats = getKenStatus()
                if not kenStats or kenStats < 1 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("ActivateKen")
                    for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
                        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Decal") then
                            v.Enabled = false
                        end
                        if (v:IsA("BasePart") and v.Name == "KenEffect") or v:IsA("Highlight") then
                            v:Destroy()
                        end
                    end
                end
            end)
            task.wait(0.42)
        end
    end)
end

-------------------- Auto Race V3/V4 --------------------
function autoRaceV3()
    if config.enablev3 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakening", "Buy") -- V3
        setScriptInfo("Auto Race V3!")
    end
end
function autoRaceV4()
    if config.enablev4 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("ActivateRaceV4")
        setScriptInfo("Auto Race V4!")
    end
end

-------------------- CORE AUTO BOUNTY: PvP, skill chains, safe mode, hop server --------------------
function getPlayerLevel(plr)
    local stat = plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Level")
    return stat and stat.Value or 0
end
function getBestTarget()
    local myLevel = getPlayerLevel(LocalPlayer)
    local best, mindist = nil, math.huge
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local lvl = getPlayerLevel(plr)
            if lvl <= myLevel and lvl >= myLevel-500 then
                local dist = (plr.Character.HumanoidRootPart.Position-LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < mindist then mindist = dist; best = plr end
            end
        end
    end
    return best
end

function autoEnablePvP()
    if LocalPlayer.PlayerGui.Main.PvpDisabled and LocalPlayer.PlayerGui.Main.PvpDisabled.Visible == true then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("EnablePvp")
        setScriptInfo("Bật PvP!")
    end
end

function autoNoClip()
    for _,p in pairs(LocalPlayer.Character:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end

function flyToTarget(target, speed)
    if not (target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame=target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
        hrp.Velocity=(target.Character.HumanoidRootPart.Position-hrp.Position).Unit *(speed or 350)
    end
end

function useSkill(toolType, key)
    local char = LocalPlayer.Character
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local mainSet = config.custom[toolType]
    if mainSet and mainSet.Enable and mainSet.Skills[key] and mainSet.Skills[key].Enable then
        game:GetService('VirtualInputManager'):SendKeyEvent(true,Enum.KeyCode[key],false,game)
        task.wait(mainSet.Skills[key].HoldTime or 0.1)
        setScriptInfo("Đánh "..toolType.." "..key.." lên mục tiêu!")
    end
end

function useAllSkills(target)
    for toolType, toolCFG in pairs(config.custom) do
        if toolCFG.Enable then
            for k, skillCFG in pairs(toolCFG.Skills) do
                useSkill(toolType, k)
            end
        end
    end
end

function autoDashAttack()
    game:GetService('VirtualInputManager'):SendKeyEvent(true,Enum.KeyCode.Q,false,game)
    game:GetService('VirtualInputManager'):SendMouseButtonEvent(0,true,false,false,false)
    setScriptInfo("Auto Q Dash và đánh thường")
end

function safeFly()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local minHP=hum.MaxHealth*(config.safezone.LowestHealth/100)
        local maxHP=hum.MaxHealth*(config.safezone.HighestHealth/100)
        if hum.Health<=minHP then
            setScriptInfo("Bay lên trời chờ hồi máu !")
            char.HumanoidRootPart.CFrame=CFrame.new(0,9999999,0)
            repeat task.wait(1)
                updateBountyLabel()
            until hum.Health>maxHP
            setScriptInfo("Hồi máu xong, bay xuống PvP!")
        end
    end
end

function checkKilled(target)
    return not (target.Character and target.Character:FindFirstChildOfClass("Humanoid") and target.Character:FindFirstChildOfClass("Humanoid").Health>0)
end

function autoHopServer()
    setScriptInfo("Đang đổi server!")
    -- Placeholder: TeleportService, hoặc dùng loader hub hop server
end

-------------------- MAIN LOOP: chạy mọi thứ --------------------
if config.autoKenNoEffect then autoKenNoEffect() end
autoRaceV3(); task.wait(1); autoRaceV4();

spawn(function()
    while true do
        pcall(function()
            autoEnablePvP()
            autoNoClip()
            local target = getBestTarget()
            if target then
                setScriptInfo("Mục tiêu: "..target.Name)
                local tStart = tick()
                repeat
                    flyToTarget(target, 350)
                    if config.autoQ then autoDashAttack() end
                    useAllSkills(target)
                    safeFly()
                    task.wait(0.22)
                until checkKilled(target) or (tick()-tStart>config.timetoskip)
                setScriptInfo("Target đã gục/skip, reload...")
            else
                autoHopServer()
                setScriptInfo("Đang hop server...")
                repeat wait(2) until not LocalPlayer.PlayerGui.Main.PvpDisabled.Visible
            end
            task.wait(1)
        end)
    end
end)