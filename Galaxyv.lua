--[[
    GALAXY HUB - Modern Key System
    Key: Galaxy@02026

    IMPORTANT:
    Replace the Discord link below with your real Discord invite.
]]

local DISCORD_LINK = "YOUR_DISCORD_SERVER_LINK_HERE"
local REQUIRED_KEY = ""

local function startMainScript()
-- Target Farm + Dynamic Spectate + Advanced Invisibility + Auto Combat + TP Dummy + Custom Keybinds

if getgenv().InvisScriptExecuted then
	return
end
getgenv().InvisScriptExecuted = true

local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local localPlayer = playersService.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================== CONFIGURABLE KEYBINDS ==========================
local Keybinds = {
    Follow = Enum.KeyCode.R,      -- Keybind for Start/Stop Follow
    Invis = Enum.KeyCode.T,       -- Keybind for Invisibility Toggle
    Spectate = Enum.KeyCode.Y,    -- Keybind for Spectate Toggle
    AutoCombat = Enum.KeyCode.G,  -- Keybind for Auto Combat Toggle
}

local colors = {
	Background = Color3.fromRGB(18, 19, 24),
	Panel = Color3.fromRGB(30, 31, 38),
	Stroke = Color3.fromRGB(50, 52, 65),
	TextPrimary = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(145, 146, 158),
	FollowOn = Color3.fromRGB(220, 70, 70),
	FollowOff = Color3.fromRGB(60, 200, 110),
	InvisOn = Color3.fromRGB(60, 200, 110),
	InvisOff = Color3.fromRGB(220, 70, 70),
    SpectateOff = Color3.fromRGB(80, 130, 255),
    SpectateOn = Color3.fromRGB(220, 120, 60),
    CombatOn = Color3.fromRGB(180, 70, 220),
    CombatOff = Color3.fromRGB(100, 100, 120),
    Reset = Color3.fromRGB(200, 50, 60),
    TpDummy = Color3.fromRGB(220, 130, 40)
}

-- ========================== UTILITY ==========================
local function getCharacter(plr)
    return plr and plr.Character
end

local function getRootPart(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function isCharacterValid(char)
    if not char then return false end
    local root = getRootPart(char)
    local hum = getHumanoid(char)
    return root and hum and hum.Health > 0
end

local function pressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- ========================== UI ANIMATION HELPERS ==========================
local function applyButtonAnimation(button)
    local originalSize = button.Size
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 4, originalSize.Y.Scale, originalSize.Y.Offset + 4)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = originalSize
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 6, originalSize.Y.Scale, originalSize.Y.Offset - 6)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 4, originalSize.Y.Scale, originalSize.Y.Offset + 4)
        }):Play()
    end)
end

-- ========================== SMOOTH NOTIFICATION ==========================
local notificationFrame = nil
local function notify(title, message)
    if notificationFrame then notificationFrame:Destroy() end
    
    notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.fromOffset(340, 65)
    notificationFrame.Position = UDim2.new(0.5, -170, 0, -80)
    notificationFrame.BackgroundColor3 = colors.Panel
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = CoreGui
    notificationFrame.ZIndex = 100

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notificationFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = colors.Stroke
    stroke.Thickness = 1.5
    stroke.Parent = notificationFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.fromOffset(10, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 210, 120)
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = notificationFrame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 25)
    msgLabel.Position = UDim2.fromOffset(10, 30)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = colors.TextPrimary
    msgLabel.TextSize = 13
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.Parent = notificationFrame

    TweenService:Create(notificationFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -170, 0, 30)
    }):Play()

    task.delay(3, function()
        if notificationFrame then
            local tweenOut = TweenService:Create(notificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -170, 0, -80)
            })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                if notificationFrame then
                    notificationFrame:Destroy()
                    notificationFrame = nil
                end
            end)
        end
    end)
end

-- ========================== INVISIBILITY LOGIC CORE ==========================
local invisProcessing = false
local invisAnimation = nil
local lastInvisHumanoid = nil
local savedRootCFrame = nil
local invisConnections = {}

local invisModel = Instance.new("Model", Workspace)
local invisHumanoid = Instance.new("Humanoid", invisModel)
local invisPart = Instance.new("Part", invisModel)
invisPart.Name = "HumanoidRootPart"
invisPart.CanCollide = false
invisPart.Transparency = 1
invisPart.Anchored = true
invisPart.Size = Vector3.new(2, 2, 1)

getgenv().InvisHumanoid = invisHumanoid
getgenv().InvisPart30 = invisPart
local invisActive = false

local invisToggleButton = nil
local spectateButton = nil
local followButton = nil
local autoCombatButton = nil
local playerDropdown = nil
local updateStatus = function() end

local function disableInvis()
	if not invisActive then return end
	invisActive = false
	getgenv().InvisActive = false
	invisProcessing = false
	if invisAnimation then
		pcall(function()
			if invisAnimation.IsPlaying then invisAnimation:Stop() end
		end)
		invisAnimation = nil
	end
	lastInvisHumanoid = nil
	local myChar = localPlayer.Character
	if myChar then
		local myRootPart = myChar:FindFirstChild("HumanoidRootPart")
		if myRootPart and savedRootCFrame then
			pcall(function() myRootPart.CFrame = savedRootCFrame end)
		end
		savedRootCFrame = nil
		local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
		if myHumanoid then
			pcall(function() Workspace.CurrentCamera.CameraSubject = myHumanoid end)
		end
		pcall(function() myChar:SetAttribute("NoHeadLerp", false) end)
		for _, val in pairs(invisConnections) do pcall(function() val:Disconnect() end) end
		invisConnections = {}
		for _, val2 in pairs(myChar:GetDescendants()) do
			if val2:IsA("BasePart") and val2.Name ~= "HumanoidRootPart" then
				val2.LocalTransparencyModifier = 0
			end
		end
	end
    if invisToggleButton then
    	invisToggleButton.Text = "Invis: Off [T]"
        TweenService:Create(invisToggleButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.InvisOff}):Play()
    end
