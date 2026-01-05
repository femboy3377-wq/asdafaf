--[[
    ⚡ HITADORO CHANGER [HYBRID VERSION]
    Логика: Оригинальная (Old System) + Поддержка R6
    Дизайн: Новый (Remastered)
    Ключ: hitadoro
    Скрытие: Клавиша 'K'
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- // НАСТРОЙКИ UI //
local THEME = {
    Background = Color3.fromRGB(10, 10, 12),
    Section    = Color3.fromRGB(18, 18, 22),
    Accent     = Color3.fromRGB(255, 215, 0), -- Золотой
    AccentDark = Color3.fromRGB(180, 150, 0),
    Text       = Color3.fromRGB(240, 240, 240),
    SubText    = Color3.fromRGB(150, 150, 150),
    Error      = Color3.fromRGB(255, 60, 60),
    Success    = Color3.fromRGB(60, 255, 100)
}

-- // ГЛАВНАЯ ФУНКЦИЯ ЗАПУСКА //
local function RunMainScript()
    -- Удаляем старый GUI
    if CoreGui:FindFirstChild("HitadoroRemastered") then
        CoreGui.HitadoroRemastered:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HitadoroRemastered"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    -- ==========================================
    --      СТАРАЯ СИСТЕМА КОПИРОВАНИЯ (ORIGINAL)
    -- ==========================================

    local usedSkins = {}

    local function addToLeaderboard(userId, username)
        if not usedSkins[userId] then
            usedSkins[userId] = {
                username = username,
                count = 1,
                lastUsed = os.time()
            }
        else
            usedSkins[userId].count = usedSkins[userId].count + 1
            usedSkins[userId].lastUsed = os.time()
        end
    end

    local function clearVisuals(character)
        if not character then return end

        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants")
            or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
                obj:Destroy()
            end
        end

        local head = character:FindFirstChild("Head")
        if head then
            for _, decal in ipairs(head:GetChildren()) do
                if decal:IsA("Decal") and decal.Name:lower() == "face" then
                    decal:Destroy()
                end
            end
        end

        local bodyColors = character:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            bodyColors:Destroy()
        end
    end

    local function attachAccessory(character, accessoryClone)
        local handle = accessoryClone:FindFirstChild("Handle")
        if not handle then return end

        local attachment = handle:FindFirstChildOfClass("Attachment")
        local targetPart = nil
        local targetAttachment = nil

        if attachment then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("Attachment") and part.Name == attachment.Name then
                    targetAttachment = part
                    targetPart = part.Parent
                    break
                end
            end
        end

        if targetAttachment and targetPart then
            handle.CFrame = targetAttachment.WorldCFrame * (attachment.CFrame:Inverse())
        else
            targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                handle.CFrame = targetPart.CFrame
            end
        end

        if targetPart then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = targetPart
            weld.Parent = handle
        end

        accessoryClone.Parent = character
    end

    local function applyBodyParts(character, sourceAppearance)
        for _, mesh in ipairs(character:GetDescendants()) do
            if mesh:IsA("CharacterMesh") then
                mesh:Destroy()
            end
        end

        for _, item in ipairs(sourceAppearance:GetDescendants()) do
            if item:IsA("CharacterMesh") then
                local meshClone = item:Clone()
                meshClone.Parent = character
            end
        end
    end

    local function applyBodyScaling(character, sourceAppearance)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local sourceHumanoid = sourceAppearance:FindFirstChildOfClass("Humanoid")
        if not sourceHumanoid then return end

        -- Поддержка R6 и R15
        if humanoid.RigType == Enum.HumanoidRigType.R15 then
            humanoid.BodyHeightScale = sourceHumanoid.BodyHeightScale or humanoid.BodyHeightScale
            humanoid.BodyWidthScale = sourceHumanoid.BodyWidthScale or humanoid.BodyWidthScale
            humanoid.BodyDepthScale = sourceHumanoid.BodyDepthScale or humanoid.BodyDepthScale
            humanoid.HeadScale = sourceHumanoid.HeadScale or humanoid.HeadScale
        else -- R6
            humanoid.BodyHeightScale = sourceHumanoid.BodyHeightScale or 1
            humanoid.BodyWidthScale = sourceHumanoid.BodyWidthScale or 1
            humanoid.BodyDepthScale = sourceHumanoid.BodyDepthScale or 1
            humanoid.HeadScale = sourceHumanoid.HeadScale or 1
        end
    end

    local function applyAppearance(userId)
        if not userId or typeof(userId) ~= "number" then
            warn("[Hitadoro] Invalid UserId")
            return false
        end

        local character = LocalPlayer.Character
        if not character then
            warn("[Hitadoro] Character not loaded")
            return false
        end

        -- Headless support
        if userId == 134082579 then
            local head = character:FindFirstChild("Head")
            if head then
                head.Transparency = 1
                for _, decal in ipairs(head:GetChildren()) do
                    if decal:IsA("Decal") then
                        decal.Transparency = 1
                    end
                end
            end
            return true
        end

        local success, appearanceModel = pcall(function()
            return Players:GetCharacterAppearanceAsync(userId)
        end)

        if not success or not appearanceModel then
            warn("[Hitadoro] Failed to get avatar for UserId: " .. userId)
            return false
        end

        clearVisuals(character)

        -- Copy BodyColors
        local bodyColors = appearanceModel:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            bodyColors:Clone().Parent = character
        end

        -- Copy clothing
        for _, item in ipairs(appearanceModel:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                item:Clone().Parent = character
            end
        end

        -- Copy accessories
        for _, acc in ipairs(appearanceModel:GetChildren()) do
            if acc:IsA("Accessory") then
                local clone = acc:Clone()
                attachAccessory(character, clone)
            end
        end

        -- Copy face
        local head = character:FindFirstChild("Head")
        if head then
            local face = appearanceModel:FindFirstChild("face", true)
            if face and face:IsA("Decal") then
                local faceClone = face:Clone()
                faceClone.Parent = head
            end
        end

        applyBodyParts(character, appearanceModel)
        applyBodyScaling(character, appearanceModel)

        return true
    end

    -- ==========================================
    --            НОВЫЙ UI (REMASTERED)
    -- ==========================================

    -- Main Container (Draggable)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -300)
    MainFrame.BackgroundColor3 = THEME.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Rounded Corners
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame

    -- Stroke (Border)
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = THEME.Accent
    MainStroke.Thickness = 2
    MainStroke.Transparency = 0.5
    MainStroke.Parent = MainFrame

    -- HEADER
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 70)
    Header.BackgroundColor3 = THEME.Section
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 10)
    HeaderFix.Position = UDim2.new(0, 0, 1, -10)
    HeaderFix.BackgroundColor3 = THEME.Section
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header

    -- Player Avatar
    local PlayerIcon = Instance.new("ImageLabel")
    PlayerIcon.Size = UDim2.new(0, 50, 0, 50)
    PlayerIcon.Position = UDim2.new(0, 15, 0, 10)
    PlayerIcon.BackgroundColor3 = THEME.Background
    PlayerIcon.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    PlayerIcon.Parent = Header

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(1, 0)
    IconCorner.Parent = PlayerIcon

    local IconStroke = Instance.new("UIStroke")
    IconStroke.Color = THEME.Accent
    IconStroke.Thickness = 1
    IconStroke.Parent = PlayerIcon

    -- Title Info
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = "HITADORO CHANGER"
    TitleLabel.Size = UDim2.new(0, 200, 0, 25)
    TitleLabel.Position = UDim2.new(0, 80, 0, 12)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextSize = 22
    TitleLabel.TextColor3 = THEME.Accent
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local UserLabel = Instance.new("TextLabel")
    UserLabel.Text = "Welcome, " .. LocalPlayer.Name
    UserLabel.Size = UDim2.new(0, 200, 0, 20)
    UserLabel.Position = UDim2.new(0, 80, 0, 38)
    UserLabel.BackgroundTransparency = 1
    UserLabel.Font = Enum.Font.GothamMedium
    UserLabel.TextSize = 14
    UserLabel.TextColor3 = THEME.SubText
    UserLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserLabel.Parent = Header

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "×"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0, 20)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextColor3 = THEME.SubText
    CloseBtn.TextSize = 30
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.Parent = Header

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- CONTENT SCROLLING
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -20, 1, -80)
    Scroll.Position = UDim2.new(0, 10, 0, 80)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = THEME.Accent
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.CanvasSize = UDim2.new(0,0,0,0)
    Scroll.BorderSizePixel = 0
    Scroll.Parent = MainFrame

    local UIList = Instance.new("UIListLayout")
    UIList.Padding = UDim.new(0, 10)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Parent = Scroll

    local UIPad = Instance.new("UIPadding")
    UIPad.PaddingLeft = UDim.new(0, 5)
    UIPad.PaddingRight = UDim.new(0, 5)
    UIPad.PaddingTop = UDim.new(0, 5)
    UIPad.Parent = Scroll

    -- Helper Functions for UI Elements
    local function CreateSectionTitle(text)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 0, 30)
        Frame.BackgroundTransparency = 1
        Frame.Parent = Scroll

        local Label = Instance.new("TextLabel")
        Label.Text = text
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = THEME.Accent
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame
    end

    local function CreateInputField(placeholder, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 45)
        Container.BackgroundColor3 = THEME.Section
        Container.BorderSizePixel = 0
        Container.Parent = Scroll

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Container

        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(1, -20, 1, 0)
        Box.Position = UDim2.new(0, 10, 0, 0)
        Box.BackgroundTransparency = 1
        Box.PlaceholderText = placeholder
        Box.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        Box.Text = ""
        Box.TextColor3 = THEME.Text
        Box.Font = Enum.Font.Gotham
        Box.TextSize = 14
        Box.TextXAlignment = Enum.TextXAlignment.Left
        Box.ClearTextOnFocus = false
        Box.Parent = Container

        Box:GetPropertyChangedSignal("Text"):Connect(function()
            callback(Box.Text)
        end)
    end

    local function CreateButton(text, icon, callback)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, 0, 0, 45)
        Btn.BackgroundColor3 = THEME.Section
        Btn.AutoButtonColor = false
        Btn.Text = ""
        Btn.Parent = Scroll

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Btn

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = THEME.Section
        Stroke.Thickness = 1
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Parent = Btn

        local Label = Instance.new("TextLabel")
        Label.Text = text
        Label.Size = UDim2.new(1, -50, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = THEME.Text
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Btn

        local IconLabel = Instance.new("TextLabel")
        IconLabel.Text = icon
        IconLabel.Size = UDim2.new(0, 30, 1, 0)
        IconLabel.Position = UDim2.new(1, -35, 0, 0)
        IconLabel.BackgroundTransparency = 1
        IconLabel.TextColor3 = THEME.Accent
        IconLabel.Font = Enum.Font.Gotham
        IconLabel.TextSize = 18
        IconLabel.Parent = Btn

        -- Hover Animation
        Btn.MouseEnter:Connect(function()
            TweenService:Create(Stroke, TweenInfo.new(0.2), {Color = THEME.Accent}):Play()
            TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = THEME.Accent}):Play()
        end)

        Btn.MouseLeave:Connect(function()
            TweenService:Create(Stroke, TweenInfo.new(0.2), {Color = THEME.Section}):Play()
            TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = THEME.Text}):Play()
        end)

        Btn.MouseButton1Click:Connect(function()
            Btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
            task.wait(0.1)
            Btn.BackgroundColor3 = THEME.Section
            callback()
        end)
    end

    -- NOTIFICATION SYSTEM
    local function Notify(title, msg, isError)
        local Notif = Instance.new("Frame")
        Notif.Size = UDim2.new(0, 280, 0, 70)
        Notif.Position = UDim2.new(1, 20, 0.85, 0)
        Notif.BackgroundColor3 = THEME.Section
        Notif.BorderSizePixel = 0
        Notif.Parent = ScreenGui

        local NCorner = Instance.new("UICorner")
        NCorner.CornerRadius = UDim.new(0, 8)
        NCorner.Parent = Notif

        local NStroke = Instance.new("UIStroke")
        NStroke.Color = isError and THEME.Error or THEME.Accent
        NStroke.Thickness = 1.5
        NStroke.Parent = Notif

        local NTitle = Instance.new("TextLabel")
        NTitle.Text = title
        NTitle.Size = UDim2.new(1, -20, 0, 25)
        NTitle.Position = UDim2.new(0, 10, 0, 5)
        NTitle.BackgroundTransparency = 1
        NTitle.TextColor3 = isError and THEME.Error or THEME.Accent
        NTitle.Font = Enum.Font.GothamBold
        NTitle.TextSize = 14
        NTitle.TextXAlignment = Enum.TextXAlignment.Left
        NTitle.Parent = Notif

        local NMsg = Instance.new("TextLabel")
        NMsg.Text = msg
        NMsg.Size = UDim2.new(1, -20, 0, 35)
        NMsg.Position = UDim2.new(0, 10, 0, 30)
        NMsg.BackgroundTransparency = 1
        NMsg.TextColor3 = THEME.Text
        NMsg.Font = Enum.Font.Gotham
        NMsg.TextSize = 12
        NMsg.TextWrapped = true
        NMsg.TextXAlignment = Enum.TextXAlignment.Left
        NMsg.TextYAlignment = Enum.TextYAlignment.Top
        NMsg.Parent = Notif

        Notif:TweenPosition(UDim2.new(1, -300, 0.85, 0), "Out", "Back", 0.5)

        task.delay(3, function()
            local tween = TweenService:Create(Notif, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0.85, 0)})
            tween:Play()
            tween.Completed:Connect(function() Notif:Destroy() end)
        end)
    end

    -- POPULATE UI
    CreateSectionTitle("🎯 COPY BY ID")
    local idInput = ""
    CreateInputField("Enter UserID (e.g. 1)", function(t) idInput = t end)
    CreateButton("Apply UserID", "➜", function()
        local uid = tonumber(idInput)
        if uid then
            if applyAppearance(uid) then
                addToLeaderboard(uid, "Unknown")
                Notify("Success", "Copied ID: " .. uid, false)
            else
                Notify("Error", "Failed to copy ID", true)
            end
        else
            Notify("Error", "Please enter a valid number", true)
        end
    end)

    CreateSectionTitle("👤 COPY BY USERNAME")
    local nameInput = ""
    CreateInputField("Enter Username (e.g. Roblox)", function(t) nameInput = t end)
    CreateButton("Apply Username", "➜", function()
        if nameInput ~= "" then
            local s, uid = pcall(function() return Players:GetUserIdFromNameAsync(nameInput) end)
            if s and uid then
                if applyAppearance(uid) then
                    addToLeaderboard(uid, nameInput)
                    Notify("Success", "Copied: " .. nameInput, false)
                else
                    Notify("Error", "Failed to copy appearance", true)
                end
            else
                Notify("Error", "User not found", true)
            end
        end
    end)

    CreateSectionTitle("⚡ QUICK ACTIONS")
    CreateButton("Headless Horseman", "👻", function()
        applyAppearance(134082579)
        addToLeaderboard(134082579, "Headless")
        Notify("Applied", "Headless applied!", false)
    end)

    CreateButton("Reset Character", "🔄", function()
        if LocalPlayer.Character then LocalPlayer.Character:Destroy() end
        LocalPlayer:LoadCharacter()
    end)

    CreateSectionTitle("⚙️ SETTINGS")
    local BindLabel = Instance.new("TextLabel")
    BindLabel.Text = "Press 'K' to Hide/Show Menu"
    BindLabel.Size = UDim2.new(1, 0, 0, 30)
    BindLabel.BackgroundTransparency = 1
    BindLabel.TextColor3 = THEME.SubText
    BindLabel.Font = Enum.Font.Gotham
    BindLabel.TextSize = 12
    BindLabel.Parent = Scroll

    -- DRAGGING
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- KEYBIND TOGGLE (K)
    local isVisible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.K then
            isVisible = not isVisible
            if isVisible then
                MainFrame.Visible = true
                MainFrame:TweenSize(UDim2.new(0, 520, 0, 600), "Out", "Back", 0.4, true)
            else
                MainFrame:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Back", 0.4, true, function()
                    if not isVisible then MainFrame.Visible = false end
                end)
            end
        end
    end)

    Notify("Hitadoro", "Script Loaded. Press K to toggle.", false)
