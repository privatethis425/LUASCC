-- Target Farm + Dynamic Spectate + Advanced Invisibility + Custom Keybinds + Force Reset (Decoupled Follow & Invis)

if getgenv().InvisScriptExecuted then
	return
end
getgenv().InvisScriptExecuted = true

local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local localPlayer = playersService.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================== CONFIGURABLE KEYBINDS ==========================
local Keybinds = {
    Follow = Enum.KeyCode.R,     -- Keybind for Start/Stop Follow
    Invis = Enum.KeyCode.T,      -- Keybind for Invisibility Toggle
    Spectate = Enum.KeyCode.Y,   -- Keybind for Spectate Toggle
}

local colors = {
	Background = Color3.fromRGB(17, 18, 23),
	Panel = Color3.fromRGB(26, 27, 34),
	Stroke = Color3.fromRGB(50, 51, 63),
	TextPrimary = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(145, 146, 158),
	InvisOn = Color3.fromRGB(70, 200, 130),
	InvisOff = Color3.fromRGB(200, 70, 80),
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

-- ========================== NOTIFICATION ==========================
local notificationFrame = nil
local function notify(title, message)
    if notificationFrame then notificationFrame:Destroy() end
    notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.fromOffset(320, 50)
    notificationFrame.Position = UDim2.new(0.5, -160, 0.5, -25)
    notificationFrame.AnchorPoint = Vector2.new(0, 0)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = CoreGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 22)
    titleLabel.Position = UDim2.fromOffset(0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = notificationFrame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 28)
    msgLabel.Position = UDim2.fromOffset(0, 22)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    msgLabel.TextSize = 14
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.Parent = notificationFrame

    task.delay(3, function()
        if notificationFrame then
            notificationFrame:Destroy()
            notificationFrame = nil
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
local playerDropdown = nil
local updateStatus = function() end

local function disableInvis()
	if not invisActive then
		return
	end
	invisActive = false
	getgenv().InvisActive = false
	invisProcessing = false
	if invisAnimation then
		pcall(function()
			if invisAnimation.IsPlaying then
				invisAnimation:Stop()
			end
		end)
		invisAnimation = nil
	end
	lastInvisHumanoid = nil
	local myChar = localPlayer.Character
	if myChar then
		local myRootPart = myChar:FindFirstChild("HumanoidRootPart")
		if myRootPart and savedRootCFrame then
			pcall(function()
				myRootPart.CFrame = savedRootCFrame
			end)
		end
		savedRootCFrame = nil
		local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
		if myHumanoid then
			pcall(function()
				Workspace.CurrentCamera.CameraSubject = myHumanoid
			end)
		end
		pcall(function()
			myChar:SetAttribute("NoHeadLerp", false)
		end)
		for _, val in pairs(invisConnections) do
			pcall(function()
				val:Disconnect()
			end)
		end
		invisConnections = {}
		for _, val2 in pairs(myChar:GetDescendants()) do
			if val2:IsA("BasePart") and val2.Name ~= "HumanoidRootPart" then
				val2.LocalTransparencyModifier = 0
			end
		end
	end
    if invisToggleButton then
    	invisToggleButton.Text = "Invis: Off [T]"
    	invisToggleButton.BackgroundColor3 = colors.InvisOff
    end
end

local function stopInvisAnimation()
	if invisAnimation then
		pcall(function()
			if invisAnimation.IsPlaying then
				invisAnimation:Stop()
			end
		end)
		invisAnimation = nil
	end
	lastInvisHumanoid = nil
	savedRootCFrame = nil
	invisProcessing = false
end

local function makeSemiTransparent(part)
	if not part:IsA("BasePart") then
		return
	end
	if part.Name == "HumanoidRootPart" then
		return
	end
	if part.Transparency == 1 then
		return
	end
	if part.Name:lower():find("hitbox") then
		return
	end
	part.LocalTransparencyModifier = 0.5
	local transparencyConn = part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
		if not invisActive then
			return
		end
		if part.LocalTransparencyModifier ~= 0.5 then
			part.LocalTransparencyModifier = 0.5
		end
	end)
	table.insert(invisConnections, transparencyConn)
end

local function hookTransparencyHandlers(model)
	for _, descendant in pairs(model:GetDescendants()) do
		makeSemiTransparent(descendant)
	end
	local descendantAddedConn = model.DescendantAdded:Connect(function(newDescendant)
		if invisActive then
			makeSemiTransparent(newDescendant)
		end
	end)
	table.insert(invisConnections, descendantAddedConn)