end

local function stopInvisAnimation()
	if invisAnimation then
		pcall(function()
			if invisAnimation.IsPlaying then invisAnimation:Stop() end
		end)
		invisAnimation = nil
	end
	lastInvisHumanoid = nil
	savedRootCFrame = nil
	invisProcessing = false
end

local function makeSemiTransparent(part)
	if not part:IsA("BasePart") or part.Name == "HumanoidRootPart" or part.Transparency == 1 or part.Name:lower():find("hitbox") then return end
	part.LocalTransparencyModifier = 0.5
	local transparencyConn = part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
		if not invisActive then return end
		if part.LocalTransparencyModifier ~= 0.5 then
			part.LocalTransparencyModifier = 0.5
		end
	end)
	table.insert(invisConnections, transparencyConn)
end

local function hookTransparencyHandlers(model)
	for _, descendant in pairs(model:GetDescendants()) do makeSemiTransparent(descendant) end
	local descendantAddedConn = model.DescendantAdded:Connect(function(newDescendant)
		if invisActive then makeSemiTransparent(newDescendant) end
	end)
	table.insert(invisConnections, descendantAddedConn)
end

local function enableInvis()
	if invisActive then disableInvis() return end
	local myChar = localPlayer.Character
	if not myChar then return end
	local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
	local myRootPart = myChar:FindFirstChild("HumanoidRootPart")
	if not myHumanoid or not myRootPart then return end
	
	invisActive = true
	getgenv().InvisActive = true
	invisProcessing = false
	if myChar then hookTransparencyHandlers(myChar) end
    if invisToggleButton then
    	invisToggleButton.Text = "Invis: On [T]"
        TweenService:Create(invisToggleButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.InvisOn}):Play()
    end
end

runService.Heartbeat:Connect(function()
	local desyncActive = getgenv().desync ~= nil
	if not invisActive and not desyncActive then return end
	if invisProcessing then return end
	
	invisProcessing = true
	local myChar = localPlayer.Character
	local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
	local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myChar or not myHumanoid or not myRootPart then invisProcessing = false return end
	if myHumanoid.Health <= 0 then
		if invisActive then task.spawn(stopInvisAnimation) end
		invisProcessing = false
		return
	end
	
	local myRootCFrame = myRootPart.CFrame
	local myVelocity = myRootPart.Velocity
	savedRootCFrame = myRootCFrame
	local currentCamera = Workspace.CurrentCamera
	local desyncCFrame = nil
	if invisActive then desyncCFrame = myRootCFrame end
	if desyncActive and not localPlayer.Character:FindFirstChild("AbsoluteImmortal") then
		desyncCFrame = getgenv().desync.CFrame or desyncCFrame
	end
	
	if desyncCFrame then
		if currentCamera and not (invisActive and not desyncActive) then
			myChar:SetAttribute("NoHeadLerp", true)
			currentCamera.CameraSubject = invisHumanoid
		end
		invisPart.CFrame = myRootCFrame
		myRootPart.CFrame = desyncCFrame
	end
	
	local currentInvisAnim = nil
	if invisActive then
		if lastInvisHumanoid ~= myHumanoid then
			if invisAnimation then
				pcall(function()
					if invisAnimation.IsPlaying then invisAnimation:Stop() end
					invisAnimation:Destroy()
				end)
				invisAnimation = nil
			end
			lastInvisHumanoid = myHumanoid
		end
		local animator = myHumanoid:FindFirstChildOfClass("Animator")
		if animator then
			if not invisAnimation or invisAnimation.Parent == nil then
				local invisAnimAsset = Instance.new("Animation")
				invisAnimAsset.AnimationId = "rbxassetid://71181015443030"
				invisAnimation = animator:LoadAnimation(invisAnimAsset)
				invisAnimation.Priority = Enum.AnimationPriority.Action4
				invisAnimation:Play()
				invisAnimation:AdjustSpeed(0)
				invisAnimation:AdjustWeight(2e9)
			end
			currentInvisAnim = invisAnimation
			currentInvisAnim.TimePosition = 13.45
		end
	end
	
	runService.RenderStepped:Wait()
	invisHumanoid.CameraOffset = myHumanoid.CameraOffset
	if currentCamera and currentCamera.CameraSubject == invisHumanoid then
		myChar:SetAttribute("NoHeadLerp", false)
		currentCamera.CameraSubject = myHumanoid
	end
	
	if currentInvisAnim and currentInvisAnim.IsPlaying then
		pcall(function() currentInvisAnim:Stop() end)
	end
	if desyncCFrame then myRootPart.CFrame = myRootCFrame end
	myRootPart.Velocity = myVelocity
	invisProcessing = false
end)

-- ========================== COMBAT & AUTO COMBAT CORE ==========================
local selectedTarget = nil
local followEnabled = false
local autoCombatEnabled = false
local currentTarget = nil

local lastSkillTime = 0
local lastDashTime = 0
local currentSkillIndex = 1
local skillKeys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}

local attackAnimIds = {
    "17799224866", "17838006839", "17838619895", "17857788598",
    "17857880283", "18179181663", "18182425133", "18464351556",
    "18464356233", "18464372850", "18464362124", "136370737633649",
    "130301810149072", "17889290569", "10479335397", "18896229321"
}