end

-- // СИСТЕМА КЛЮЧА //
local function StartKeySystem()
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "HitadoroKey"
    KeyGui.Parent = CoreGui

    local Backdrop = Instance.new("Frame")
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.new(0,0,0)
    Backdrop.BackgroundTransparency = 0.5
    Backdrop.Parent = KeyGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 350, 0, 180)
    Frame.Position = UDim2.new(0.5, -175, 0.5, -90)
    Frame.BackgroundColor3 = THEME.Background
    Frame.BorderSizePixel = 0
    Frame.Parent = KeyGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = THEME.Accent
    Stroke.Thickness = 2
    Stroke.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Text = "SECURITY CHECK"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = THEME.Accent
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 18
    Title.Parent = Frame

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0.8, 0, 0, 45)
    Input.Position = UDim2.new(0.1, 0, 0.3, 0)
    Input.BackgroundColor3 = THEME.Section
    Input.Text = ""
    Input.PlaceholderText = "Enter Key..."
    Input.TextColor3 = THEME.Text
    Input.Font = Enum.Font.Gotham
    Input.TextSize = 16
    Input.Parent = Frame

    local InCorner = Instance.new("UICorner")
    InCorner.CornerRadius = UDim.new(0, 6)
    InCorner.Parent = Input

    local EnterBtn = Instance.new("TextButton")
    EnterBtn.Size = UDim2.new(0.8, 0, 0, 40)
    EnterBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    EnterBtn.BackgroundColor3 = THEME.Accent
    EnterBtn.Text = "VERIFY"
    EnterBtn.TextColor3 = Color3.new(0,0,0)
    EnterBtn.Font = Enum.Font.GothamBold
    EnterBtn.TextSize = 16
    EnterBtn.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = EnterBtn

    EnterBtn.MouseButton1Click:Connect(function()
        if Input.Text:gsub(" ", "") == "hitadoro" then
            EnterBtn.Text = "SUCCESS"
            EnterBtn.BackgroundColor3 = THEME.Success
            wait(0.5)
            KeyGui:Destroy()
            RunMainScript()
        else
            EnterBtn.Text = "WRONG KEY"
            EnterBtn.BackgroundColor3 = THEME.Error
            wait(1)
            EnterBtn.Text = "VERIFY"
            EnterBtn.BackgroundColor3 = THEME.Accent
            Input.Text = ""
        end
    end)
end

-- ЗАПУСК
StartKeySystem()
