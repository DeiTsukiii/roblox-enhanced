-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables
local ESPs = {}
local Flying = false
local FlySpeed = 20
local FlyKey = Enum.KeyCode.U
local bodyVelocity, bodyGyro
local connections = {}

-- Settings
local ESPSettings = {
    Enabled = false,
    Box = true,
    Name = true,
    Snapline = true,
    VerifTeam = false,
}
local AimlockSettings = {
    Enabled = false,
    Key = Enum.KeyCode.P,
    VerifTeam = true,
    VerifyWall = true,
    BodyPart = "Head",
}

-- ====================
-- FLY
-- ====================
local function enableFly()
    if Flying then return end
    if not LocalPlayer.Character then return end

    RootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not RootPart or not Humanoid then return end

    Flying = true
    Humanoid.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = RootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.D = 500
    bodyGyro.CFrame = RootPart.CFrame
    bodyGyro.Parent = RootPart

    spawn(function()
        while Flying and bodyVelocity and bodyGyro do
            local camera = workspace.CurrentCamera
            local direction = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                direction = direction + Vector3.new(0, -1, 0)
            end

            if direction.Magnitude > 0 then
                direction = direction.Unit * FlySpeed
            end

            if bodyVelocity then
                bodyVelocity.Velocity = direction
            end
            if bodyGyro then
                bodyGyro.CFrame = CFrame.new(RootPart.Position, RootPart.Position + camera.CFrame.LookVector)
            end

            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end

            RunService.RenderStepped:Wait()
        end
    end)
end

local function disableFly()
    if not Flying then return end
    Flying = false

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    if Humanoid then
        Humanoid.PlatformStand = false
    end

    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- ====================
-- ESP
-- ====================
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPs[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1

    local name = Drawing.new("Text")
    name.Visible = false
    name.Center = true
    name.Size = 14
    name.Outline = true
    name.Text = player.Name

    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Thickness = 1

    ESPs[player] = {Box = box, Name = name, Snapline = snapline}
end

local function RemoveESP(player)
    local esp = ESPs[player]
    if not esp then return end
    for _, obj in pairs(esp) do
        if obj and obj.Remove then
            obj:Remove()
        end
    end
    ESPs[player] = nil
end

local function UpdateESP(player)
    if not ESPSettings.Enabled then return end
    if ESPSettings.VerifTeam and player.Team == LocalPlayer.Team then
        local esp = ESPs[player]
        if esp then
            for _, obj in pairs(esp) do obj.Visible = false end
        end
        return
    end
    local esp = ESPs[player]
    if not esp then return end

    local char = player.Character
    if not char then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not head or not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    local headPos3D = head.Position + Vector3.new(0, 0.5, 0)
    local footPos3D = root.Position - Vector3.new(0, humanoid.HipHeight, 0)
    local headPos2D, onScreenHead = Camera:WorldToViewportPoint(headPos3D)
    local footPos2D, onScreenFoot = Camera:WorldToViewportPoint(footPos3D)
    if not onScreenHead and not onScreenFoot then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    local color = Color3.fromRGB(255, 255, 255)
    if player.Team and player.Team.TeamColor then
        color = player.Team.TeamColor.Color
    end

    local height = math.abs(headPos2D.Y - footPos2D.Y)
    local width = height / 2
    local centerX = (headPos2D.X + footPos2D.X) / 2
    local centerY = (headPos2D.Y + footPos2D.Y) / 2

    -- Box
    if ESPSettings.Box then
        esp.Box.Visible = true
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Position = Vector2.new(centerX - width/2, centerY - height/2)
        esp.Box.Color = color
    else
        esp.Box.Visible = false
    end

    -- Username
    if ESPSettings.Name then
        esp.Name.Visible = true
        esp.Name.Text = player.Name
        esp.Name.Position = Vector2.new(headPos2D.X, headPos2D.Y - 20)
        esp.Name.Color = color
    else
        esp.Name.Visible = false
    end

    -- Snapline
    if ESPSettings.Snapline then
        esp.Snapline.Visible = true
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y - 100)
        esp.Snapline.To = Vector2.new(centerX, centerY + height/2)
        esp.Snapline.Color = color
    else
        esp.Snapline.Visible = false
    end
end

-- ====================
-- AIMLOCK
-- ====================
function AimLock()
    if not AimlockSettings.Enabled then return end
    local target
    local lastDist = math.huge
    local cam = workspace.CurrentCamera
    for _, v in pairs(Players:GetPlayers()) do
        local verifTeam = not AimlockSettings.VerifTeam or v.Team ~= LocalPlayer.Team
        if v ~= LocalPlayer and verifTeam and v.Character and v.Character:FindFirstChild(AimlockSettings.BodyPart) then
            local headPos = v.Character[AimlockSettings.BodyPart].Position

            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.IgnoreWater = true

            local rayResult = workspace:Raycast(cam.CFrame.Position, (headPos - cam.CFrame.Position), rayParams)
            local canSee = not rayResult or rayResult.Instance:IsDescendantOf(v.Character)
            if not AimlockSettings.VerifyWall or canSee then
                local dist = (headPos - cam.CFrame.Position).Magnitude
                if dist < lastDist then
                    lastDist = dist
                    target = v
                end
            end
        end
    end

    if target and target.Character and target.Character:FindFirstChild(AimlockSettings.BodyPart) then
        local headPos = target.Character[AimlockSettings.BodyPart].Position
        cam.CFrame = CFrame.new(cam.CFrame.Position, headPos)
    end