local function isAttackingAnim(humanoid)
    if not humanoid then return false end
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        local id = track.Animation.AnimationId
        for _, pattern in ipairs(attackAnimIds) do
            if id:match(pattern) then return true end
        end
    end
    return false
end

local function getBehindCFrame(targetRoot)
    local cf = targetRoot.CFrame
    local _, ry = cf:ToEulerAnglesYXZ()
    local yaw = CFrame.fromEulerAnglesYXZ(0, ry, 0)
    return CFrame.new(cf.Position) * yaw * CFrame.new(0, 0, 5)
end

local function detachPhysics()
    local char = localPlayer.Character
    if char then
        local root = getRootPart(char)
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if sethiddenproperty then sethiddenproperty(root, "PhysicsRepRootPart", nil) end
        end
        local hum = getHumanoid(char)
        if hum then hum.AutoRotate = true end
    end
end

local combatHeartbeat
local function stopCombat()
    if combatHeartbeat then
        combatHeartbeat:Disconnect()
        combatHeartbeat = nil
    end
    detachPhysics()
    currentTarget = nil
end

local function startCombat()
    if combatHeartbeat then return end
    combatHeartbeat = runService.Heartbeat:Connect(function()
        if not followEnabled or not selectedTarget then
            if currentTarget then
                currentTarget = nil
                detachPhysics()
            end
            return
        end

        local target = selectedTarget
        if not target or not target.Parent then
            notify("Target Left", (target and target.DisplayName or "Player") .. " left the game.")
            followEnabled = false
            selectedTarget = nil
            if playerDropdown then playerDropdown.Text = "Select Target..." end
            updateStatus()
            stopCombat()
            return
        end

        local targetChar = getCharacter(target)
        if not isCharacterValid(targetChar) then
            currentTarget = nil
            detachPhysics()
            followEnabled = false
            if followButton then
                followButton.Text = "Start Follow [R]"
                TweenService:Create(followButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.FollowOff}):Play()
            end
            stopCombat()
            updateStatus()
            notify("Target Eliminated", target.DisplayName .. " has died.")
            return
        end

        local myChar = localPlayer.Character
        if not myChar then return end
        local myRoot = getRootPart(myChar)
        local myHum = getHumanoid(myChar)
        if not myRoot or not myHum then return end

        local targetRoot = getRootPart(targetChar)
        local targetHum = getHumanoid(targetChar)
        if not targetRoot or not targetHum then return end

        currentTarget = target

        myHum.AutoRotate = false
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        if not getgenv().desync then
            myRoot.CFrame = getBehindCFrame(targetRoot)
        end
        if sethiddenproperty then
            sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot)
        end

        -- Auto Combat (M1 + Skills + Dash Q) Logic
        if autoCombatEnabled and not targetChar:FindFirstChild("ForceField") then
            
            -- Auto M1 Attack
            if not isAttackingAnim(myHum) then
                local communicate = myChar:FindFirstChild("Communicate")
                if communicate then
                    communicate:FireServer({ Goal = "LeftClick" })
                    task.wait(0.05)
                    communicate:FireServer({ Goal = "LeftClickRelease" })
                end
            end

            local now = tick()
            
            -- Auto Dash (Q Key) gap closing / comboing every 3.5 seconds
            if now - lastDashTime > 3.5 then
                lastDashTime = now
                task.spawn(function()
                    pressKey(Enum.KeyCode.Q)
                end)
            end

            -- Auto Skills (1, 2, 3, 4) every 0.8 seconds
            if now - lastSkillTime > 0.8 then
                lastSkillTime = now
                local keyToPress = skillKeys[currentSkillIndex]
                currentSkillIndex = (currentSkillIndex % #skillKeys) + 1
                task.spawn(function()
                    pressKey(keyToPress)
                end)
            end
        end
    end)
end

-- ========================== SPECTATE SYSTEM ==========================
local spectateEnabled = false
local spectateTarget = nil
local Yaw = 0
local Pitch = -0.3
local Distance = 10
local TargetDistance = 10
local DistanceLerpSpeed = 15
local isRotating = false
local spectateRenderConnection = nil

local function stopSpectate()
    spectateEnabled = false
    spectateTarget = nil
    if spectateButton then
        spectateButton.Text = "Spectate [Y]"
        TweenService:Create(spectateButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.SpectateOff}):Play()
    end
    if spectateRenderConnection then
        spectateRenderConnection:Disconnect()
        spectateRenderConnection = nil
    end
    Camera.CameraType = Enum.CameraType.Custom
    if localPlayer.Character then Camera.CameraSubject = localPlayer.Character end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    updateStatus()
end

local function startSpectate(targetPlayer)
    if not targetPlayer then return end
    if spectateEnabled then stopSpectate() end
    spectateTarget = targetPlayer
    spectateEnabled = true
    
    if spectateButton then
        spectateButton.Text = "Stop Spectating [Y]"
        TweenService:Create(spectateButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.SpectateOn}):Play()
    end

    Yaw, Pitch, Distance, TargetDistance = 0, -0.3, 10, 10
    Camera.CameraType = Enum.CameraType.Scriptable

    if spectateRenderConnection then spectateRenderConnection:Disconnect() end
    spectateRenderConnection = runService.RenderStepped:Connect(function(deltaTime)
        if not spectateEnabled or not spectateTarget or not spectateTarget.Parent then
            notify("Spectate Ended", "Target left the game.")
            stopSpectate()
            return
        end

        local targetChar = getCharacter(spectateTarget)
        if not targetChar then return end
        local root = getRootPart(targetChar) or targetChar:FindFirstChild("Head")
        if not root then return end

        Distance = Distance + (TargetDistance - Distance) * (1 - math.exp(-DistanceLerpSpeed * deltaTime))
        local targetPos = root.Position
        local yawQuat = CFrame.Angles(0, Yaw, 0)
        local pitchQuat = CFrame.Angles(Pitch, 0, 0)
        local dir = (yawQuat * pitchQuat).LookVector * Distance
        Camera.CFrame = CFrame.new(targetPos - dir, targetPos)
    end)

    updateStatus()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and spectateEnabled then
        isRotating = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and spectateEnabled then
        isRotating = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement and isRotating and spectateEnabled then
        Yaw = Yaw - input.Delta.X * 0.005
        Pitch = math.clamp(Pitch - input.Delta.Y * 0.005, -1.5, 0.5)
    end
    if input.UserInputType == Enum.UserInputType.MouseWheel and spectateEnabled then
        TargetDistance = math.clamp(TargetDistance - input.Position.Z * 3.5, 2, 50)
    end