end

local function enableInvis()
	if invisActive then
		disableInvis()
		return
	end
	local myChar = localPlayer.Character
	if not myChar then
		return
	end
	local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
	local myRootPart = myChar:FindFirstChild("HumanoidRootPart")
	if not myHumanoid or not myRootPart then
		return
	end
	invisActive = true
	getgenv().InvisActive = true
	invisProcessing = false
	if myChar then
		hookTransparencyHandlers(myChar)
	end
    if invisToggleButton then
    	invisToggleButton.Text = "Invis: On [T]"
    	invisToggleButton.BackgroundColor3 = colors.InvisOn
    end
end

runService.Heartbeat:Connect(function()
	local desyncActive = getgenv().desync ~= nil
	if not invisActive and not desyncActive then
		return
	end
	if invisProcessing then
		return
	end
	invisProcessing = true
	local myChar = localPlayer.Character
	local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
	local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myChar or not myHumanoid or not myRootPart then
		invisProcessing = false
		return
	end
	if myHumanoid.Health <= 0 then
		if invisActive then
			task.spawn(stopInvisAnimation)
		end
		invisProcessing = false
		return
	end
	local myRootCFrame = myRootPart.CFrame
	local myVelocity = myRootPart.Velocity
	savedRootCFrame = myRootCFrame
	local currentCamera = Workspace.CurrentCamera
	local desyncCFrame = nil
	if invisActive then
		desyncCFrame = myRootCFrame
	end
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
					if invisAnimation.IsPlaying then
						invisAnimation:Stop()
					end
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
		pcall(function()
			currentInvisAnim:Stop()
		end)
	end
	if desyncCFrame then
		myRootPart.CFrame = myRootCFrame
	end
	myRootPart.Velocity = myVelocity
	invisProcessing = false
end)

-- ========================== COMBAT LOOP ==========================
local selectedTarget = nil
local followEnabled = false
local currentTarget = nil

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
            if sethiddenproperty then
                sethiddenproperty(root, "PhysicsRepRootPart", nil)
            end
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
            local targetName = target.Name
            local targetDisplay = target.DisplayName
            notify("Target left the server", targetDisplay .. " (@" .. targetName .. ")")
            followEnabled = false
            selectedTarget = nil
            if playerDropdown then
                playerDropdown.Text = "Select Player"
            end
            updateStatus()
            stopCombat()
            return
        end

        local targetChar = getCharacter(target)
        if not isCharacterValid(targetChar) then
            currentTarget = nil
            detachPhysics()
            -- Target died: Stop follow, but KEEP invis exactly as it is!
            followEnabled = false
            if followButton then
                followButton.Text = "Start Follow [R]"
                followButton.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            end
            stopCombat()
            updateStatus()
            notify("Target died", target.DisplayName .. " has died.")
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

        if not isAttackingAnim(myHum) and not targetChar:FindFirstChild("ForceField") then
            local communicate = myChar:FindFirstChild("Communicate")
            if communicate then
                communicate:FireServer({ Goal = "LeftClick" })
                task.wait(0.1)
                communicate:FireServer({ Goal = "LeftClickRelease" })
            end
        end
    end)
end

-- ========================== IMPROVED SPECTATE ==========================
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
        spectateButton.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
    end
    
    if spectateRenderConnection then
        spectateRenderConnection:Disconnect()
        spectateRenderConnection = nil
    end
    
    Camera.CameraType = Enum.CameraType.Custom
    if localPlayer.Character then
        Camera.CameraSubject = localPlayer.Character
    end
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    updateStatus()
end