end

-- ====================
-- EVENTS
-- ====================
table.insert(connections, Players.PlayerAdded:Connect(CreateESP))
table.insert(connections, Players.PlayerRemoving:Connect(RemoveESP))
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

local AimlockToggle
local FlyToggle
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AimlockSettings.Key then
        AimlockToggle:Set(not AimlockSettings.Enabled)
    elseif input.KeyCode == FlyKey then
        FlyToggle:Set(not Flying)
    end
end))

-- ====================
-- RENDER
-- ====================
table.insert(connections, RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and ESPSettings.Enabled then
            UpdateESP(player)
        end
    end

    if AimlockSettings.Enabled then
        AimLock()
    end
end))

-- ====================
-- CREATE UI
-- ====================
local Window = Rayfield:CreateWindow({
   Name = "Roblox Enhanced",
   Icon = 111899568071911,
   LoadingTitle = "Roblox Enhanced",
   LoadingSubtitle = "by DeiTsuki",
   ShowText = "Roblox Enhanced",
   Theme = "Default",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

local HomeTab = Window:CreateTab("Home", 14219650242)
HomeTab:CreateLabel("Welcome to Roblox Enhanced!")
HomeTab:CreateLabel("Created by DeiTsuki")
HomeTab:CreateButton({
    Name = "My Github",
    Callback = function()
        setclipboard("https://github.com/DeiTsukiii")
        Rayfield:Notify({
            Title = "Copied to Clipboard",
            Content = "Github link has been copied to clipboard.",
            Duration = 5
        })
    end
})
HomeTab:CreateDropdown({
   Name = "Theme",
   Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
   CurrentOption = {"Default"},
   MultipleOptions = false,
   Flag = "Theme",
   Callback = function(Options)
        Window.ModifyTheme(Options[1])
   end,
})
HomeTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        for _, conn in pairs(connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        connections = {}
        disableFly()
        for _, player in pairs(Players:GetPlayers()) do
            RemoveESP(player)
        end
        Rayfield:Destroy()
    end
})

local EspTab = Window:CreateTab("ESP", 4483362458)
EspTab:CreateToggle({
   Name = "Enabled",
   CurrentValue = false,
   Flag = "ToggleESP",
   Callback = function(Value)
        ESPSettings.Enabled = Value
        if not ESPSettings.Enabled then
            for _, esp in pairs(ESPs) do
                for _, obj in pairs(esp) do
                    obj.Visible = false
                end
            end
        end
   end,
})
EspTab:CreateToggle({
   Name = "Box",
   CurrentValue = ESPSettings.Box,
   Flag = "ToggleESPBox",
   Callback = function(Value)
        ESPSettings.Box = Value
   end,
})
EspTab:CreateToggle({
   Name = "Name",
   CurrentValue = ESPSettings.Name,
   Flag = "ToggleESPName",
   Callback = function(Value)
        ESPSettings.Name = Value
   end,
})
EspTab:CreateToggle({
   Name = "Snapline",
   CurrentValue = ESPSettings.Snapline,
   Flag = "ToggleESPSnapline",
   Callback = function(Value)
        ESPSettings.Snapline = Value
   end,
})
EspTab:CreateToggle({
   Name = "Verify Team",
   CurrentValue = ESPSettings.VerifTeam,
   Flag = "ToggleESPVerifTeam",
   Callback = function(Value)
        ESPSettings.VerifTeam = Value
   end,
})

local AimlockTab = Window:CreateTab("Aimlock", 126193793480527)
AimlockToggle = AimlockTab:CreateToggle({
   Name = "Enabled",
   CurrentValue = false,
   Flag = "ToggleAimlock",
   Callback = function(Value)
        AimlockSettings.Enabled = Value
   end,
})
local AimlockKeyInput
AimlockKeyInput = AimlockTab:CreateInput({
   Name = "Toggle Key",
   CurrentValue = "P",
   PlaceholderText = "P",
   RemoveTextAfterFocusLost = false,
   Flag = "AimlockKey",
   Callback = function(Text)
        local success, key = pcall(function() return Enum.KeyCode[Text] end)
        if success and key then
            AimlockSettings.Key = key
        else
            AimlockKeyInput:Set("P")
            Rayfield:Notify({
                Title = "Invalid Key",
                Content = "Please enter a valid key.",
                Duration = 5
            })
        end
   end,
})
AimlockTab:CreateToggle({
   Name = "Verify Team",
   CurrentValue = AimlockSettings.VerifTeam,
   Flag = "ToggleAimlockVerifTeam",
   Callback = function(Value)
        AimlockSettings.VerifTeam = Value
   end,
})
AimlockTab:CreateToggle({
   Name = "Verify Wall",
   CurrentValue = AimlockSettings.VerifyWall,
   Flag = "ToggleAimlockVerifyWall",
   Callback = function(Value)
        AimlockSettings.VerifyWall = Value
   end,
})
AimlockTab:CreateDropdown({
   Name = "Body Part",
   Options = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "AimlockBodyPart",
   Callback = function(Options)
        AimlockSettings.BodyPart = Options[1]
   end,
})

local PlayersTab = Window:CreateTab("Players", 81489458260315)
local SelectedPlayer = nil

local SelectedPlayerDropdown = PlayersTab:CreateDropdown({
   Name = "Selected Player",
   Options = {"N/A"},
   CurrentOption = {"N/A"},
   MultipleOptions = false,
   Flag = "SelectedPlayer",
   Callback = function(Options)
       SelectedPlayer = Options[1]
   end,
})

local function refreshPlayerList()
    local options = {"N/A"}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(options, player.Name)
        end
    end
    SelectedPlayerDropdown:Refresh(options)
end

refreshPlayerList()
table.insert(connections, Players.PlayerAdded:Connect(refreshPlayerList))
table.insert(connections, Players.PlayerRemoving:Connect(refreshPlayerList))

PlayersTab:CreateButton({
    Name = "Spectate",
    Callback = function()
        if SelectedPlayer and SelectedPlayer ~= "N/A" then
            local player = Players:FindFirstChild(SelectedPlayer)
            if player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and workspace.CurrentCamera then
                    workspace.CurrentCamera.CameraSubject = humanoid
                end
            end
        end
    end
})

PlayersTab:CreateButton({
    Name = "Stop Spectating",
    Callback = function()
        if workspace.CurrentCamera and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                workspace.CurrentCamera.CameraSubject = humanoid
            end
        end
    end
})

PlayersTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if SelectedPlayer and SelectedPlayer ~= "N/A" then
            local player = Players:FindFirstChild(SelectedPlayer)
            if player and player.Character and LocalPlayer.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and myRoot then
                    myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end
})