end)

-- ========================== ANTI-AFK ==========================
local function setupAntiAfk()
    local vu = game:GetService("VirtualUser")
    localPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end

-- ========================== REDESIGNED SMOOTH GUI ==========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SmoothTargetFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(360, 340)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = colors.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = colors.Stroke
stroke.Thickness = 1
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.Position = UDim2.fromOffset(0, 0)
title.BackgroundTransparency = 1
title.Text = "GALAXY HUB"
title.TextColor3 = colors.TextPrimary
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- ========================== TAB SYSTEM ==========================
local targetTabButton = Instance.new("TextButton")
targetTabButton.Size = UDim2.fromOffset(165, 30)
targetTabButton.Position = UDim2.fromOffset(10, 42)
targetTabButton.BackgroundColor3 = colors.FollowOff
targetTabButton.Text = "Target Farm"
targetTabButton.TextColor3 = colors.TextPrimary
targetTabButton.TextSize = 12
targetTabButton.Font = Enum.Font.GothamBold
targetTabButton.AutoButtonColor = false
targetTabButton.Parent = mainFrame
local targetTabCorner = Instance.new("UICorner")
targetTabCorner.CornerRadius = UDim.new(0, 6)
targetTabCorner.Parent = targetTabButton

local publicTabButton = Instance.new("TextButton")
publicTabButton.Size = UDim2.fromOffset(165, 30)
publicTabButton.Position = UDim2.fromOffset(185, 42)
publicTabButton.BackgroundColor3 = colors.Panel
publicTabButton.Text = "Rage Kill"
publicTabButton.TextColor3 = colors.TextDim
publicTabButton.TextSize = 12
publicTabButton.Font = Enum.Font.GothamBold
publicTabButton.AutoButtonColor = false
publicTabButton.Parent = mainFrame
local publicTabCorner = Instance.new("UICorner")
publicTabCorner.CornerRadius = UDim.new(0, 6)
publicTabCorner.Parent = publicTabButton

local targetContent = Instance.new("Frame")
targetContent.Name = "TargetFarmContent"
targetContent.Size = UDim2.new(1, 0, 1, -78)
targetContent.Position = UDim2.fromOffset(0, 78)
targetContent.BackgroundTransparency = 1
targetContent.Parent = mainFrame

local publicContent = Instance.new("Frame")
publicContent.Name = "PublicFarmContent"
publicContent.Size = UDim2.new(1, 0, 1, -78)
publicContent.Position = UDim2.fromOffset(0, 78)
publicContent.BackgroundTransparency = 1
publicContent.Visible = false
publicContent.Parent = mainFrame

local publicInfo = Instance.new("TextLabel")
publicInfo.Size = UDim2.new(1, -30, 0, 35)
publicInfo.Position = UDim2.fromOffset(15, 10)
publicInfo.BackgroundTransparency = 1
publicInfo.Text = "Public Kill"
publicInfo.TextColor3 = colors.TextPrimary
publicInfo.TextSize = 14
publicInfo.Font = Enum.Font.GothamBold
publicInfo.Parent = publicContent

local publicLoadButton = Instance.new("TextButton")
publicLoadButton.Size = UDim2.new(1, -30, 0, 42)
publicLoadButton.Position = UDim2.fromOffset(15, 52)
publicLoadButton.BackgroundColor3 = colors.FollowOff
publicLoadButton.Text = "Load Rage Kill"
publicLoadButton.TextColor3 = colors.TextPrimary
publicLoadButton.TextSize = 13
publicLoadButton.Font = Enum.Font.GothamBold
publicLoadButton.AutoButtonColor = false
publicLoadButton.Parent = publicContent
local publicLoadCorner = Instance.new("UICorner")
publicLoadCorner.CornerRadius = UDim.new(0, 7)
publicLoadCorner.Parent = publicLoadButton
applyButtonAnimation(publicLoadButton)

-- Public Farm Auto Combat Toggle
local publicAutoCombatButton = Instance.new("TextButton")
publicAutoCombatButton.Size = UDim2.new(1, -30, 0, 38)
publicAutoCombatButton.Position = UDim2.fromOffset(15, 105)
publicAutoCombatButton.BackgroundColor3 = colors.CombatOff
publicAutoCombatButton.Text = "Auto Combat: Off"
publicAutoCombatButton.TextColor3 = colors.TextPrimary
publicAutoCombatButton.TextSize = 13
publicAutoCombatButton.Font = Enum.Font.GothamBold
publicAutoCombatButton.Parent = publicContent
local publicCombatCorner = Instance.new("UICorner")
publicCombatCorner.CornerRadius = UDim.new(0, 7)
publicCombatCorner.Parent = publicAutoCombatButton
applyButtonAnimation(publicAutoCombatButton)

