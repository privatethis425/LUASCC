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
    TpDummy = Color3.fromRGB(220, 130, 40),
    HitboxOn = Color3.fromRGB(60, 200, 110),
    HitboxOff = Color3.fromRGB(100, 100, 120)
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
local hitboxButton = nil
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
local hitboxEnabled = false
local currentTarget = nil
local enlargedHitboxPart = nil
local enlargedHitboxOriginalSize = nil

local HITBOX_SIZE = Vector3.new(4, 4, 4)

local function restoreTargetHitbox()
    if enlargedHitboxPart and enlargedHitboxPart.Parent and enlargedHitboxOriginalSize then
        pcall(function()
            enlargedHitboxPart.Size = enlargedHitboxOriginalSize
        end)
    end
    enlargedHitboxPart = nil
    enlargedHitboxOriginalSize = nil
end

local function applyTargetHitbox(targetPlayer)
    restoreTargetHitbox()
    if not hitboxEnabled or not targetPlayer then return end

    local targetChar = getCharacter(targetPlayer)
    local targetRoot = getRootPart(targetChar)
    if not targetRoot or not targetRoot:IsA("BasePart") then return end

    enlargedHitboxPart = targetRoot
    enlargedHitboxOriginalSize = targetRoot.Size
    pcall(function()
        targetRoot.Size = HITBOX_SIZE
    end)
end

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
            restoreTargetHitbox()
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
            restoreTargetHitbox()
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
mainFrame.Size = UDim2.fromOffset(360, 350)
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
title.Text = "TARGET FARM & COMBAT"
title.TextColor3 = colors.TextPrimary
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Player selection dropdown
playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(0.9, 0, 0, 35)
playerDropdown.Position = UDim2.fromScale(0.05, 0.14)
playerDropdown.BackgroundColor3 = colors.Panel
playerDropdown.Text = "Select Target..."
playerDropdown.TextColor3 = colors.TextPrimary
playerDropdown.TextSize = 13
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.Parent = mainFrame
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
dropdownList.Parent = mainFrame
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
                if hitboxEnabled then
                    applyTargetHitbox(selectedTarget)
                end
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
buttonGrid.Size = UDim2.new(0.9, 0, 0, 188)
buttonGrid.Position = UDim2.fromScale(0.05, 0.29)
buttonGrid.BackgroundTransparency = 1
buttonGrid.Parent = mainFrame

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

-- Row 4: Hitbox
hitboxButton = Instance.new("TextButton")
hitboxButton.BackgroundColor3 = colors.HitboxOff
hitboxButton.Text = "Hitbox helper: Off"
hitboxButton.TextColor3 = colors.TextPrimary
hitboxButton.TextSize = 12
hitboxButton.Font = Enum.Font.GothamBold
hitboxButton.Parent = buttonGrid
local cornerHitbox = Instance.new("UICorner")
cornerHitbox.CornerRadius = UDim.new(0, 6)
cornerHitbox.Parent = hitboxButton
applyButtonAnimation(hitboxButton)

-- Status Bar
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.fromScale(0, 0.92)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Awaiting Target Selection..."
statusLabel.TextColor3 = colors.TextDim
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

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

local function toggleHitboxAction()
    hitboxEnabled = not hitboxEnabled
    if hitboxEnabled then
        if not selectedTarget then
            hitboxEnabled = false
            notify("Action Denied", "Please select a target first.")
            return
        end
        hitboxButton.Text = "Hitbox helper: On"
        TweenService:Create(hitboxButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.HitboxOn}):Play()
        applyTargetHitbox(selectedTarget)
    else
        hitboxButton.Text = "Hitbox helper: Off"
        TweenService:Create(hitboxButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.HitboxOff}):Play()
        restoreTargetHitbox()
    end
    updateStatus()
end

-- Button Clicks
followButton.MouseButton1Click:Connect(toggleFollow)
invisToggleButton.MouseButton1Click:Connect(toggleInvisAction)
spectateButton.MouseButton1Click:Connect(toggleSpectateAction)
autoCombatButton.MouseButton1Click:Connect(toggleAutoCombatAction)
hitboxButton.MouseButton1Click:Connect(toggleHitboxAction)

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

    if hitboxEnabled and selectedTarget then
        table.insert(parts, "Hitbox helper: Active")
    end

    if #parts == 0 then
        statusLabel.Text = "Awaiting Target Selection..."
    else
        statusLabel.Text = table.concat(parts, " | ")
    end
end

refreshPlayerList()
playersService.PlayerAdded:Connect(refreshPlayerList)
playersService.PlayerRemoving:Connect(function(plr)
    if selectedTarget == plr then
        restoreTargetHitbox()
        selectedTarget = nil
        if playerDropdown then playerDropdown.Text = "Select Target..." end
        hitboxEnabled = false
        if hitboxButton then
            hitboxButton.Text = "Hitbox helper: Off"
            TweenService:Create(hitboxButton, TweenInfo.new(0.3), {BackgroundColor3 = colors.HitboxOff}):Play()
        end
    end
    refreshPlayerList()
    updateStatus()
end)

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

    if hitboxEnabled and selectedTarget then
        task.wait(0.2)
        applyTargetHitbox(selectedTarget)
    end

    if followEnabled and selectedTarget then
        task.wait(0.5)
        stopCombat()
        startCombat()
    end
end)

restoreTargetHitbox()

print("Target Farm GUI + TP Dummy Integration Loaded Successfully.")