local function startSpectate(targetPlayer)
    if not targetPlayer then return end
    if spectateEnabled then
        stopSpectate()
    end
    spectateTarget = targetPlayer
    spectateEnabled = true
    
    if spectateButton then
        spectateButton.Text = "Stop Spectate [Y]"
        spectateButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    end

    Yaw = 0
    Pitch = -0.3
    Distance = 10
    TargetDistance = 10

    Camera.CameraType = Enum.CameraType.Scriptable

    if spectateRenderConnection then spectateRenderConnection:Disconnect() end
    spectateRenderConnection = runService.RenderStepped:Connect(function(deltaTime)
        if not spectateEnabled or not spectateTarget or not spectateTarget.Parent then
            local name = spectateTarget and spectateTarget.Name or "Unknown"
            local display = spectateTarget and spectateTarget.DisplayName or "Unknown"
            notify("Spectate stopped", display .. " (@" .. name .. ") left the server")
            stopSpectate()
            return
        end

        local targetChar = getCharacter(spectateTarget)
        if not targetChar then return end
        local root = getRootPart(targetChar)
        if not root then
            root = targetChar:FindFirstChild("Head")
            if not root then return end
        end

        Distance = Distance + (TargetDistance - Distance) * (1 - math.exp(-DistanceLerpSpeed * deltaTime))

        local targetPos = root.Position
        local yawQuat = CFrame.Angles(0, Yaw, 0)
        local pitchQuat = CFrame.Angles(Pitch, 0, 0)
        local dir = (yawQuat * pitchQuat).LookVector * Distance
        local camPos = targetPos - dir

        Camera.CFrame = CFrame.new(camPos, targetPos)
    end)

    updateStatus()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if spectateEnabled then
            isRotating = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRotating = false
        if spectateEnabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement and isRotating and spectateEnabled then
        local sens = 0.005
        Yaw = Yaw - input.Delta.X * sens
        Pitch = math.clamp(Pitch - input.Delta.Y * sens, -1.5, 0.5)
    end

    if input.UserInputType == Enum.UserInputType.MouseWheel and spectateEnabled then
        local scrollAmount = input.Position.Z 
        local zoomSpeed = 3.5 
        TargetDistance = math.clamp(TargetDistance - scrollAmount * zoomSpeed, 2, 50)
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

-- ========================== SIMPLE GUI ==========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TargetFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(340, 270)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.fromOffset(0, 0)
title.BackgroundTransparency = 1
title.Text = "Target Farm"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Player selection dropdown
playerDropdown = Instance.new("TextButton")
playerDropdown.Size = UDim2.new(0.9, 0, 0, 30)
playerDropdown.Position = UDim2.fromScale(0.05, 0.18)
playerDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
playerDropdown.Text = "Select Player"
playerDropdown.TextColor3 = Color3.fromRGB(200,200,200)
playerDropdown.TextSize = 14
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.Parent = mainFrame
local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 4)
corner2.Parent = playerDropdown

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Size = UDim2.new(0.9, 0, 0, 120)
dropdownList.Position = UDim2.fromScale(0.05, 0.18 + 30/270 + 0.01)
dropdownList.BackgroundColor3 = Color3.fromRGB(40,40,45)
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.ZIndex = 10
dropdownList.Parent = mainFrame
local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 4)
corner3.Parent = dropdownList
dropdownList.CanvasSize = UDim2.new(0,0,0,0)
dropdownList.ScrollBarThickness = 4

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
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(50,50,55)
            btn.Text = plr.DisplayName .. " (" .. plr.Name .. ")"
            btn.TextColor3 = Color3.fromRGB(220,220,220)
            btn.TextSize = 13
            btn.Font = Enum.Font.Gotham
            btn.AutoButtonColor = true
            btn.ZIndex = 11
            btn.Parent = dropdownList
            btn.MouseButton1Click:Connect(function()
                selectedTarget = plr
                playerDropdown.Text = plr.DisplayName .. " (" .. plr.Name .. ")"
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
            height = height + 25
        end
    end
    dropdownList.CanvasSize = UDim2.new(0,0,0, height)
end

playerDropdown.MouseButton1Click:Connect(function()
    refreshPlayerList()
    dropdownList.Visible = not dropdownList.Visible
end)

-- Force Reset Button
local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.32, 0, 0, 30)
resetButton.Position = UDim2.fromScale(0.34, 0.52)
resetButton.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
resetButton.Text = "Force Reset"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.TextSize = 12
resetButton.Font = Enum.Font.GothamBold
resetButton.Parent = mainFrame
local cornerReset = Instance.new("UICorner")
cornerReset.CornerRadius = UDim.new(0, 4)
cornerReset.Parent = resetButton

resetButton.MouseButton1Click:Connect(function()
	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end)

-- Button row
local buttonRow = Instance.new("Frame")
buttonRow.Size = UDim2.new(0.95, 0, 0, 35)
buttonRow.Position = UDim2.fromScale(0.025, 0.67)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = mainFrame

followButton = Instance.new("TextButton")
followButton.Size = UDim2.new(0.32, 0, 1, 0)
followButton.Position = UDim2.fromScale(0, 0)
followButton.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
followButton.Text = "Start Follow [R]"
followButton.TextColor3 = Color3.fromRGB(255,255,255)
followButton.TextSize = 12
followButton.Font = Enum.Font.GothamBold
followButton.Parent = buttonRow
local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 4)
corner4.Parent = followButton