-- Martial Artist Recommendation Note
local martialNote = Instance.new("TextLabel")
martialNote.Size = UDim2.new(1, -30, 0, 30)
martialNote.Position = UDim2.fromOffset(15, 148)
martialNote.BackgroundTransparency = 1
martialNote.Text = "Recommended: Use Martial Artist Character before using Rage Farm."
martialNote.TextColor3 = colors.TextDim
martialNote.TextSize = 11
martialNote.Font = Enum.Font.Gotham
martialNote.TextWrapped = true
martialNote.Parent = publicContent

-- Public Farm Auto Combat System (M1 + Skills + Dash Q)
local publicAutoCombatEnabled = false
local publicCombatRunning = false
local publicLastDash = 0
local publicLastSkill = 0
local publicSkillIndex = 1
local publicSkillKeys = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four
}

local function startPublicAutoCombat()
    if publicCombatRunning then return end
    publicCombatRunning = true

    task.spawn(function()
        while publicCombatRunning do
            task.wait(0.05)

            if not publicAutoCombatEnabled then
                continue
            end

            local char = localPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hum then
                local communicate = char:FindFirstChild("Communicate")

                -- Auto M1
                if communicate and not isAttackingAnim(hum) then
                    pcall(function()
                        communicate:FireServer({Goal = "LeftClick"})
                        task.wait(0.05)
                        communicate:FireServer({Goal = "LeftClickRelease"})
                    end)
                end

                local now = tick()

                -- Auto Dash Q
                if now - publicLastDash >= 3.5 then
                    publicLastDash = now
                    task.spawn(function()
                        pcall(function()
                            pressKey(Enum.KeyCode.Q)
                        end)
                    end)
                end

                -- Auto Skills 1-4
                if now - publicLastSkill >= 0.8 then
                    publicLastSkill = now
                    local key = publicSkillKeys[publicSkillIndex]
                    publicSkillIndex = (publicSkillIndex % #publicSkillKeys) + 1

                    task.spawn(function()
                        pcall(function()
                            pressKey(key)
                        end)
                    end)
                end
            end
        end
    end)
end

local function stopPublicAutoCombat()
    publicCombatRunning = false
end

publicAutoCombatButton.MouseButton1Click:Connect(function()
    publicAutoCombatEnabled = not publicAutoCombatEnabled

    if publicAutoCombatEnabled then
        publicAutoCombatButton.Text = "Auto Combat: On"
        TweenService:Create(publicAutoCombatButton, TweenInfo.new(0.2), {BackgroundColor3 = colors.CombatOn}):Play()
        startPublicAutoCombat()
        notify("Public Auto Combat Enabled", "M1 + Skills + Dash Q active.")
    else
        publicAutoCombatButton.Text = "Auto Combat: Off"
        TweenService:Create(publicAutoCombatButton, TweenInfo.new(0.2), {BackgroundColor3 = colors.CombatOff}):Play()
        stopPublicAutoCombat()
    end
end)


local publicLoaded = false
local publicLoading = false

local function setActiveTab(tabName)
    local isTarget = tabName == "Target"
    targetContent.Visible = isTarget
    publicContent.Visible = not isTarget

    targetTabButton.BackgroundColor3 = isTarget and colors.FollowOff or colors.Panel
    targetTabButton.TextColor3 = isTarget and colors.TextPrimary or colors.TextDim
    publicTabButton.BackgroundColor3 = isTarget and colors.Panel or colors.FollowOff
    publicTabButton.TextColor3 = isTarget and colors.TextDim or colors.TextPrimary
end

targetTabButton.MouseButton1Click:Connect(function()
    setActiveTab("Target")
end)

publicTabButton.MouseButton1Click:Connect(function()
    setActiveTab("Public")
end)

publicLoadButton.MouseButton1Click:Connect(function()
    if publicLoading then return end
    if publicLoaded then
        notify("Public Farm", "Rage Kill is already loaded.")
        return
    end

    publicLoading = true
    publicLoadButton.Text = "Loading ..."
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/JoshSuarez425/Infographics_MCO2/refs/heads/main/public%20farm.lua"))()
        end)

        if not ok then
            publicLoading = false
            publicLoadButton.Text = "Load Public Kill"
            notify("Public Kill Error", tostring(err))
            return
        end

        task.wait(0.2)

        -- Embed the Public Farm window into this tab instead of leaving
        -- a second independent GUI on the screen.
        local publicGui = CoreGui:FindFirstChild("ZKAYFarmUI")
        local publicMain = publicGui and publicGui:FindFirstChild("MainFrame")

        if publicMain then
            publicMain.Parent = publicContent
            publicMain.AnchorPoint = Vector2.new(0.5, 0)
            publicMain.Position = UDim2.fromScale(0.5, 12 / math.max(publicContent.AbsoluteSize.Y, 1))
            publicMain.Size = UDim2.fromOffset(320, 120)
            publicMain.Active = true
            publicMain.Draggable = true
            if publicGui then
                publicGui:Destroy()
            end
        end

        publicLoaded = true
        publicLoading = false
        publicLoadButton.Visible = false
        publicInfo.Text = "Public Kill • Loaded"
    end)
end)

setActiveTab("Target")

-- Player selection dropdown
playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(0.9, 0, 0, 35)
playerDropdown.Position = UDim2.fromScale(0.05, 0.14)
playerDropdown.BackgroundColor3 = colors.Panel
playerDropdown.Text = "Select Target..."
playerDropdown.TextColor3 = colors.TextPrimary
playerDropdown.TextSize = 13
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.Parent = targetContent
local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 6)
corner2.Parent = playerDropdown
applyButtonAnimation(playerDropdown)

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Size = UDim2.new(0.9, 0, 0, 130)
dropdownList.Position = UDim2.fromScale(0.05, 0.27)
dropdownList.BackgroundColor3 = colors.Panel
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.ZIndex = 15
dropdownList.Parent = targetContent
dropdownList.ScrollBarImageColor3 = colors.Stroke
dropdownList.ScrollBarThickness = 4

