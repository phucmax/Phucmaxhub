--// UI Loading Screen với Logo + chữ "phucmaxtonghop" dưới logo

local ScreenGui = Instance.new("ScreenGui")
local LoadingFrame = Instance.new("Frame")
local Logo = Instance.new("ImageLabel")
local LogoText = Instance.new("TextLabel") -- thêm dòng chữ dưới logo
local Title = Instance.new("TextLabel")
local ProgressBarBackground = Instance.new("Frame")
local ProgressBar = Instance.new("Frame")

-- Parent vào CoreGui
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

-- Khung loading
LoadingFrame.Parent = ScreenGui
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingFrame.Size = UDim2.new(0, 300, 0, 240)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.BackgroundTransparency = 0.1
LoadingFrame.ClipsDescendants = true

-- Bo góc loading frame
local UICorner1 = Instance.new("UICorner", LoadingFrame)
UICorner1.CornerRadius = UDim.new(0, 12)

-- Viền đỏ phát sáng
local UIStrokeLoading = Instance.new("UIStroke", LoadingFrame)
UIStrokeLoading.Thickness = 3
UIStrokeLoading.Color = Color3.fromRGB(255, 0, 0)
UIStrokeLoading.Transparency = 0.3

-- Logo
Logo.Parent = LoadingFrame
Logo.BackgroundTransparency = 1
Logo.Size = UDim2.new(0, 60, 0, 60)
Logo.Position = UDim2.new(0.1, -20, 0.35, 18)
Logo.Image = "rbxassetid://114009263825021"
Logo.ImageTransparency = 0

-- Bo công 4 góc cho Logo
local UICornerLogo = Instance.new("UICorner")
UICornerLogo.CornerRadius = UDim.new(0, 4)-- bo tròn hoàn toàn
UICornerLogo.Parent = Logo 
-- Viền phát sáng cho logo
local UIStrokeLogo = Instance.new("UIStroke", Logo)
UIStrokeLogo.Color = Color3.fromRGB(255, 0, 0)
UIStrokeLogo.Thickness = 2
UIStrokeLogo.Transparency = 0.3

Title.Name = "Title"
Title.Parent = LoadingFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0.2, -25, 0.4, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "PHUCMAXTONGHOP"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.TextStrokeTransparency = 0.5
Title.TextSize = 25

-- Nền progress bar
ProgressBarBackground.Parent = LoadingFrame
ProgressBarBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ProgressBarBackground.Position = UDim2.new(0.1, 0, 0.8, 0)
ProgressBarBackground.Size = UDim2.new(0.8, 0, 0.08, 0)
ProgressBarBackground.BorderSizePixel = 0

-- Bo góc nền progress bar
local UICorner2 = Instance.new("UICorner", ProgressBarBackground)
UICorner2.CornerRadius = UDim.new(0, 6)

-- Thanh chạy
ProgressBar.Parent = ProgressBarBackground
ProgressBar.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BorderSizePixel = 0

-- Bo góc thanh chạy
local UICorner3 = Instance.new("UICorner", ProgressBar)
UICorner3.CornerRadius = UDim.new(0, 6)

--// Animation Loading Bar
task.spawn(function()
    for i = 1, 100 do
        ProgressBar.Size = UDim2.new(i/100, 0, 1, 0)

        -- Tăng đỏ dần
        local red = 100 + (155 * (i/100))
        ProgressBar.BackgroundColor3 = Color3.fromRGB(red, 0, 0)

        wait(0.02)
    end

    wait(0.5)
    ScreenGui:Destroy()

    -- Load script chính
    loadstring(game:HttpGet("https://raw.githubusercontent.com/phucmax/Nhincccc/refs/heads/main/script%20nha%20lam.lua"))()
    
    local HttpService = game:GetService("HttpService")
    local webhookUrl = "https://discord.com/api/webhooks/1366072947059720244/EXQVV59GImlIrepYC4F36vKgQMnfIUd1ZGkXJlDG_CUmOuWKIj6AHDeVpJ4EwvXXKbPc"
    
    local data = {
        ["content"] = "**Script đã được chạy!**\nUser: " .. game.Players.LocalPlayer.Name
    }

    local finalData = HttpService:JSONEncode(data)

    pcall(function()
        (syn and syn.request or http_request)({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = finalData
        })
    end)
end)