local MeTab = Window:CreateTab("Misc", 16181361436)

-- WalkSpeed
MeTab:CreateSection("Speed & Jump")
MeTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 1000},
   Increment = 1,
   Suffix = "WalkSpeed",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Value
        end
   end,
})

-- JumpPower
MeTab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 500},
   Increment = 1,
   Suffix = "JumpPower",
   CurrentValue = 50,
   Flag = "JumpPower",
   Callback = function(Value)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = Value
        end
   end,
})

-- Fly
MeTab:CreateSection("Fly")
FlyToggle = MeTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(Value)
        if Value then
            enableFly()
        else
            disableFly()
        end
    end
})

MeTab:CreateSlider({
   Name = "Fly Speed",
   Range = {20, 300},
   Increment = 1,
   Suffix = "FlySpeed",
   CurrentValue = 20,
   Flag = "FlySpeed",
   Callback = function(Value)
        FlySpeed = Value
   end,
})

local FlyKeyInput
FlyKeyInput = MeTab:CreateInput({
   Name = "Toggle Key",
   CurrentValue = "U",
   PlaceholderText = "U",
   RemoveTextAfterFocusLost = false,
   Flag = "FlyKey",
   Callback = function(Text)
        local success, key = pcall(function() return Enum.KeyCode[Text] end)
        if success and key then
            FlyKey = key
        else
            FlyKeyInput:Set("U")
            Rayfield:Notify({
                Title = "Invalid Key",
                Content = "Please enter a valid key.",
                Duration = 5
            })
        end
   end,
})

-- HipHeight
MeTab:CreateSection("Fun Settings")
MeTab:CreateSlider({
   Name = "Hip Height",
   Range = {0, 50},
   Increment = 0.5,
   Suffix = "HipHeight",
   CurrentValue = 2,
   Flag = "HipHeight",
   Callback = function(Value)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HipHeight = Value
        end
   end,
})

-- Gravity
MeTab:CreateSlider({
   Name = "Gravity",
   Range = {0, 500},
   Increment = 1,
   Suffix = "Gravity",
   CurrentValue = workspace.Gravity,
   Flag = "Gravity",
   Callback = function(Value)
        workspace.Gravity = Value
   end,
})

MeTab:CreateSection("Additional Options")
-- Unban VC
MeTab:CreateButton({
    Name = "Unban VC",
    Callback = function()
        voiceChatService = game:GetService("VoiceChatService")
        voiceChatService:joinVoice()
    end
})

-- Talentless
MeTab:CreateButton({
    Name = "Piano - Talentless",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hellohellohell012321/TALENTLESS/main/TALENTLESS", true))()
    end
})