local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 6)
corner3.Parent = dropdownList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = dropdownList

local function refreshPlayerList()
    for _, child in pairs(dropdownList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local players = playersService:GetPlayers()
    local height = 0
    for _, plr in ipairs(players) do
        if plr ~= localPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = colors.Panel
            btn.Text = "  " .. plr.DisplayName .. " (@" .. plr.Name .. ")"
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextColor3 = colors.TextPrimary
            btn.TextSize = 13
            btn.Font = Enum.Font.Gotham
            btn.AutoButtonColor = true
            btn.ZIndex = 16
            btn.Parent = dropdownList
            
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.Stroke}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.Panel}):Play()
            end)
            
            btn.MouseButton1Click:Connect(function()
                selectedTarget = plr
                playerDropdown.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
                dropdownList.Visible = false
                if followEnabled then
                    stopCombat()
                    startCombat()
                end
                if spectateEnabled then
                    stopSpectate()
                    startSpectate(selectedTarget)
                end
                updateStatus()
            end)
            height = height + 30
        end
    end
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, height)
end

playerDropdown.MouseButton1Click:Connect(function()
    refreshPlayerList()
    dropdownList.Visible = not dropdownList.Visible
end)

-- 3x2 Button Grid Layout
local buttonGrid = Instance.new("Frame")
buttonGrid.Size = UDim2.new(0.9, 0, 0, 140)
buttonGrid.Position = UDim2.fromScale(0.05, 0.29)
buttonGrid.BackgroundTransparency = 1
buttonGrid.Parent = targetContent

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.CellSize = UDim2.new(0.48, -5, 0, 38)
gridLayout.Parent = buttonGrid

-- Row 1: Follow & Spectate
followButton = Instance.new("TextButton")
followButton.BackgroundColor3 = colors.FollowOff
followButton.Text = "Start Follow [R]"
followButton.TextColor3 = colors.TextPrimary
followButton.TextSize = 12
followButton.Font = Enum.Font.GothamBold
followButton.Parent = buttonGrid
local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 6)
corner4.Parent = followButton
applyButtonAnimation(followButton)

spectateButton = Instance.new("TextButton")
spectateButton.BackgroundColor3 = colors.SpectateOff
spectateButton.Text = "Spectate [Y]"
spectateButton.TextColor3 = colors.TextPrimary
spectateButton.TextSize = 12
spectateButton.Font = Enum.Font.GothamBold
spectateButton.Parent = buttonGrid
local corner5 = Instance.new("UICorner")
corner5.CornerRadius = UDim.new(0, 6)
corner5.Parent = spectateButton
applyButtonAnimation(spectateButton)

-- Row 2: Invis & Auto Combat
invisToggleButton = Instance.new("TextButton")
invisToggleButton.BackgroundColor3 = colors.InvisOff
invisToggleButton.Text = "Invis: Off [T]"
invisToggleButton.TextColor3 = colors.TextPrimary
invisToggleButton.TextSize = 12
invisToggleButton.Font = Enum.Font.GothamBold
invisToggleButton.Parent = buttonGrid
local corner6 = Instance.new("UICorner")
corner6.CornerRadius = UDim.new(0, 6)
corner6.Parent = invisToggleButton
applyButtonAnimation(invisToggleButton)

autoCombatButton = Instance.new("TextButton")
autoCombatButton.BackgroundColor3 = colors.CombatOff
autoCombatButton.Text = "Auto Combat: Off [G]"
autoCombatButton.TextColor3 = colors.TextPrimary
autoCombatButton.TextSize = 12
autoCombatButton.Font = Enum.Font.GothamBold
autoCombatButton.Parent = buttonGrid
local cornerCombat = Instance.new("UICorner")
cornerCombat.CornerRadius = UDim.new(0, 6)
cornerCombat.Parent = autoCombatButton
applyButtonAnimation(autoCombatButton)

-- Row 3: Force Reset & TP Dummy
local resetButton = Instance.new("TextButton")
resetButton.BackgroundColor3 = colors.Reset
resetButton.Text = "Force Reset"
resetButton.TextColor3 = colors.TextPrimary
resetButton.TextSize = 12
resetButton.Font = Enum.Font.GothamBold
resetButton.Parent = buttonGrid
local corner7 = Instance.new("UICorner")
corner7.CornerRadius = UDim.new(0, 6)
corner7.Parent = resetButton
applyButtonAnimation(resetButton)

local tpDummyButton = Instance.new("TextButton")
tpDummyButton.BackgroundColor3 = colors.TpDummy
tpDummyButton.Text = "TP Dummy"
tpDummyButton.TextColor3 = colors.TextPrimary
tpDummyButton.TextSize = 12
tpDummyButton.Font = Enum.Font.GothamBold
tpDummyButton.Parent = buttonGrid
local corner8 = Instance.new("UICorner")
corner8.CornerRadius = UDim.new(0, 6)
corner8.Parent = tpDummyButton
applyButtonAnimation(tpDummyButton)

-- Status Bar
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.fromScale(0, 0.88)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Awaiting Target Selection..."
statusLabel.TextColor3 = colors.TextDim
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = targetContent

-- Toggle Actions
local function toggleFollow()
    followEnabled = not followEnabled
    if followEnabled then
        if not selectedTarget then
            followEnabled = false
            notify("Action Denied", "Please select a target first.")
            return
        end
        followButton.Text = "Stop Follow [R]"
        TweenService:Create(followButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.FollowOn}):Play()
        startCombat()
    else
        followButton.Text = "Start Follow [R]"
        TweenService:Create(followButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.FollowOff}):Play()
        stopCombat()
    end
    updateStatus()