invisToggleButton = Instance.new("TextButton")
invisToggleButton.Name = "InvisToggle"
invisToggleButton.Size = UDim2.new(0.32, 0, 1, 0)
invisToggleButton.Position = UDim2.fromScale(0.34, 0)
invisToggleButton.BackgroundColor3 = colors.InvisOff
invisToggleButton.Font = Enum.Font.GothamBold
invisToggleButton.Text = "Invis: Off [T]"
invisToggleButton.TextColor3 = colors.TextPrimary
invisToggleButton.TextSize = 12
invisToggleButton.AutoButtonColor = false
invisToggleButton.Parent = buttonRow
local cornerInvis = Instance.new("UICorner")
cornerInvis.CornerRadius = UDim.new(0, 4)
cornerInvis.Parent = invisToggleButton

spectateButton = Instance.new("TextButton")
spectateButton.Size = UDim2.new(0.32, 0, 1, 0)
spectateButton.Position = UDim2.fromScale(0.68, 0)
spectateButton.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
spectateButton.Text = "Spectate [Y]"
spectateButton.TextColor3 = Color3.fromRGB(255,255,255)
spectateButton.TextSize = 12
spectateButton.Font = Enum.Font.GothamBold
spectateButton.Parent = buttonRow
local corner5 = Instance.new("UICorner")
corner5.CornerRadius = UDim.new(0, 4)
corner5.Parent = spectateButton

-- Toggle action functions
local function toggleFollow()
    followEnabled = not followEnabled
    if followEnabled then
        if not selectedTarget then
            followEnabled = false
            followButton.Text = "Start Follow [R]"
            followButton.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            notify("No player selected", "Please select a target first")
            return
        end
        followButton.Text = "Stop Follow [R]"
        followButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        startCombat()
    else
        followButton.Text = "Start Follow [R]"
        followButton.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
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
            notify("No player selected", "Please select a target first")
            return
        end
        startSpectate(selectedTarget)
    end
end

-- Button mouse clicks
followButton.MouseButton1Click:Connect(toggleFollow)
invisToggleButton.MouseButton1Click:Connect(toggleInvisAction)
spectateButton.MouseButton1Click:Connect(toggleSpectateAction)

-- ========================== KEYBIND LISTENER ==========================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Keybinds.Follow then
        toggleFollow()
    elseif input.KeyCode == Keybinds.Invis then
        toggleInvisAction()
    elseif input.KeyCode == Keybinds.Spectate then
        toggleSpectateAction()
    end
end)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.fromScale(0, 0.88)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Select a player and press Start"
statusLabel.TextColor3 = Color3.fromRGB(150,150,150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

updateStatus = function()
    local parts = {}
    if followEnabled and selectedTarget then
        table.insert(parts, "Following: " .. selectedTarget.DisplayName)
    elseif followEnabled and not selectedTarget then
        table.insert(parts, "Follow: no target")
    end

    if spectateEnabled and spectateTarget then
        table.insert(parts, "Spectating: " .. spectateTarget.DisplayName)
    elseif spectateEnabled and not spectateTarget then
        table.insert(parts, "Spectate: no target")
    end

    if #parts == 0 then
        statusLabel.Text = "Select a player and press Start"
    else
        statusLabel.Text = table.concat(parts, " | ")
    end
end

refreshPlayerList()
playersService.PlayerAdded:Connect(refreshPlayerList)
playersService.PlayerRemoving:Connect(refreshPlayerList)

setupAntiAfk()

-- ========================== LOCAL PLAYER CHARACTER LOAD HANDLER ==========================
localPlayer.CharacterAdded:Connect(function(char)
    -- Clean up garbage connections from the old dead character
    for _, val in pairs(invisConnections) do
        pcall(function() val:Disconnect() end)
    end
    invisConnections = {}
    
    -- Clear saved position so we don't accidentally teleport to where we died when toggling invis off
    savedRootCFrame = nil

    -- Re-hook transparency handling if invis is still ON
    if invisActive then
        task.spawn(function()
            char:WaitForChild("HumanoidRootPart", 5)
            if invisActive then
                hookTransparencyHandlers(char)
            end
        end)
    end

    if followEnabled and selectedTarget then
        task.wait(0.5)
        stopCombat()
        startCombat()
    end
end)

print("Target Farm + Keybinds + Permanent Invis Loaded successfully.")