end

local function toggleInvisAction()
    if invisActive then
        disableInvis()
    else
        enableInvis()
    end
end

local function toggleSpectateAction()
    if spectateEnabled then
        stopSpectate()
    else
        if not selectedTarget then
            notify("Action Denied", "Please select a target first.")
            return
        end
        startSpectate(selectedTarget)
    end
end

local function toggleAutoCombatAction()
    autoCombatEnabled = not autoCombatEnabled
    if autoCombatEnabled then
        autoCombatButton.Text = "Auto Combat: On [G]"
        TweenService:Create(autoCombatButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.CombatOn}):Play()
        notify("Auto Combat Enabled", "M1 + Auto Skills (1-4) + Auto Dash (Q) active.")
    else
        autoCombatButton.Text = "Auto Combat: Off [G]"
        TweenService:Create(autoCombatButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.CombatOff}):Play()
    end
    updateStatus()
end

-- Button Clicks
followButton.MouseButton1Click:Connect(toggleFollow)
invisToggleButton.MouseButton1Click:Connect(toggleInvisAction)
spectateButton.MouseButton1Click:Connect(toggleSpectateAction)
autoCombatButton.MouseButton1Click:Connect(toggleAutoCombatAction)
publicAutoCombatButton.MouseButton1Click:Connect(function()
    toggleAutoCombatAction()
    if autoCombatEnabled then
        publicAutoCombatButton.Text = "Auto Combat: On"
        TweenService:Create(publicAutoCombatButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.CombatOn}):Play()
    else
        publicAutoCombatButton.Text = "Auto Combat: Off"
        TweenService:Create(publicAutoCombatButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.CombatOff}):Play()
    end
end)

resetButton.MouseButton1Click:Connect(function()
	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	end
end)

tpDummyButton.MouseButton1Click:Connect(function()
    local char = localPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local playerNames = {}
    for _, p in ipairs(playersService:GetPlayers()) do
        playerNames[p.Name] = true
    end

    local target = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not playerNames[obj.Name] then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp then
                target = hrp
                break
            end
        end
    end

    if target then
        root.CFrame = target.CFrame + Vector3.new(0, 4, 0)
        notify("Success", "Teleported to Dummy.")
    else
        notify("Error", "No dummy found in workspace.")
    end
end)

-- Keybind Listeners
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Keybinds.Follow then
        toggleFollow()
    elseif input.KeyCode == Keybinds.Invis then
        toggleInvisAction()
    elseif input.KeyCode == Keybinds.Spectate then
        toggleSpectateAction()
    elseif input.KeyCode == Keybinds.AutoCombat then
        toggleAutoCombatAction()
    end
end)

updateStatus = function()
    local parts = {}
    if followEnabled and selectedTarget then
        table.insert(parts, "Following: " .. selectedTarget.DisplayName)
    elseif followEnabled and not selectedTarget then
        table.insert(parts, "Follow: Off")
    end

    if autoCombatEnabled then
        table.insert(parts, "Combat: Active")
    end

    if spectateEnabled and spectateTarget then
        table.insert(parts, "Spectating: " .. spectateTarget.DisplayName)
    end

    if #parts == 0 then
        statusLabel.Text = "Awaiting Target Selection..."
    else
        statusLabel.Text = table.concat(parts, " | ")
    end
end

refreshPlayerList()
playersService.PlayerAdded:Connect(refreshPlayerList)
playersService.PlayerRemoving:Connect(refreshPlayerList)

setupAntiAfk()

-- Character Spawn Handler
localPlayer.CharacterAdded:Connect(function(char)
    for _, val in pairs(invisConnections) do pcall(function() val:Disconnect() end) end
    invisConnections = {}
    savedRootCFrame = nil

    if invisActive then
        task.spawn(function()
            char:WaitForChild("HumanoidRootPart", 5)
            if invisActive then hookTransparencyHandlers(char) end
        end)
    end

    if followEnabled and selectedTarget then
        task.wait(0.5)
        stopCombat()
        startCombat()
    end
end)

print("Galaxy Hub Loaded!.")

-- Disable Auto Combat while using Ultimate
task.spawn(function()
    while task.wait(0.15) do
        local char = localPlayer.Character
        if char and autoCombatEnabled then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local usingUlt = false

            if hum then
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    local name = string.lower(track.Animation and track.Animation.Name or "")
                    if string.find(name, "ult") or string.find(name, "ultimate") then
                        usingUlt = true
                        break
                    end
                end
            end

            if char:GetAttribute("UsingUltimate") == true or char:GetAttribute("UltActive") == true then
                usingUlt = true
            end

            if usingUlt then
                autoCombatEnabled = false
                publicCombatRunning = false
                if autoCombatButton then
                    autoCombatButton.Text = "Auto Combat: Off [G]"
                    TweenService:Create(autoCombatButton, TweenInfo.new(0.2), {BackgroundColor3 = colors.CombatOff}):Play()
                end
                if publicAutoCombatButton then
                    publicAutoCombatButton.Text = "Auto Combat: Off"
                    TweenService:Create(publicAutoCombatButton, TweenInfo.new(0.2), {BackgroundColor3 = colors.CombatOff}):Play()
                end
            end
        end
    end
end)

end

-- ========================== MODERN KEY SYSTEM ==========================

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Avoid duplicate key-system windows.
pcall(function()
    local old = CoreGui:FindFirstChild("GalaxyHubKeySystem")
    if old then old:Destroy() end
end)

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "GalaxyHubKeySystem"
keyGui.ResetOnSpawn = false
keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
keyGui.Parent = CoreGui

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundTransparency = 1
background.Parent = keyGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(390, 250)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
main.BorderSizePixel = 0
main.Active = true
main.Parent = background

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(55, 58, 72)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- Mobile-friendly dragging.
do
    local dragging = false
    local dragStart
    local startPos

    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 32)
title.Position = UDim2.fromOffset(20, 18)
title.BackgroundTransparency = 1
title.Text = "GALAXY HUB"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 24)
subtitle.Position = UDim2.fromOffset(20, 50)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Enter your key to continue"
subtitle.TextColor3 = Color3.fromRGB(145, 146, 158)
subtitle.TextSize = 13
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = main

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -40, 0, 46)
keyBox.Position = UDim2.fromOffset(20, 84)
keyBox.BackgroundColor3 = Color3.fromRGB(30, 31, 38)
keyBox.BorderSizePixel = 0
keyBox.ClearTextOnFocus = false
keyBox.PlaceholderText = "Just Click Submit..."
keyBox.PlaceholderColor3 = Color3.fromRGB(120, 121, 133)
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(240, 240, 245)
keyBox.TextSize = 14
keyBox.Font = Enum.Font.Gotham
keyBox.TextXAlignment = Enum.TextXAlignment.Left
keyBox.Parent = main

local keyPadding = Instance.new("UIPadding")
keyPadding.PaddingLeft = UDim.new(0, 14)
keyPadding.PaddingRight = UDim.new(0, 14)
keyPadding.Parent = keyBox

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 9)
keyCorner.Parent = keyBox

local keyStroke = Instance.new("UIStroke")
keyStroke.Color = Color3.fromRGB(55, 58, 72)
keyStroke.Thickness = 1
keyStroke.Parent = keyBox

local getKey = Instance.new("TextButton")
getKey.Size = UDim2.new(0.5, -25, 0, 44)
getKey.Position = UDim2.new(0, 20, 0, 145)
getKey.BackgroundColor3 = Color3.fromRGB(35, 100, 235)
getKey.BorderSizePixel = 0
getKey.Text = "Get Key"
getKey.TextColor3 = Color3.fromRGB(255, 255, 255)
getKey.TextSize = 13
getKey.Font = Enum.Font.GothamBold
getKey.AutoButtonColor = false
getKey.Parent = main

local getCorner = Instance.new("UICorner")
getCorner.CornerRadius = UDim.new(0, 9)
getCorner.Parent = getKey

local submit = Instance.new("TextButton")
submit.Size = UDim2.new(0.5, -25, 0, 44)
submit.Position = UDim2.new(0.5, 5, 0, 145)
submit.BackgroundColor3 = Color3.fromRGB(95, 65, 220)
submit.BorderSizePixel = 0
submit.Text = "Submit Key"
submit.TextColor3 = Color3.fromRGB(255, 255, 255)
submit.TextSize = 13
submit.Font = Enum.Font.GothamBold
submit.AutoButtonColor = false
submit.Parent = main

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 9)
submitCorner.Parent = submit

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -40, 0, 30)
status.Position = UDim2.fromOffset(20, 198)
status.BackgroundTransparency = 1
status.Text = "Get a key from our Discord server."
status.TextColor3 = Color3.fromRGB(145, 146, 158)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextWrapped = true
status.Parent = main

local function buttonHover(button, normalColor)
    local hoverColor = Color3.fromRGB(
        math.min(normalColor.R * 255 + 20, 255),
        math.min(normalColor.G * 255 + 20, 255),
        math.min(normalColor.B * 255 + 20, 255)
    )

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

buttonHover(getKey, Color3.fromRGB(35, 100, 235))
buttonHover(submit, Color3.fromRGB(95, 65, 220))

local function copyDiscordLink()
    if DISCORD_LINK == "YOUR_DISCORD_SERVER_LINK_HERE" then
        status.Text = "In developmental XD."
        status.TextColor3 = Color3.fromRGB(255, 190, 80)
        return
    end

    local copied = false

    pcall(function()
        if setclipboard then
            setclipboard(DISCORD_LINK)
            copied = true
        end
    end)

    if not copied then
        pcall(function()
            if toclipboard then
                toclipboard(DISCORD_LINK)
                copied = true
            end
        end)
    end

    if copied then
        status.Text = "Discord link copied to clipboard!"
        status.TextColor3 = Color3.fromRGB(80, 210, 120)
    else
        status.Text = "Clipboard is not supported by this executor."
        status.TextColor3 = Color3.fromRGB(255, 190, 80)
    end
end

local submitting = false

local function submitKey()
    if submitting then return end

    if keyBox.Text == REQUIRED_KEY then
        submitting = true
        status.Text = "Key accepted! Loading..."
        status.TextColor3 = Color3.fromRGB(80, 210, 120)

        task.wait(0.35)

        keyGui:Destroy()

        local ok, err = xpcall(startMainScript, debug.traceback)
        if not ok then
            warn("[Galaxy Hub] Main script error:\n" .. tostring(err))
        end
    else
        status.Text = "Invalid key. Please try again."
        status.TextColor3 = Color3.fromRGB(235, 80, 80)

        local original = main.Position
        TweenService:Create(main, TweenInfo.new(0.05), {
            Position = original + UDim2.fromOffset(6, 0)
        }):Play()

        task.delay(0.05, function()
            if main and main.Parent then
                TweenService:Create(main, TweenInfo.new(0.05), {
                    Position = original
                }):Play()
            end
        end)
    end
end

getKey.MouseButton1Click:Connect(copyDiscordLink)
submit.MouseButton1Click:Connect(submitKey)

keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitKey()
    end
end)
