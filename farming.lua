if getgenv().ScriptExecuted then
	return
end

getgenv().ScriptExecuted = true

local countries = {
	"France",
	"Netherlands",
	"United States",
	"United Kingdom",
	"Australia",
	"Germany",
	"India",
	"Brazil",
	"Singapore",
	"Japan",
}

local colors = {
	Background = Color3.fromRGB(17, 18, 23),
	Panel = Color3.fromRGB(26, 27, 34),
	PanelAlt = Color3.fromRGB(33, 34, 43),
	Stroke = Color3.fromRGB(50, 51, 63),
	TextPrimary = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(145, 146, 158),
	Amber = Color3.fromRGB(240, 170, 60),
	Teal = Color3.fromRGB(70, 200, 190),
	Rose = Color3.fromRGB(225, 95, 110),
	Lavender = Color3.fromRGB(150, 130, 235),
	FarmOn = Color3.fromRGB(70, 200, 130),
	FarmOff = Color3.fromRGB(200, 70, 80),
}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or colors.Stroke
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, amount)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.Parent = parent
	return padding
end

local function createTween(target, properties, duration, easingStyle, easingDirection)
	local tweenService = game:GetService("TweenService")
	return tweenService:Create(
		target,
		TweenInfo.new(
			duration or 0.2,
			easingStyle or Enum.EasingStyle.Quad,
			easingDirection or Enum.EasingDirection.Out
		),
		properties
	)
end

local function configureLabel(label, truncate)
	label.ClipsDescendants = true
	if truncate then
		label.TextTruncate = Enum.TextTruncate.AtEnd
	end

end

local farmEnabled = true
local startVisualOptimizer
local stopVisualOptimizer
local unusedFlag = false
local httpService = game:GetService("HttpService")

local function jsonEncode(value)
	return httpService:JSONEncode(value)
end

local playersService = game:GetService("Players")
local localPlayer = playersService.LocalPlayer
local baseFolder = "GalaxyHub"
local userFolder = "ZKAYHub/PublicFarm/" .. localPlayer.Name
local settingsPath = userFolder .. "/settings.json"

local function makeFolders()
	if not isfolder(baseFolder) then
		makefolder(baseFolder)
	end
	if not isfolder(userFolder) then
		makefolder(userFolder)
	end

end

local defaultSettings = {
	country = countries[1],
	hopOnCount = "1000",
	webhookUrl = "",
}

local farmSettings = table.clone(defaultSettings)

local function saveSettings()
	makeFolders()
	local encodeOk, encodedJson = pcall(httpService.JSONEncode, httpService, farmSettings)
	if encodeOk then
		writefile(settingsPath, encodedJson)
	else
		warn("[galaxy Hub] Failed to encode settings:", encodedJson)
	end

end

local function loadSettings()
	makeFolders()
	if not isfile(settingsPath) then
		return
	end
	local readOk, fileContent = pcall(readfile, settingsPath)
	if not readOk then
		warn("[GalaxyHub] Failed to read settings file:", fileContent)
		return
	end
	local decodeOk, decoded = pcall(httpService.JSONDecode, httpService, fileContent)
	if not decodeOk or type(decoded) ~= "table" then
		warn("[galaxyHub] Failed to decode settings file, using defaults")
		return
	end
	for key, value in pairs(decoded) do
		if key == "hopOnCount" and tonumber(value) and tonumber(value) <= 500 then
			farmSettings[key] = "1000"
		else
			farmSettings[key] = value
		end
	end

end

loadSettings()
getgenv().TimeFarmed = getgenv().TimeFarmed or 0
getgenv().session_start = getgenv().session_start or os.time()
getgenv().carriedKills = getgenv().carriedKills or 0
getgenv().emotes = getgenv().emotes or 0
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GalaxyFarmUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 218)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = colors.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true
addCorner(mainFrame, 18)
addStroke(mainFrame, colors.Stroke, 1)
local accentStrip = Instance.new("Frame")
accentStrip.Name = "AccentStrip"
accentStrip.BackgroundColor3 = colors.Amber
accentStrip.BorderSizePixel = 0
accentStrip.Size = UDim2.new(1, 0, 0, 4)
accentStrip.Position = UDim2.fromOffset(0, 0)
accentStrip.ZIndex = 2
mainFrame.ClipsDescendants = true
accentStrip.Parent = mainFrame
local mainLayout = Instance.new("UIListLayout")
mainLayout.FillDirection = Enum.FillDirection.Vertical
mainLayout.Padding = UDim.new(0, 14)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainFrame
addPadding(mainFrame, 18)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.LayoutOrder = 1
titleBar.Parent = mainFrame
local badgeFrame = Instance.new("Frame")
badgeFrame.Name = "Badge"
badgeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
badgeFrame.Size = UDim2.fromOffset(36, 36)
badgeFrame.Position = UDim2.fromOffset(0, 2)
addCorner(badgeFrame, 10)
badgeFrame.Parent = titleBar
local badgeText = Instance.new("TextLabel")
badgeText.BackgroundTransparency = 1
badgeText.Size = UDim2.new(1, 0, 1, 0)
badgeText.Font = Enum.Font.GothamBold
badgeText.Text = "PY"
badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
badgeText.TextSize = 18
badgeText.Parent = badgeFrame
local timeFarmedBox = Instance.new("Frame")
timeFarmedBox.Name = "TimeFarmedBox"
timeFarmedBox.BackgroundColor3 = colors.PanelAlt
timeFarmedBox.Size = UDim2.fromOffset(112, 36)
timeFarmedBox.Position = UDim2.new(1, -112, 0, 2)
addCorner(timeFarmedBox, 10)
addStroke(timeFarmedBox, colors.Stroke, 1)
timeFarmedBox.ClipsDescendants = true
timeFarmedBox.Parent = titleBar
local timeIconLabel = Instance.new("TextLabel")
timeIconLabel.BackgroundTransparency = 1
timeIconLabel.Size = UDim2.fromOffset(20, 36)
timeIconLabel.Position = UDim2.fromOffset(8, 0)
timeIconLabel.Font = Enum.Font.GothamBold
timeIconLabel.Text = "\1521"
timeIconLabel.TextColor3 = colors.Amber
timeIconLabel.TextSize = 14
timeIconLabel.Parent = timeFarmedBox
local timeFarmedLabel = Instance.new("TextLabel")
timeFarmedLabel.Name = "Value"
timeFarmedLabel.BackgroundTransparency = 1
timeFarmedLabel.Size = UDim2.new(1, -34, 1, 0)
timeFarmedLabel.Position = UDim2.fromOffset(30, 0)
timeFarmedLabel.Font = Enum.Font.GothamBold
timeFarmedLabel.Text = "00:00:00"
timeFarmedLabel.TextColor3 = colors.TextPrimary
timeFarmedLabel.TextSize = 13
timeFarmedLabel.TextXAlignment = Enum.TextXAlignment.Left
configureLabel(timeFarmedLabel, true)
timeFarmedLabel.Parent = timeFarmedBox
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -168, 0, 20)
titleLabel.Position = UDim2.fromOffset(48, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "ProjectYielding"
titleLabel.TextColor3 = colors.TextPrimary
titleLabel.TextSize = 17
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
configureLabel(titleLabel, true)
titleLabel.Parent = titleBar
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Size = UDim2.new(1, -168, 0, 16)
subtitleLabel.Position = UDim2.fromOffset(48, 20)
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.Text = "Public Server Farm"
subtitleLabel.TextColor3 = colors.TextDim
subtitleLabel.TextSize = 12
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
configureLabel(subtitleLabel, true)
subtitleLabel.Parent = titleBar

local function makeStatsChip(parent, chipLabel, value, color)
	local chip = Instance.new("Frame")
	chip.Name = chipLabel .. "Chip"
	chip.BackgroundColor3 = colors.Panel
	chip.BorderSizePixel = 0
	chip.Size = UDim2.new(0.25, -9, 1, 0)
	chip.ClipsDescendants = true
	addCorner(chip, 12)
	addStroke(chip, colors.Stroke, 1)
	local dot = Instance.new("Frame")
	dot.BackgroundColor3 = color
	dot.Size = UDim2.fromOffset(8, 8)
	dot.Position = UDim2.fromOffset(12, 12)
	addCorner(dot, 4)
	dot.Parent = chip
	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.Position = UDim2.fromOffset(12, 26)
	valueLabel.Size = UDim2.new(1, -20, 0, 26)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = value
	valueLabel.TextColor3 = colors.TextPrimary
	valueLabel.TextSize = 19
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	configureLabel(valueLabel, true)
	valueLabel.Parent = chip
	local captionLabel = Instance.new("TextLabel")
	captionLabel.BackgroundTransparency = 1
	captionLabel.Position = UDim2.fromOffset(12, 52)
	captionLabel.Size = UDim2.new(1, -20, 0, 12)
	captionLabel.Font = Enum.Font.Gotham
	captionLabel.Text = string.upper(chipLabel)
	captionLabel.TextColor3 = colors.TextDim
	captionLabel.TextSize = 9
	captionLabel.TextXAlignment = Enum.TextXAlignment.Left
	configureLabel(captionLabel, true)
	captionLabel.Parent = chip
	chip.Parent = parent
	return chip, valueLabel
end

local statsRow = Instance.new("Frame")
statsRow.Name = "StatsRow"
statsRow.BackgroundTransparency = 1
statsRow.Size = UDim2.new(1, 0, 0, 76)
statsRow.LayoutOrder = 2
statsRow.Parent = mainFrame
local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.Padding = UDim.new(0, 12)
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Parent = statsRow
local killsChip, killsValueLabel = makeStatsChip(statsRow, "Kills", "0", colors.Rose)
local killsPerHourChip, killsPerHourValueLabel = makeStatsChip(statsRow, "Kills/hr", "0", colors.Teal)
local emotesChip, emotesValueLabel = makeStatsChip(statsRow, "Emotes", "0", colors.Lavender)
local totalChip, totalValueLabel = makeStatsChip(statsRow, "Total", "0", colors.Amber)
local controlsCard = Instance.new("Frame")
controlsCard.Name = "ControlsCard"
controlsCard.BackgroundColor3 = colors.Panel
controlsCard.BorderSizePixel = 0
controlsCard.Size = UDim2.new(1, 0, 0, 92)
controlsCard.LayoutOrder = 3
controlsCard.ZIndex = 5
addCorner(controlsCard, 14)
addStroke(controlsCard, colors.Stroke, 1)
controlsCard.Parent = mainFrame
addPadding(controlsCard, 14)
local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.Padding = UDim.new(0, 14)
controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
controlsLayout.Parent = controlsCard
local countryBox = Instance.new("Frame")
countryBox.Name = "CountryBox"
countryBox.BackgroundTransparency = 1
countryBox.Size = UDim2.new(0.5, -7, 1, 0)
countryBox.ZIndex = 5
countryBox.Parent = controlsCard
local regionLabel = Instance.new("TextLabel")
regionLabel.BackgroundTransparency = 1
regionLabel.Position = UDim2.fromOffset(0, 0)
regionLabel.Size = UDim2.new(1, 0, 0, 14)
regionLabel.Font = Enum.Font.GothamMedium
regionLabel.Text = "REGION"
regionLabel.TextColor3 = colors.TextDim
regionLabel.TextSize = 11
regionLabel.TextXAlignment = Enum.TextXAlignment.Left
configureLabel(regionLabel, true)
regionLabel.Parent = countryBox
local dropdownButton = Instance.new("TextButton")
dropdownButton.Name = "DropdownButton"
dropdownButton.BackgroundColor3 = colors.PanelAlt
dropdownButton.Position = UDim2.fromOffset(0, 20)
dropdownButton.Size = UDim2.new(1, 0, 0, 30)
dropdownButton.AutoButtonColor = false
dropdownButton.Font = Enum.Font.Gotham
dropdownButton.Text = ""
dropdownButton.ZIndex = 5
addCorner(dropdownButton, 8)
dropdownButton.Parent = countryBox
local countryLabel = Instance.new("TextLabel")
countryLabel.BackgroundTransparency = 1
countryLabel.Size = UDim2.new(1, -28, 1, 0)
countryLabel.Position = UDim2.fromOffset(10, 0)
countryLabel.Font = Enum.Font.Gotham
countryLabel.Text = farmSettings.country or "Select..."
countryLabel.TextColor3 = colors.TextPrimary
countryLabel.TextSize = 13
countryLabel.TextXAlignment = Enum.TextXAlignment.Left
countryLabel.ZIndex = 6
configureLabel(countryLabel, true)
countryLabel.Parent = dropdownButton
local chevronLabel = Instance.new("TextLabel")
chevronLabel.BackgroundTransparency = 1
chevronLabel.Size = UDim2.fromOffset(20, 30)
chevronLabel.Position = UDim2.new(1, -22, 0, 0)
chevronLabel.Font = Enum.Font.GothamBold
chevronLabel.Text = "\1982"
chevronLabel.TextColor3 = colors.TextDim
chevronLabel.TextSize = 12
chevronLabel.ZIndex = 6
chevronLabel.Parent = dropdownButton
local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Name = "DropdownList"
dropdownList.BackgroundColor3 = colors.PanelAlt
dropdownList.BorderSizePixel = 0
dropdownList.Position = UDim2.fromOffset(0, 54)
dropdownList.Size = UDim2.new(1, 0, 0, 0)
dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownList.ScrollingDirection = Enum.ScrollingDirection.Y
dropdownList.ScrollBarThickness = 6
dropdownList.ScrollBarImageColor3 = colors.TextDim
dropdownList.ClipsDescendants = true
dropdownList.Visible = false
dropdownList.ZIndex = 10
addCorner(dropdownList, 8)
addStroke(dropdownList, colors.Stroke, 1)
dropdownList.Parent = countryBox
local dropdownListLayout = Instance.new("UIListLayout")
dropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownListLayout.Parent = dropdownList
local dropdownOpen = false
local rowHeight = 28
local maxVisibleRows = 5

local function closeDropdown()
	dropdownOpen = false
	dropdownList.Visible = false
	dropdownList.Size = UDim2.new(1, 0, 0, 0)
	chevronLabel.Text = "\1982"
end

local function openDropdown()
	dropdownOpen = true
	dropdownList.Visible = true
	chevronLabel.Text = "\1972"
	dropdownList.CanvasSize = UDim2.new(0, 0, 0, #countries * rowHeight)
	local uiScaleRef = mainFrame:FindFirstChildOfClass("UIScale")
	local scaleValue = (uiScaleRef and uiScaleRef.Scale > 0) and uiScaleRef.Scale or 1
	local currentCamera = workspace.CurrentCamera
	local viewportHeight = currentCamera and currentCamera.ViewportSize.Y or 600
	local bottomMargin = 12
	local maxHeightPx = viewportHeight - dropdownList.AbsolutePosition.Y - bottomMargin
	local maxHeightScaled = maxHeightPx / scaleValue
	local visibleRows = math.max(1, math.floor(maxHeightScaled / rowHeight))
	local clampedRows = math.min(#countries, maxVisibleRows, visibleRows)
	dropdownList.Size = UDim2.new(1, 0, 0, clampedRows * rowHeight)
end

dropdownButton.MouseButton1Click:Connect(function()
	if dropdownOpen then
		closeDropdown()
	else
		openDropdown()
	end

end)

for index, country in ipairs(countries) do
	local countryButton = Instance.new("TextButton")
	countryButton.Name = country
	countryButton.LayoutOrder = index
	countryButton.BackgroundColor3 = colors.PanelAlt
	countryButton.AutoButtonColor = true
	countryButton.Size = UDim2.new(1, 0, 0, rowHeight)
	countryButton.Font = Enum.Font.Gotham
	countryButton.Text = "   " .. country
	countryButton.TextXAlignment = Enum.TextXAlignment.Left
	countryButton.TextColor3 = colors.TextPrimary
	countryButton.TextSize = 13
	countryButton.ZIndex = 11
	configureLabel(countryButton, true)
	countryButton.Parent = dropdownList
	countryButton.MouseButton1Click:Connect(function()
		farmSettings.country = country
		countryLabel.Text = country
		closeDropdown()
		saveSettings()
	end)
end

local hopOnBox = Instance.new("Frame")
hopOnBox.Name = "HopOnBox"
hopOnBox.BackgroundTransparency = 1
hopOnBox.Size = UDim2.new(0.5, -7, 1, 0)
hopOnBox.Parent = controlsCard
local hopOnTitle = Instance.new("TextLabel")
hopOnTitle.BackgroundTransparency = 1
hopOnTitle.Position = UDim2.fromOffset(0, 0)
hopOnTitle.Size = UDim2.new(1, 0, 0, 14)
hopOnTitle.Font = Enum.Font.GothamMedium
hopOnTitle.Text = "HOP ON THRESHOLD"
hopOnTitle.TextColor3 = colors.TextDim
hopOnTitle.TextSize = 11
hopOnTitle.TextXAlignment = Enum.TextXAlignment.Left
configureLabel(hopOnTitle, true)
hopOnTitle.Parent = hopOnBox
local hopOnInput = Instance.new("TextBox")
hopOnInput.Name = "HopOnInput"
hopOnInput.BackgroundColor3 = colors.PanelAlt
hopOnInput.Position = UDim2.fromOffset(0, 20)
hopOnInput.Size = UDim2.new(1, 0, 0, 30)
hopOnInput.Font = Enum.Font.Gotham
hopOnInput.PlaceholderText = "kills num"
hopOnInput.PlaceholderColor3 = colors.TextDim
hopOnInput.Text = farmSettings.hopOnCount or ""
hopOnInput.TextColor3 = colors.TextPrimary
hopOnInput.TextSize = 13
hopOnInput.ClearTextOnFocus = false
hopOnInput.TextXAlignment = Enum.TextXAlignment.Left
hopOnInput.ClipsDescendants = true
addCorner(hopOnInput, 8)
hopOnInput.Parent = hopOnBox
local hopOnPadding = Instance.new("UIPadding")
hopOnPadding.PaddingLeft = UDim.new(0, 10)
hopOnPadding.Parent = hopOnInput
hopOnInput:GetPropertyChangedSignal("Text"):Connect(function()
	local digitsOnly = hopOnInput.Text:gsub("%D", "")
	if digitsOnly ~= hopOnInput.Text then
		hopOnInput.Text = digitsOnly
	end
	farmSettings.hopOnCount = digitsOnly
	saveSettings()
end)
local webhookRow = Instance.new("Frame")
webhookRow.Name = "WebhookRow"
webhookRow.BackgroundTransparency = 1
webhookRow.Size = UDim2.new(1, 0, 0, 42)
webhookRow.LayoutOrder = 4
webhookRow.Parent = mainFrame
local webhookRowLayout = Instance.new("UIListLayout")
webhookRowLayout.FillDirection = Enum.FillDirection.Horizontal
webhookRowLayout.Padding = UDim.new(0, 12)
webhookRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
webhookRowLayout.Parent = webhookRow
local webhookInput = Instance.new("TextBox")
webhookInput.Name = "WebhookInput"
webhookInput.BackgroundColor3 = colors.Panel
webhookInput.BorderSizePixel = 0
webhookInput.Size = UDim2.new(1, -136, 1, 0)
webhookInput.Font = Enum.Font.Gotham
webhookInput.PlaceholderText = "https://discord.com/api/webhooks/..."
webhookInput.PlaceholderColor3 = colors.TextDim
webhookInput.Text = farmSettings.webhookUrl or ""
webhookInput.TextColor3 = colors.TextPrimary
webhookInput.TextSize = 13
webhookInput.ClearTextOnFocus = false
webhookInput.TextXAlignment = Enum.TextXAlignment.Left
webhookInput.ClipsDescendants = true
addCorner(webhookInput, 10)
addStroke(webhookInput, colors.Stroke, 1)
webhookInput.Parent = webhookRow
webhookInput:GetPropertyChangedSignal("Text"):Connect(function()
	farmSettings.webhookUrl = webhookInput.Text
	saveSettings()
end)
local webhookPadding = Instance.new("UIPadding")
webhookPadding.PaddingLeft = UDim.new(0, 12)
webhookPadding.Parent = webhookInput
local testWebhookButton = Instance.new("TextButton")
testWebhookButton.Name = "TestWebhook"
testWebhookButton.BackgroundColor3 = colors.PanelAlt
testWebhookButton.Size = UDim2.new(0, 124, 1, 0)
testWebhookButton.Font = Enum.Font.GothamMedium
testWebhookButton.Text = "Test Webhook"
testWebhookButton.TextColor3 = colors.TextPrimary
testWebhookButton.TextSize = 13
addCorner(testWebhookButton, 10)
addStroke(testWebhookButton, colors.Stroke, 1)
testWebhookButton.Parent = webhookRow
local bottomRow = Instance.new("Frame")
bottomRow.Name = "BottomRow"
bottomRow.BackgroundTransparency = 1
bottomRow.Size = UDim2.new(1, 0, 0, 46)
bottomRow.LayoutOrder = 5
bottomRow.Parent = mainFrame
local farmToggleButton = Instance.new("TextButton")
farmToggleButton.Name = "FarmToggle"
farmToggleButton.BackgroundColor3 = colors.FarmOn
farmToggleButton.Size = UDim2.new(1, 0, 1, 0)
farmToggleButton.Font = Enum.Font.GothamBold
farmToggleButton.Text = "Start Farm"
farmToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmToggleButton.TextSize = 15
farmToggleButton.AutoButtonColor = false
addCorner(farmToggleButton, 12)
farmToggleButton.Parent = bottomRow

local function setFarmState(enabled)
	farmEnabled = enabled
	if enabled then
		farmToggleButton.Text = "Stop Farm"
		createTween(farmToggleButton, { BackgroundColor3 = colors.FarmOff }, 0.18):Play()
		if startVisualOptimizer then
			startVisualOptimizer()
		end
	else
		if stopVisualOptimizer then
			stopVisualOptimizer()
		end
		pcall(function()
			localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-42, 1855, 25227)
		end)
		farmToggleButton.Text = "Start Farm"
		createTween(farmToggleButton, { BackgroundColor3 = colors.FarmOn }, 0.18):Play()
	end

end

farmToggleButton.MouseButton1Click:Connect(function()
	setFarmState(not farmEnabled)
end)
local hopServerRow = Instance.new("Frame")
hopServerRow.Name = "HopServerRow"
hopServerRow.BackgroundTransparency = 1
hopServerRow.Size = UDim2.new(1, 0, 0, 46)
hopServerRow.LayoutOrder = 6
hopServerRow.Parent = mainFrame
local hopServerRowLayout = Instance.new("UIListLayout")
hopServerRowLayout.FillDirection = Enum.FillDirection.Horizontal
hopServerRowLayout.Padding = UDim.new(0, 12)
hopServerRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
hopServerRowLayout.Parent = hopServerRow
local hopServerButton = Instance.new("TextButton")
hopServerButton.Name = "HopServer"
hopServerButton.LayoutOrder = 1
hopServerButton.BackgroundColor3 = colors.PanelAlt
hopServerButton.Size = UDim2.new(2 / 3, -6, 1, 0)
hopServerButton.Font = Enum.Font.GothamBold
hopServerButton.Text = "Hop Server"
hopServerButton.TextColor3 = colors.TextPrimary
hopServerButton.TextSize = 15
hopServerButton.AutoButtonColor = false
addCorner(hopServerButton, 12)
addStroke(hopServerButton, colors.Stroke, 1)
hopServerButton.Parent = hopServerRow
local renderToggleButton = Instance.new("TextButton")
renderToggleButton.Name = "NoRenderToggle"
renderToggleButton.LayoutOrder = 2
renderToggleButton.BackgroundColor3 = colors.PanelAlt
renderToggleButton.Size = UDim2.new(1 / 3, -6, 1, 0)
renderToggleButton.Font = Enum.Font.GothamBold
renderToggleButton.Text = "Render: On"
renderToggleButton.TextColor3 = colors.TextPrimary
renderToggleButton.TextSize = 13
renderToggleButton.AutoButtonColor = false
renderToggleButton.ClipsDescendants = true
addCorner(renderToggleButton, 12)
addStroke(renderToggleButton, colors.Stroke, 1)
renderToggleButton.Parent = hopServerRow
local renderEnabled = getgenv().renderEnabled ~= nil and getgenv().renderEnabled or false

local function setRender(enabled)
	renderEnabled = true
	getgenv().renderEnabled = true
	renderToggleButton.Text = "Render: On"

end

renderToggleButton.MouseButton1Click:Connect(function() end)
setRender(true)
local creditsRow = Instance.new("Frame")
creditsRow.Name = "CreditsRow"
creditsRow.BackgroundTransparency = 1
creditsRow.Size = UDim2.new(1, 0, 0, 18)
creditsRow.LayoutOrder = 6
creditsRow.Parent = mainFrame
local creditsLabel = Instance.new("TextLabel")
creditsLabel.Name = "CreditsLabel"
creditsLabel.BackgroundTransparency = 1
creditsLabel.Size = UDim2.new(1, 0, 1, 0)
creditsLabel.Font = Enum.Font.Gotham
creditsLabel.Text =
	"Copyright to: @zkayreal (Script Owner); @unauthorization. (Co-Owner); @invincible.samurai (Architect)"
creditsLabel.TextColor3 = colors.TextDim
creditsLabel.TextSize = 13
creditsLabel.TextXAlignment = Enum.TextXAlignment.Center
creditsLabel.TextScaled = false
creditsLabel.TextWrapped = true
creditsLabel.Parent = creditsRow

-- Keep the public farm UI compact with only active farm stats and controls.
mainFrame.Size = UDim2.new(0, 320, 0, 218)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.BackgroundColor3 = colors.Background
mainLayout:Destroy()
accentStrip:Destroy()
local mainPadding = mainFrame:FindFirstChildOfClass("UIPadding")
if mainPadding then
	mainPadding:Destroy()
end
timeFarmedLabel.Visible = false
timeFarmedLabel.Parent = nil
testWebhookButton.Visible = false
testWebhookButton.Parent = nil
renderToggleButton:Destroy()
killsPerHourValueLabel.Visible = false
killsPerHourValueLabel.Parent = nil
totalValueLabel.Visible = false
totalValueLabel.Parent = nil
controlsCard:Destroy()
webhookRow:Destroy()
creditsRow:Destroy()
statsLayout:Destroy()
titleLabel.Parent = mainFrame
titleLabel.Position = UDim2.fromOffset(16, 10)
titleLabel.Size = UDim2.new(1, -32, 0, 24)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "ZYke Farm"
titleLabel.TextColor3 = colors.TextPrimary
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = nil
badgeFrame:Destroy()
timeFarmedBox:Destroy()
titleBar:Destroy()

local function styleGalaxyChip(chip, captionText, valueLabel, dotColor, position, size)
	chip.Parent = mainFrame
	chip.Visible = true
	chip.Size = size
	chip.Position = position
	chip.BackgroundColor3 = colors.Panel
	chip.BorderSizePixel = 0
	for index2, child in ipairs(chip:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = true
			child.BackgroundColor3 = dotColor
			child.Size = UDim2.fromOffset(7, 7)
			child.Position = UDim2.fromOffset(10, 13)
		elseif child:IsA("TextLabel") and child ~= valueLabel then
			child.Visible = true
			child.Position = UDim2.fromOffset(22, 4)
			child.Size = UDim2.new(1, -30, 0, 12)
			child.Font = Enum.Font.GothamMedium
			child.Text = captionText
			child.TextColor3 = colors.TextDim
			child.TextSize = 9
			child.TextXAlignment = Enum.TextXAlignment.Left
		end
	end
	valueLabel.Visible = true
	valueLabel.Position = UDim2.fromOffset(10, 18)
	valueLabel.Size = UDim2.new(1, -20, 0, 24)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextColor3 = colors.TextPrimary
	valueLabel.TextSize = 18
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
end

styleGalaxyChip(killsChip, "KILLS", killsValueLabel, colors.Rose, UDim2.fromOffset(16, 44), UDim2.fromOffset(138, 52))
styleGalaxyChip(emotesChip, "EMOTES", emotesValueLabel, colors.Lavender, UDim2.fromOffset(166, 44), UDim2.fromOffset(138, 52))
killsPerHourChip:Destroy()
totalChip:Destroy()
statsRow:Destroy()

local timeChip = Instance.new("Frame")
timeChip.Name = "TimeChip"
timeChip.BackgroundColor3 = colors.Panel
timeChip.BorderSizePixel = 0
timeChip.Position = UDim2.fromOffset(16, 106)
timeChip.Size = UDim2.fromOffset(288, 38)
addCorner(timeChip, 10)
addStroke(timeChip, colors.Stroke, 1)
timeChip.Parent = mainFrame

local timeDot = Instance.new("Frame")
timeDot.BackgroundColor3 = colors.Teal
timeDot.Size = UDim2.fromOffset(7, 7)
timeDot.Position = UDim2.fromOffset(10, 15)
addCorner(timeDot, 4)
timeDot.Parent = timeChip

local timeCaptionLabel = Instance.new("TextLabel")
timeCaptionLabel.BackgroundTransparency = 1
timeCaptionLabel.Position = UDim2.fromOffset(24, 0)
timeCaptionLabel.Size = UDim2.new(0.5, -24, 1, 0)
timeCaptionLabel.Font = Enum.Font.GothamMedium
timeCaptionLabel.Text = "TIME"
timeCaptionLabel.TextColor3 = colors.TextDim
timeCaptionLabel.TextSize = 10
timeCaptionLabel.TextXAlignment = Enum.TextXAlignment.Left
configureLabel(timeCaptionLabel, true)
timeCaptionLabel.Parent = timeChip

timeFarmedLabel.Visible = true
timeFarmedLabel.Parent = timeChip
timeFarmedLabel.Position = UDim2.new(0.5, 0, 0, 0)
timeFarmedLabel.Size = UDim2.new(0.5, -12, 1, 0)
timeFarmedLabel.Font = Enum.Font.GothamBold
timeFarmedLabel.TextColor3 = colors.TextPrimary
timeFarmedLabel.TextSize = 15
timeFarmedLabel.TextXAlignment = Enum.TextXAlignment.Right

farmToggleButton.Parent = mainFrame
hopServerButton.Parent = mainFrame
bottomRow:Destroy()
hopServerRow:Destroy()
farmToggleButton.Position = UDim2.fromOffset(16, 158)
farmToggleButton.Size = UDim2.fromOffset(138, 40)
farmToggleButton.TextSize = 13
addCorner(farmToggleButton, 11)
hopServerButton.Visible = true
hopServerButton.Position = UDim2.fromOffset(166, 158)
hopServerButton.Size = UDim2.fromOffset(138, 40)
hopServerButton.Text = "Server Hop"
hopServerButton.TextSize = 13
hopServerButton.BackgroundColor3 = colors.PanelAlt
addCorner(hopServerButton, 11)
addStroke(hopServerButton, colors.Stroke, 1)
emotesValueLabel.Name = "EmotesValue"
killsValueLabel.Name = "KillsValue"
local tweenService = game:GetService("TweenService")

local notificationStack = {}
local notificationWidth = 300
local notificationHeight = 64
local unusedMargin = 10
local bottomOffset = 20
local sideOffset = 20

local function shiftNotifications()
	local offsetY = 20
	for index2 = #notificationStack, 1, -1 do
		local notif = notificationStack[index2]
		local targetY = -84
		tweenService
			:Create(
				notif,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Position = UDim2.new(1, -notificationWidth - sideOffset, 1, targetY) }
			)
			:Play()
		offsetY = 94
	end

end

local function notify(title, message, duration)
	duration = duration or 3.5
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.BackgroundColor3 = colors.Panel
	notif.BorderSizePixel = 0
	notif.Size = UDim2.fromOffset(notificationWidth, notificationHeight)
	notif.Position = UDim2.new(1, 20, 1, -bottomOffset - notificationHeight)
	notif.AnchorPoint = Vector2.new(0, 0)
	notif.ZIndex = 50
	addCorner(notif, 12)
	addStroke(notif, colors.Stroke, 1)
	notif.Parent = screenGui
	local accentBar = Instance.new("Frame")
	accentBar.BackgroundColor3 = colors.Amber
	accentBar.BorderSizePixel = 0
	accentBar.Size = UDim2.new(0, 4, 1, -16)
	accentBar.Position = UDim2.fromOffset(8, 8)
	accentBar.ZIndex = 51
	addCorner(accentBar, 2)
	accentBar.Parent = notif
	local titleLabel2 = Instance.new("TextLabel")
	titleLabel2.BackgroundTransparency = 1
	titleLabel2.Position = UDim2.fromOffset(24, 10)
	titleLabel2.Size = UDim2.new(1, -36, 0, 18)
	titleLabel2.Font = Enum.Font.GothamBold
	titleLabel2.Text = title
	titleLabel2.TextColor3 = colors.TextPrimary
	titleLabel2.TextSize = 14
	titleLabel2.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel2.ZIndex = 51
	configureLabel(titleLabel2, true)
	titleLabel2.Parent = notif
	local messageLabel = Instance.new("TextLabel")
	messageLabel.BackgroundTransparency = 1
	messageLabel.Position = UDim2.fromOffset(24, 30)
	messageLabel.Size = UDim2.new(1, -36, 0, 26)
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.Text = message
	messageLabel.TextColor3 = colors.TextDim
	messageLabel.TextSize = 12
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.ZIndex = 51
	messageLabel.Parent = notif
	table.insert(notificationStack, notif)
	shiftNotifications()
	task.delay(duration, function()
		local hideTween = tweenService:Create(
			notif,
			TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 20, notif.Position.Y.Scale, notif.Position.Y.Offset) }
		)
		hideTween:Play()
		hideTween.Completed:Connect(function()
			for index2, notif2 in ipairs(notificationStack) do
				if notif2 == notif then
					table.remove(notificationStack, index2)
					break
				end
			end
			notif:Destroy()
			shiftNotifications()
		end)
	end)
end

local uiScale = Instance.new("UIScale")
uiScale.Parent = mainFrame
local uiWidth, uiHeight =
	(
		(
			((bit32.bxor(62783, 434770) + 132989) + (bit32.bxor(5231, 3240) + 40815))
			+ ((52 * (("H"):byte()) + 259757) + (-171835 - 739896))
		)
		+ (
			((26 * (("c"):byte()) - 394683) + (-76574 + 806811))
			+ ((16 * (("L"):byte()) + 961620) + (11 * #"deWSWMpKHpDJEByIITjD" - 1248158))
		)
	),
	(
		(
			((57 * #"nmFeUpmEwREqHi" - 581942) + (58 * #"SJcNkzD" + 804122))
			+ ((909437 - 915130) + (47 * (("8"):byte()) - 69146))
		)
		+ (
			((1490418 - 666532) + (32 * (("9"):byte()) + 47712))
			+ ((1473889 - 763592) + (36 * (("8"):byte()) - 1736432))
		)
	)
local scaleFactor = 1
uiWidth, uiHeight = 320, 120

local function updateCameraScale()
	uiScale.Scale = scaleFactor
end

updateCameraScale()
workspace:GetPropertyChangedSignal(("Curre" .. "ntCamera")):Connect(function()
	updateCameraScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCameraScale)
	end

end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCameraScale)
end

local function removeCaptureUi()
	local coreGui = game:GetService("CoreGui")
	local starterGui = game:GetService("StarterGui")
	local guiNames = { "CaptureManager", "CaptureOverlay", "PlayerList" }
	for index2, guiName in ipairs(guiNames) do
		pcall(function()
			local instance = coreGui:FindFirstChild(guiName)
			if instance then
				instance:Destroy()
			end
		end)
	end
	pcall(function()
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
end

task.spawn(function()
	removeCaptureUi()
	while true do
		pcall(function()
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			local playerList = game:GetService("CoreGui"):FindFirstChild("PlayerList")
			if playerList then
				playerList:Destroy()
			end
		end)
		task.wait(0.3)
	end

end)
removeCaptureUi()

if not getgenv().TimeFarmed then
	getgenv().TimeFarmed = 0
end

local savedCarriedKills = getgenv().SavedCarriedKills or 0
local savedEmotes = getgenv().SavedEmotes or 0
local sessionStartTime = getgenv().SavedSessionStart or os.time()
local unusedHolder = nil
local carriedKills = 0
local killsPerHour = 0
local killsSinceLoad = 0
local totalKills = 0
local sessionKills = 0
local currentlyTargeting = false
local targetCFrame = nil
local currentTarget = nil
local isAttacking = false
local isUlted = false
local gKeyBusy = false
local ultKeyReady = false
local ultStartup = false
local isTeleporting = false
local teleportService = game:GetService("TeleportService")
local playersService2 = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local virtualInput = game:GetService("VirtualInputManager")
local localPlayer2 = playersService2.LocalPlayer
local leaderstats = localPlayer2:FindFirstChild("leaderstats") or localPlayer2

local function sendWebhook()
	local userName = localPlayer2 and localPlayer2.Name or "Unknown"
	local webhookKills = 0
	local webhookEmotes = savedEmotes
	local webhookTotalKills = 0
	local webhookKillPerHour = 0
	local timeText = timeFarmedLabel and timeFarmedLabel.Text
	local embed = {
		title = "Galaxy Hub Public Farm",
		color = 0,
		description = string.format(
			"**User:** ||%s||\n**Kills farmed:** %s\n**Emotes unlocked:** %s\n**Total kills:** %s\n**Kill / hr:** %s\n**Time farmed:** %s",
			userName,
			tostring(webhookKills),
			tostring(webhookEmotes),
			tostring(webhookTotalKills),
			tostring(webhookKillPerHour),
			timeText
		),
		timestamp = DateTime.now():ToIsoDate(),
	}
	local payload = {
		embeds = { embed },
	}
	local requestOk, requestError = pcall(function()
		return request({
			Url = farmSettings.webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = httpService:JSONEncode(payload),
		})
	end)
	if not requestOk then
		warn("Webhook request failed: " .. tostring(requestError))
	end
	return requestOk, requestError
end

testWebhookButton.MouseButton1Click:Connect(sendWebhook)
workspace.FallenPartsDestroyHeight = 0 / 0
local fallenPartsWatcher = workspace
	:GetPropertyChangedSignal(("Fa" .. "llenP" .. "artsDestroyHe" .. "ight"))
	:Connect(function()
		local currentValue = workspace.FallenPartsDestroyHeight
		if currentValue == currentValue then
			workspace.FallenPartsDestroyHeight = 0 / 0
		end
	end)
local killFloorPart = Instance.new("Part", workspace)
killFloorPart.CFrame = CFrame.new(0, -10008, 0)
killFloorPart.Anchored = true
killFloorPart.Size = Vector3.new(2048, 10, 2048)
killFloorPart.Transparency = 0.5
killFloorPart.CanCollide = true
killFloorPart.Name = game:GetService("HttpService"):GenerateGUID()
local lastHealth = 100
local healthChangedConn = nil
local renderSteppedConn = nil
local characterAddedConn = nil

local function onCharacterAdded(character)
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 3)
	if not humanoid or not rootPart then
		return
	end
	lastHealth = humanoid.Health
	if healthChangedConn then
		healthChangedConn:Disconnect()
		healthChangedConn = nil
	end
	if renderSteppedConn then
		renderSteppedConn:Disconnect()
		renderSteppedConn = nil
	end
	renderSteppedConn = runService.RenderStepped:Connect(function()
		local rootPart2 = character:FindFirstChild("HumanoidRootPart")
		if rootPart2 then
			lastHealth = humanoid.Health
			killFloorPart.CFrame = CFrame.new(rootPart2.Position.X, -10008, rootPart2.Position.Z)
		end
	end)
	healthChangedConn = humanoid.HealthChanged:Connect(function(newHealth)
		local rootPart2 = character:FindFirstChild("HumanoidRootPart")
		if newHealth <= 0 and rootPart2 and rootPart2.CFrame.Y <= 0 then
			humanoid.Health = lastHealth
		end
	end)
end

onCharacterAdded(localPlayer2.Character)
characterAddedConn = localPlayer2.CharacterAdded:Connect(function(newCharacter)
	task.wait(0.1)
	onCharacterAdded(newCharacter)
end)

local connections = {}
local ownedFolders = setmetatable({}, { __mode = "k" })

local function ensureMovingExclusion(character)
	if not character then
		return nil
	end
	local existingFolder = character:FindFirstChild("MovingExclusion")
	if existingFolder then
		return existingFolder
	end
	local folder = Instance.new("Folder")
	folder.Name = "MovingExclusion"
	pcall(function()
		folder:SetAttribute("galaxyOwned", true)
	end)
	folder.Parent = character
	ownedFolders[folder] = true
	return folder
end

local function hookMovingExclusion(character)
	if not character then
		return
	end
	ensureMovingExclusion(character)
	local childRemovedConn = character.ChildRemoved:Connect(function(child)
		if child.Name == "MovingExclusion" then
			task.defer(ensureMovingExclusion, character)
		end
	end)
	table.insert(connections, childRemovedConn)
end

hookMovingExclusion(localPlayer2.Character)
table.insert(
	connections,
	localPlayer2.CharacterAdded:Connect(function(newCharacter)
		task.wait(0.1)
		hookMovingExclusion(newCharacter)
	end)
)
local invisProcessing = false
local invisAnimation = nil
local lastInvisHumanoid = nil
local savedRootCFrame = nil

local invisConnections = {}
local invisModel = Instance.new("Model", workspace)
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
	local myChar = localPlayer2.Character
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
				workspace.CurrentCamera.CameraSubject = myHumanoid
			end)
		end
		pcall(function()
			myChar:SetAttribute("NoHeadLerp", false)
		end)
		for idx, val in pairs(invisConnections) do
			pcall(function()
				val:Disconnect()
			end)
		end
		invisConnections = {}
		for idx2, val2 in pairs(myChar:GetDescendants()) do
			if val2:IsA("BasePart") and val2.Name ~= "HumanoidRootPart" then
				val2.LocalTransparencyModifier = 0
			end
		end
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
	local transparencyConn = part:GetPropertyChangedSignal(("LocalTra" .. "nsparencyMo" .. "difier")):Connect(function()
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
	for index2, descendant in pairs(model:GetDescendants()) do
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
	local myChar = localPlayer2.Character
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
	local myChar2 = localPlayer2.Character
	if myChar2 then
		hookTransparencyHandlers(myChar2)
	end

end

local invisHeartbeat = runService.Heartbeat:Connect(function()
	if not farmEnabled then
		return
	end
	if isUlted or isTeleporting then
		getgenv().desync = nil
	end
	local desyncActive = getgenv().desync ~= nil
	if not invisActive and not desyncActive then
		return
	end
	if invisProcessing then
		return
	end
	invisProcessing = true
	local myChar = localPlayer2.Character
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
	local currentCamera = workspace.CurrentCamera
	local desyncCFrame = nil
	if invisActive then
		desyncCFrame = myRootCFrame
	end
	if desyncActive and not localPlayer2.Character:FindFirstChild("AbsoluteImmortal") then
		desyncCFrame = getgenv().desync.CFrame or desyncCFrame
	end
	local cameraSwapped = false
	if desyncCFrame then
		if currentCamera and not (invisActive and not desyncActive) then
			myChar:SetAttribute("NoHeadLerp", true)
			currentCamera.CameraSubject = invisHumanoid
			cameraSwapped = true
		end
		if currentlyTargeting and targetCFrame then
			invisPart.CFrame = targetCFrame
		else
			invisPart.CFrame = myRootCFrame
		end
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
		if currentlyTargeting and targetCFrame then
			myRootPart.CFrame = targetCFrame
		else
			if
				currentCamera
				and userInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
				and not desyncActive
				and not (invisActive and not desyncActive)
			then
				local value = currentCamera.CFrame.LookVector
				local var = Vector3.new(value.X, 0, value.Z)
				if var.Magnitude > 0.001 then
					myRootPart.CFrame = CFrame.new(myRootCFrame.Position, myRootCFrame.Position + var)
				else
					myRootPart.CFrame = myRootCFrame
				end
			else
				myRootPart.CFrame = myRootCFrame
			end
		end
	end
	myRootPart.Velocity = myVelocity
	invisProcessing = false
end)
enableInvis()
task.spawn(function()
	local function fn(arg)
		repeat
			task.wait()
		until (localPlayer2.Character == arg)
			and arg:FindFirstChild("HumanoidRootPart")
			and arg:FindFirstChildOfClass("Humanoid")
		if localPlayer2.Character ~= arg then
			return
		end
		local var = arg:FindFirstChild("HumanoidRootPart")
		task.spawn(function()
			while task.wait() and (not localPlayer2.Character or localPlayer2.Character == arg) do
				if getgenv().desync and not arg:FindFirstChild("AbsoluteImmortal") then
					local list = {}
					local afterimageOk, afterimageClone = pcall(function()
						return replicatedStorage.Resources.NinjaUlt.Afterimage_Despawn:Clone()
					end)
					local vanishingOk, vanishingClone = pcall(function()
						return replicatedStorage.Resources.VanishingKick.tpthing:Clone()
					end)
					if afterimageOk and afterimageClone then
						afterimageClone.Parent = var
						list[1] = afterimageClone
						for idx, val in pairs(afterimageClone:GetChildren()) do
							if val:IsA("ParticleEmitter") then
								val.Enabled = true
								val.Rate = 100
							end
						end
					end
					if vanishingOk and vanishingClone then
						vanishingClone.Parent = var
						list[2] = vanishingClone
						vanishingClone.Enabled = true
						vanishingClone.Rate = 100
					end
					repeat
						if list[1] and list[1].Parent then
							list[1].CFrame = var.CFrame
						end
						runService.RenderStepped:Wait()
					until not getgenv().desync or arg:FindFirstChild("AbsoluteImmortal")
					for idx, val in pairs(list) do
						pcall(function()
							val:Destroy()
						end)
					end
				end
			end
		end)
		task.spawn(function()
			for idx, val in pairs(arg:GetDescendants()) do
				if
					val:IsA("BasePart")
					and val ~= var
					and val.Transparency ~= 1
					and not val.Name:lower():find("hitbox")
				then
					task.spawn(function()
						while task.wait() and (not localPlayer2.Character or localPlayer2.Character == arg) do
							if
								val
								and (invisActive or (getgenv().desync and not arg:FindFirstChild("AbsoluteImmortal")))
							then
								val.Transparency = 0.5
								repeat
									runService.RenderStepped:Wait()
								until not invisActive
										and (not getgenv().desync or arg:FindFirstChild("AbsoluteImmortal"))
									or (localPlayer2.Character and localPlayer2.Character ~= arg)
								val.Transparency = 0
							end
						end
					end)
				end
			end
		end)
	end
	if localPlayer2.Character then
		task.spawn(fn, localPlayer2.Character)
	end
	localPlayer2.CharacterAdded:Connect(function(arg)
		task.spawn(fn, arg)
	end)
end)
local lightingService = game:GetService("Lighting")
local workspaceService = game:GetService("Workspace")
local terrain = Workspace:FindFirstChildOfClass("Terrain")

local visualOptimizerController

startVisualOptimizer = function()
	if visualOptimizerController and visualOptimizerController.running then
		return
	end

	local oldController = getgenv().__TSB_ULTRA_OPTIMIZER
	if type(oldController) == "table" and type(oldController.stop) == "function" then
		pcall(oldController.stop)
	end

	local controller = {
		running = true,
		connections = {},
	}
	visualOptimizerController = controller
	getgenv().__TSB_ULTRA_OPTIMIZER = controller

	local CONFIG = {
		deleteCharacterVfx = true,
		deleteTreesByShapeAndColor = true,
		deleteMapDecor = true,
		deleteTexturesAndMeshes = true,
		flattenRemainingMap = true,
		batchSize = 70,
		frameBudgetSeconds = 0.0015,
	}
	local removed = setmetatable({}, { __mode = "k" })
	local processed = setmetatable({}, { __mode = "k" })
	local queued = setmetatable({}, { __mode = "k" })
	local queue = {}
	local queueHead = 1
	local queueTail = 0
	local counters = { deleted = 0, flattened = 0, disabled = 0, processed = 0 }

	local PROTECTED_CLASSES = {
		Attachment = true,
		Motor6D = true,
		Motor = true,
		Weld = true,
		WeldConstraint = true,
		Bone = true,
		Animator = true,
		AnimationController = true,
		Humanoid = true,
		Camera = true,
		BoneAttachment = true,
	}
	local VFX_CLASSES = {
		ParticleEmitter = true,
		Trail = true,
		Beam = true,
		Smoke = true,
		Fire = true,
		Sparkles = true,
		Explosion = true,
		Highlight = true,
		PointLight = true,
		SpotLight = true,
		SurfaceLight = true,
		Decal = true,
		Texture = true,
		SurfaceAppearance = true,
		PostEffect = true,
		BloomEffect = true,
		BlurEffect = true,
		ColorCorrectionEffect = true,
		DepthOfFieldEffect = true,
		SunRaysEffect = true,
	}
	local NAME_KILL_WORDS = {
		"tree", "leaf", "leaves", "branch", "bush", "grass", "plant", "foliage",
		"trunk", "wood", "log", "palm", "shrub", "vine", "effect", "effects",
		"vfx", "fx", "particle", "particles", "trail", "beam", "smoke", "dust",
		"debris", "rubble", "shockwave", "slash", "impact", "explosion", "aura",
		"spark", "ring", "wind", "afterimage", "hitfx", "rock", "crate", "barrel",
		"bench", "chair", "table", "lamp", "sign", "fence", "prop", "decor",
		"decoration", "detail", "garbage", "trash",
	}
	local KEEP_WORDS = {
		"baseplate", "base", "floor", "ground", "road", "street", "sidewalk", "spawn",
		"arena", "platform", "plate", "safezone",
	}
	local CHARACTER_EFFECT_CONTAINER_WORDS = {
		"effect", "effects", "vfx", "fx", "particle", "particles", "trail", "beam",
		"aura", "afterimage", "hitfx", "shockwave", "slash", "impact", "explosion",
		"smoke", "dust", "debris", "rubble", "spark", "ring", "wind", "skill",
		"ult", "ultimate", "awaken", "transform", "summon",
	}
	local STREAK_UI_WORDS = { "streak", "killstreak", "crown" }

	local function connect(signal, handler)
		local ok, connection = pcall(function()
			return signal:Connect(handler)
		end)
		if ok and connection then
			table.insert(controller.connections, connection)
		end
		return connection
	end

	function controller.stop()
		if not controller.running then
			return
		end
		controller.running = false
		for _, connection in ipairs(controller.connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(controller.connections)
		table.clear(queue)
		if visualOptimizerController == controller then
			visualOptimizerController = nil
		end
		if getgenv().__TSB_ULTRA_OPTIMIZER == controller then
			getgenv().__TSB_ULTRA_OPTIMIZER = nil
		end
	end

	local function nameHas(instance, words)
		local name = string.lower(instance.Name)
		for _, word in ipairs(words) do
			if string.find(name, word, 1, true) then
				return true
			end
		end
		return false
	end

	local function isLocalCharacter(instance)
		local character = localPlayer2 and localPlayer2.Character
		return character ~= nil and (instance == character or instance:IsDescendantOf(character))
	end

	local function isUnderCamera(instance)
		local camera = workspaceService.CurrentCamera
		return camera ~= nil and instance:IsDescendantOf(camera)
	end

	local function characterOwner(instance)
		local ancestor = instance.Parent
		while ancestor do
			if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
				return playersService2:GetPlayerFromCharacter(ancestor), ancestor
			end
			ancestor = ancestor.Parent
		end
		return nil, nil
	end

	local function isPlayerOwned(instance)
		for _, player in ipairs(playersService2:GetPlayers()) do
			local character = player.Character
			if character and instance:IsDescendantOf(character) then
				return true
			end
			if instance:IsDescendantOf(player) then
				return true
			end
		end
		return false
	end

	local function isStreakUi(instance)
		if instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("ScreenGui") then
			return true
		end
		if instance:FindFirstAncestorWhichIsA("BillboardGui")
			or instance:FindFirstAncestorWhichIsA("SurfaceGui")
			or instance:FindFirstAncestorWhichIsA("ScreenGui") then
			return true
		end
		local ancestor = instance
		while ancestor do
			local ancestorName = string.lower(ancestor.Name)
			for _, word in ipairs(STREAK_UI_WORDS) do
				if string.find(ancestorName, word, 1, true) then
					return true
				end
			end
			ancestor = ancestor.Parent
		end
		return false
	end

	local function isCoreCharacterPart(instance)
		if PROTECTED_CLASSES[instance.ClassName] or isUnderCamera(instance) then
			return true
		end
		if isLocalCharacter(instance) or isStreakUi(instance) then
			return true
		end
		local _, character = characterOwner(instance)
		if not character then
			return false
		end
		if instance:IsA("BasePart") then
			return instance.Name == "HumanoidRootPart"
				or instance.Name == "Head"
				or instance.Name == "Torso"
				or instance.Name == "UpperTorso"
				or instance.Name == "LowerTorso"
				or string.find(instance.Name, "Arm", 1, true) ~= nil
				or string.find(instance.Name, "Leg", 1, true) ~= nil
				or string.find(instance.Name, "Hand", 1, true) ~= nil
				or string.find(instance.Name, "Foot", 1, true) ~= nil
		end
		return instance:IsA("Humanoid")
			or instance:IsA("Animator")
			or instance:IsA("Motor6D")
			or instance:IsA("Attachment")
	end

	local function safeDestroy(instance)
		if not instance or removed[instance] or instance == workspaceService.CurrentCamera then
			return false
		end
		if isLocalCharacter(instance) or isCoreCharacterPart(instance) then
			return false
		end
		removed[instance] = true
		local ok = pcall(function()
			instance:Destroy()
		end)
		if ok then
			counters.deleted += 1
		end
		return ok
	end

	local function disableAndDestroyVisual(instance)
		if isLocalCharacter(instance) or isStreakUi(instance) or not VFX_CLASSES[instance.ClassName] then
			return false
		end
		if isUnderCamera(instance) then
			pcall(function()
				if instance:IsA("Explosion") then
					instance.Visible = false
				else
					instance.Enabled = false
				end
			end)
			counters.disabled += 1
			return false
		end
		pcall(function()
			if instance:IsA("Explosion") then
				instance.Visible = false
			else
				instance.Enabled = false
			end
		end)
		counters.disabled += 1
		return safeDestroy(instance)
	end

	local function setIfDifferent(instance, property, value)
		pcall(function()
			if instance[property] ~= value then
				instance[property] = value
			end
		end)
	end

	local function colorBands(part)
		local color = part.Color
		local red = color.R * 255
		local green = color.G * 255
		local blue = color.B * 255
		local greenFoliage = green > red * 1.15 and green > blue * 1.15 and green > 35
		local brownWood = red > 55 and green > 18 and green < 115 and blue < 80 and red > blue * 1.4
		local darkPlant = green >= red and green >= blue and red < 80 and green < 130 and blue < 85
		return greenFoliage, brownWood, darkPlant
	end

	local function looksLikeTreePart(part)
		if not part:IsA("BasePart") or nameHas(part, KEEP_WORDS) then
			return false
		end
		local greenFoliage, brownWood, darkPlant = colorBands(part)
		local size = part.Size
		local highAboveGround = part.Position.Y > 2
		local chunkyCanopy = size.X >= 4 and size.Z >= 4 and size.Y >= 2
		local trunkShape = size.Y >= 4 and size.X <= 5 and size.Z <= 5
		local branchShape = size.Y <= 2 and math.max(size.X, size.Z) >= 4
		return CONFIG.deleteTreesByShapeAndColor
			and highAboveGround
			and (((greenFoliage or darkPlant) and chunkyCanopy) or (brownWood and (trunkShape or branchShape)))
	end

	local function shouldKeepMapPart(part)
		if part:IsA("SpawnLocation") or nameHas(part, KEEP_WORDS) then
			return true
		end
		local size = part.Size
		return (size.Y <= 3 and size.X >= 18 and size.Z >= 18)
			or (part.Position.Y <= 3 and size.X >= 8 and size.Z >= 8)
	end

	local function flattenMapPart(part)
		setIfDifferent(part, "Material", Enum.Material.SmoothPlastic)
		setIfDifferent(part, "Color", Color3.fromRGB(135, 135, 135))
		setIfDifferent(part, "Reflectance", 0)
		setIfDifferent(part, "CastShadow", false)
		counters.flattened += 1
	end

	local function stripMeshWeight(instance)
		if not CONFIG.deleteTexturesAndMeshes or isUnderCamera(instance) then
			return
		end
		if instance:IsA("SpecialMesh") then
			setIfDifferent(instance, "TextureId", "")
			setIfDifferent(instance, "VertexColor", Vector3.new(1, 1, 1))
			counters.disabled += 1
		elseif instance:IsA("MeshPart") then
			setIfDifferent(instance, "TextureID", "")
			setIfDifferent(instance, "RenderFidelity", Enum.RenderFidelity.Performance)
			setIfDifferent(instance, "Material", Enum.Material.SmoothPlastic)
			setIfDifferent(instance, "Color", Color3.fromRGB(135, 135, 135))
			setIfDifferent(instance, "CastShadow", false)
			counters.flattened += 1
		end
	end

	local function cleanLighting()
		setIfDifferent(lightingService, "GlobalShadows", false)
		setIfDifferent(lightingService, "EnvironmentDiffuseScale", 0)
		setIfDifferent(lightingService, "EnvironmentSpecularScale", 0)
		setIfDifferent(lightingService, "Brightness", 1)
		setIfDifferent(lightingService, "ClockTime", 14)
		setIfDifferent(lightingService, "FogStart", 100000)
		setIfDifferent(lightingService, "FogEnd", 100000)
		setIfDifferent(lightingService, "Ambient", Color3.fromRGB(180, 180, 180))
		setIfDifferent(lightingService, "OutdoorAmbient", Color3.fromRGB(180, 180, 180))
		for _, child in ipairs(lightingService:GetChildren()) do
			if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
				safeDestroy(child)
			else
				disableAndDestroyVisual(child)
			end
		end
	end

	local function cleanTerrain()
		if not terrain then
			return
		end
		setIfDifferent(terrain, "Decoration", false)
		setIfDifferent(terrain, "WaterReflectance", 0)
		setIfDifferent(terrain, "WaterTransparency", 1)
		setIfDifferent(terrain, "WaterWaveSize", 0)
		setIfDifferent(terrain, "WaterWaveSpeed", 0)
	end

	local function shouldDeleteContainer(instance)
		if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
			return false
		end
		if instance == workspaceService or instance == workspaceService.CurrentCamera
			or isUnderCamera(instance) or isPlayerOwned(instance) or isStreakUi(instance) then
			return false
		end
		return CONFIG.deleteMapDecor and nameHas(instance, NAME_KILL_WORDS)
	end

	local function cleanInstance(instance)
		if not instance or removed[instance] or processed[instance] or instance.Parent == nil then
			return
		end
		if isLocalCharacter(instance) then
			return
		end
		processed[instance] = true
		counters.processed += 1
		if isStreakUi(instance) then
			return
		end
		if isUnderCamera(instance) then
			disableAndDestroyVisual(instance)
			return
		end

		local _, character = characterOwner(instance)
		if character then
			if CONFIG.deleteCharacterVfx
				and (instance:IsA("Folder") or instance:IsA("Model"))
				and nameHas(instance, CHARACTER_EFFECT_CONTAINER_WORDS) then
				safeDestroy(instance)
				return
			end
			if CONFIG.deleteCharacterVfx and VFX_CLASSES[instance.ClassName] then
				disableAndDestroyVisual(instance)
				return
			end
			if instance:IsA("BasePart") then
				setIfDifferent(instance, "CastShadow", false)
			end
			return
		end

		if disableAndDestroyVisual(instance) then
			return
		end
		if shouldDeleteContainer(instance) then
			safeDestroy(instance)
			return
		end
		stripMeshWeight(instance)
		if instance:IsA("BasePart") then
			if looksLikeTreePart(instance) then
				safeDestroy(instance)
				return
			end
			if CONFIG.deleteMapDecor and nameHas(instance, NAME_KILL_WORDS) then
				safeDestroy(instance)
				return
			end
			if CONFIG.flattenRemainingMap then
				if shouldKeepMapPart(instance) then
					flattenMapPart(instance)
				else
					local size = instance.Size
					local smallOrVerticalProp = size.Y > 3 or math.max(size.X, size.Z) < 6
					if smallOrVerticalProp and not instance.CanCollide then
						safeDestroy(instance)
					else
						flattenMapPart(instance)
					end
				end
			end
		end
	end

	local function enqueue(instance)
		if not controller.running or not instance or queued[instance] or processed[instance] then
			return
		end
		if isLocalCharacter(instance) then
			return
		end
		queued[instance] = true
		queueTail += 1
		queue[queueTail] = instance
	end

	local function freeZoom()
		pcall(function()
			localPlayer2.CameraMaxZoomDistance = 400
			localPlayer2.CameraMinZoomDistance = 0.5
		end)
	end

	freeZoom()
	connect(runService.Heartbeat, freeZoom)
	cleanLighting()
	cleanTerrain()
	for _, instance in ipairs(workspaceService:GetChildren()) do
		if instance ~= workspaceService.CurrentCamera then
			enqueue(instance)
		end
	end
	connect(workspaceService.DescendantAdded, enqueue)
	connect(lightingService.DescendantAdded, function(instance)
		if instance:IsA("Sky") or instance:IsA("Atmosphere") or instance:IsA("Clouds") then
			safeDestroy(instance)
		else
			disableAndDestroyVisual(instance)
		end
	end)
	connect(playersService2.PlayerAdded, function(player)
		connect(player.CharacterAdded, enqueue)
	end)
	for _, player in ipairs(playersService2:GetPlayers()) do
		if player.Character and player ~= localPlayer2 then
			enqueue(player.Character)
		end
		connect(player.CharacterAdded, function(character)
			if player ~= localPlayer2 then
				enqueue(character)
			end
		end)
	end
	connect(runService.Heartbeat, function()
		if not controller.running then
			return
		end
		local startedAt = os.clock()
		local count = 0
		while queueHead <= queueTail and count < CONFIG.batchSize do
			local instance = queue[queueHead]
			queue[queueHead] = nil
			queueHead += 1
			queued[instance] = nil
			if instance and instance.Parent ~= nil then
				for _, child in ipairs(instance:GetChildren()) do
					enqueue(child)
				end
				cleanInstance(instance)
			end
			count += 1
			if os.clock() - startedAt >= CONFIG.frameBudgetSeconds then
				break
			end
		end
		if queueHead > queueTail then
			queueHead = 1
			queueTail = 0
		end
	end)
end

stopVisualOptimizer = function()
	if visualOptimizerController then
		visualOptimizerController.stop()
	end
end

setFarmState(farmEnabled)
local desyncActive = false

local function getCharacter(input)
	if typeof(input) == "Instance" then
		if input:IsA("Player") then
			return input.Character
		elseif input:IsA("Model") then
			return input
		end
	end
	return nil
end

local function getRootPart(model)
	return model and model:FindFirstChild(("HumanoidRoot" .. "Part")) or nil
end

local function getHumanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid") or nil
end

local function getOtherPlayers()
	local playersList = playersService2:GetPlayers()
	local selfIndex = table.find(playersList, localPlayer2)
	if selfIndex then
		table.remove(playersList, selfIndex)
	end
	return playersList
end

local function hasAnimation(humanoid, animIdPattern)
	if not humanoid then
		return false
	end
	for index2, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		if track.Animation.AnimationId:match(animIdPattern) then
			return true
		end
	end
	return false
end

local function findWeakestTarget()
	local weakestPlayer = nil
	local lowestHealth = math.huge
	for index2, player in ipairs(playersService2:GetPlayers()) do
		if player == localPlayer2 then
			continue
		end
		if player == currentTarget then
			continue
		end
		local char = player.Character
		if not char then
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then
			continue
		end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end
		if not humanoid.Health then
			continue
		end
		local torso = char:FindFirstChild("Torso")
		if not torso or torso.Transparency == 1 then
			continue
		end
		if hasAnimation(humanoid, "15128849047") then
			continue
		end
		if char:FindFirstChildWhichIsA("ForceField") then
			continue
		end
		if
			(
				char:GetAttribute("Ulted")
				and (char:GetAttribute("Character") == "Batter" or char:GetAttribute("Character") == "Bald")
			) or char:FindFirstChild("Counter")
		then
			continue
		end
		local rootPos = char.HumanoidRootPart.Position
		if not (rootPos.X >= -500 and rootPos.X <= 800 and rootPos.Z >= -600 and rootPos.Z <= 700) then
			continue
		end
		local health = humanoid.Health
		if health > 0 and health < lowestHealth then
			lowestHealth = health
			weakestPlayer = player
		end
	end
	return weakestPlayer
end

local function setupCharacterHandlers(character)
	local humanoid = character:WaitForChild("Humanoid")
	character.DescendantAdded:Connect(function(newDescendant)
		if newDescendant.Name == "Ragdoll" or newDescendant.Name == "RagdollSim" then
			if (not desyncActive) and humanoid.Health > 0 and not character:FindFirstChild("ExtraHitbox") then
				task.spawn(function()
					repeat
						desyncActive = true
						getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
						task.wait()
					until newDescendant.Parent ~= character or humanoid.Health <= 0
					desyncActive = false
					getgenv().desync = nil
				end)
			end
		end
	end)
	task.spawn(function()
		local playerGui = localPlayer2:WaitForChild("PlayerGui")
		if not playerGui then
			return
		end
		local hotbar = playerGui:WaitForChild("Hotbar")
		if not hotbar then
			return
		end
		local backpack = hotbar:WaitForChild("Backpack")
		if not backpack then
			return
		end
		local hotbarFrame = backpack:WaitForChild("Hotbar")
		if not hotbarFrame then
			return
		end
		local slotTwo = hotbarFrame:WaitForChild("2")
		if not slotTwo then
			return
		end
		local slotBase = slotTwo:WaitForChild("Base")
		if not slotBase then
			return
		end
		slotBase.ChildAdded:Connect(function(child)
			if child.Name == "Cooldown" and localPlayer2.Character:GetAttribute("Ulted") then
				task.spawn(function()
					ultStartup = true
					task.wait(0.05)
					ultStartup = false
				end)
			end
		end)
	end)
	local ultAnimIds = {
		["18464351556"] = true,
		["18464372850"] = true,
		["18464362124"] = true,
		["136370737633649"] = true,
	}
	humanoid.AnimationPlayed:Connect(function(track)
		local animId = track.Animation.AnimationId
		if ultAnimIds[animId:match("%d+")] then
			currentTarget = findWeakestTarget()
			return
		end
		local function isHunterClass(player)
			if not player or not player:IsA("Player") then
				return false
			end
			local char = getCharacter(player)
			local className = char and char:GetAttribute("Character")
			if type(className) ~= "string" then
				return false
			end
			className = className:lower()
			return className == "hunter" or className == "blade" or className:find("zombie", 1, true) ~= nil
		end
		local function freezeVelocityWhile(condition)
			local conn
			conn = runService.Heartbeat:Connect(function()
				if not condition() then
					conn:Disconnect()
					return
				end
				local myRoot = getRootPart(getCharacter(localPlayer2))
				if myRoot then
					myRoot.AssemblyLinearVelocity = Vector3.new()
					myRoot.AssemblyAngularVelocity = Vector3.new()
				end
			end)
			return conn
		end
		local ultHeartbeatConn = nil
		local ultRenderConn = nil
		local myRoot = nil
		local targetRoot = nil
		local ultFinished = false
		local ultOffsets = {
			CFrame.new(0, 0, 1.55),
			CFrame.new(0.85, 0.15, 1.35),
			CFrame.new(-0.85, 0.15, 1.35),
			CFrame.new(0, 0.85, 1.2),
			CFrame.new(0, -0.25, 1.15),
			CFrame.new(0.45, 0.05, 0.95),
			CFrame.new(-0.45, 0.05, 0.95),
		}
		local function getUltKillCFrame(targetRoot2)
			local offsetIndex = (math.floor(tick() * 160) % #ultOffsets) + 1
			return targetRoot2.CFrame * ultOffsets[offsetIndex]
		end
		local function detachPhysics()
			if ultHeartbeatConn then
				ultHeartbeatConn:Disconnect()
				ultHeartbeatConn = nil
			end
			if ultRenderConn then
				ultRenderConn:Disconnect()
				ultRenderConn = nil
			end
			if sethiddenproperty then
				if myRoot and myRoot.Parent then
					pcall(function()
						sethiddenproperty(myRoot, "PhysicsRepRootPart", nil)
					end)
				end
				if targetRoot and targetRoot.Parent then
					pcall(function()
						sethiddenproperty(targetRoot, "PhysicsRepRootPart", nil)
					end)
				end
			end
			if myRoot and myRoot.Parent then
				myRoot.CFrame = CFrame.new(myRoot.Position)
				myRoot.AssemblyLinearVelocity = Vector3.zero
				myRoot.AssemblyAngularVelocity = Vector3.zero
				pcall(function()
					myRoot.Velocity = Vector3.zero
				end)
				pcall(function()
					myRoot.RotVelocity = Vector3.zero
				end)
				local myHumanoid = myRoot.Parent:FindFirstChildOfClass("Humanoid")
				if myHumanoid then
					pcall(function()
						myHumanoid.AutoRotate = true
					end)
				end
			end
			myRoot = nil
			targetRoot = nil
		end
		local function detachPhysicsAll()
			detachPhysics()
		end
		local function attachPhysicsTo(myRoot2, targetRoot2)
			if ultFinished then
				return
			end
			if ultHeartbeatConn then
				ultHeartbeatConn:Disconnect()
				ultHeartbeatConn = nil
			end
			if myRoot and myRoot.Parent then
				myRoot.AssemblyLinearVelocity = Vector3.zero
				myRoot.AssemblyAngularVelocity = Vector3.zero
				pcall(function()
					myRoot.Velocity = Vector3.zero
				end)
				pcall(function()
					myRoot.RotVelocity = Vector3.zero
				end)
			end
			if not myRoot2 or not targetRoot2 then
				return
			end
			myRoot = myRoot2
			targetRoot = targetRoot2
			if ultRenderConn then
				ultRenderConn:Disconnect()
				ultRenderConn = nil
			end
			local myHumanoid = myRoot2.Parent and myRoot2.Parent:FindFirstChildOfClass("Humanoid")
			local targetHumanoid = targetRoot2.Parent and targetRoot2.Parent:FindFirstChildOfClass("Humanoid")
			if myHumanoid then
				pcall(function()
					myHumanoid.AutoRotate = false
				end)
			end
			if targetHumanoid then
				ultRenderConn = runService.RenderStepped:Connect(function()
					if targetHumanoid and targetHumanoid.Parent then
						pcall(function()
							targetHumanoid.AutoRotate = false
						end)
					end
				end)
			end
			myRoot2.CFrame = getUltKillCFrame(targetRoot2)
			myRoot2.AssemblyLinearVelocity = Vector3.zero
			myRoot2.AssemblyAngularVelocity = Vector3.zero
			if sethiddenproperty then
				pcall(function()
					sethiddenproperty(myRoot2, "PhysicsRepRootPart", myRoot2)
				end)
				pcall(function()
					sethiddenproperty(myRoot2, "PhysicsRepRootPart", targetRoot2)
				end)
			end
			local heartbeatConn
			heartbeatConn = runService.Heartbeat:Connect(function()
				if not myRoot2 or not myRoot2.Parent
 or not targetRoot2 or not targetRoot2.Parent then
					heartbeatConn:Disconnect()
					if ultHeartbeatConn == heartbeatConn then
						ultHeartbeatConn = nil
					end
					if sethiddenproperty then
						if myRoot2 and myRoot2.Parent then
							pcall(function()
								sethiddenproperty(myRoot2, "PhysicsRepRootPart", nil)
							end)
						end
						if targetRoot2 and targetRoot2.Parent then
							pcall(function()
								sethiddenproperty(targetRoot2, "PhysicsRepRootPart", nil)
							end)
						end
					end
					if myRoot2 and myRoot2.Parent then
						myRoot2.AssemblyLinearVelocity = Vector3.zero
						myRoot2.AssemblyAngularVelocity = Vector3.zero
						pcall(function()
							myRoot2.Velocity = Vector3.zero
						end)
						pcall(function()
							myRoot2.RotVelocity = Vector3.zero
						end)
					end
					return
				end
				myRoot2.CFrame = getUltKillCFrame(targetRoot2)
				myRoot2.AssemblyLinearVelocity = Vector3.zero
				myRoot2.AssemblyAngularVelocity = Vector3.zero
				pcall(function()
					myRoot2.Velocity = Vector3.zero
				end)
				pcall(function()
					myRoot2.RotVelocity = Vector3.zero
				end)
				if sethiddenproperty then
					pcall(function()
						sethiddenproperty(myRoot2, "PhysicsRepRootPart", targetRoot2)
					end)
				end
			end)
			ultHeartbeatConn = heartbeatConn
		end
		if animId:match("18896229321") then
			task.wait(0.01)
			if not ultStartup then
				return
			end
			ultFinished = false
			getgenv().desync = nil
			isTeleporting = true
			task.spawn(function()
				local myChar = getCharacter(localPlayer2)
				if not myChar then
					return
				end
				if myChar:GetAttribute("Character") ~= "Purple" then
					return
				end
				local ultDeadline = tick() + 5.25
				local ultActive = true
				local ultStart = tick()
				local animDuration = 70
				local animFps = 30
				local TARGET_HOLD_TIME = 0.16
				local TARGET_RETRY_TIME = 0.42
				local CAST_FAILSAFE_TIME = 3.8
				local function extractAnimId(animationId)
					return animationId:match("%d+")
				end
				local function findUltTrack()
					for index2, track2 in ipairs(localPlayer2.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
						if extractAnimId(track2.Animation.AnimationId) == "18896229321" then
							return track2
						end
					end
					return nil
				end
				local ultTrack = findUltTrack()
				while not ultTrack do
					task.wait()
					ultTrack = findUltTrack()
				end
				task.spawn(function()
					repeat
						task.wait()
						ultTrack = findUltTrack()
					until not ultTrack
						or (ultTrack.TimePosition >= animDuration / animFps)
						or (tick() >= ultStart + CAST_FAILSAFE_TIME)
					ultFinished = true
					local myChar2 = getCharacter(localPlayer2)
					if not myChar2 then
						return
					end
					pcall(function()
						localPlayer2.Character.HumanoidRootPart.CFrame = CFrame.new(150, 441, 32)
					end)
					ultKeyReady = true
					pcall(function()
						localPlayer2.Character.HumanoidRootPart.CFrame = CFrame.new(0, -29000, 0)
					end)
					task.wait(1.5)
					pcall(function()
						localPlayer2.Character.HumanoidRootPart.CFrame = CFrame.new(150, 441, 32)
					end)
					isTeleporting = false
					task.wait(5)
					pcall(function()
						localPlayer2.Character.HumanoidRootPart.CFrame = CFrame.new(-42, 1855, 25227)
					end)
				end)
				local freezeConn = freezeVelocityWhile(function()
					return ultActive
				end)
				local doneTargets = {}
				local currentTarget2 = nil
				local targetSince = tick()
				local savedMyCFrame = nil
				do
					local myChar2 = getCharacter(localPlayer2)
					local myRoot2 = myChar2 and getRootPart(myChar2)
					if myRoot2 then
						savedMyCFrame = myRoot2.CFrame
					end
				end
				local function resolveCharacter(input)
					if not input then
						return nil
					end
					if input:IsA("Player") then
						return getCharacter(input)
					end
					if input:IsA("Model") then
						return input
					end
					return nil
				end
				local function getHumanoidOf(input)
					return getHumanoid(resolveCharacter(input))
				end
				local function getRootOf(input)
					return getRootPart(resolveCharacter(input))
				end
				local function isInvulnerable(char)
					if not char then
						return false
					end
					if char:FindFirstChild("ForceField") then
						return true
					end
					if char:FindFirstChild("AbsoluteImmortal") then
						return true
					end
					if char:FindFirstChild("BeingGrabbed") then
						return true
					end
					if char:FindFirstChild("HunterCounter") then
						return true
					end
					if char:FindFirstChild("AtomicCounter") then
						return true
					end
					if char:FindFirstChild("forcefield") then
						return true
					end
					return false
				end
				local function isTargetInvalid(target)
					local targetChar = resolveCharacter(target)
					local targetHumanoid = targetChar and getHumanoid(targetChar)
					local targetRoot2 = targetChar and getRootPart(targetChar)
					if not targetChar or not targetHumanoid or not targetRoot2 then
						return true
					end
					if targetHumanoid.Health <= 0 then
						return true
					end
					if target:IsA("Player") then
						if isInvulnerable(targetChar) then
							return true
						end
						if targetChar:FindFirstChild("Counter") then
							return true
						end
						if hasAnimation(targetHumanoid, "15128849047") then
							return true
						end
						if targetChar:GetAttribute("Ulted") and targetChar:GetAttribute("Character") == "Batter" then
							return true
						end
					end
					local targetRootPos = targetChar.HumanoidRootPart.Position
					if
						not (
							targetRootPos.X >= -500
							and targetRootPos.X <= 800
							and targetRootPos.Z >= -600
							and targetRootPos.Z <= 700
						)
					then
						return true
					end
					return false
				end
				local function isCounteringTarget(target)
					local targetHumanoid = getHumanoidOf(target)
					return targetHumanoid
						and (
							hasAnimation(targetHumanoid, "18896222853")
							or hasAnimation(targetHumanoid, "137434257516014")
						)
				end
				local function hasCounter(player)
					if not player or not player:IsA("Player") then
						return false
					end
					local char = getCharacter(player)
					local humanoid2 = char and getHumanoid(char)
					if not char or not humanoid2 then
						return false
					end
					if humanoid2.Health <= 0 then
						return false
					end
					if hasAnimation(humanoid2, "15128849047") then
						return false
					end
					return isInvulnerable(char)
				end
				local function findWeakestDummy()
					local dummy = workspace.Live:FindFirstChild("Weakest Dummy")
					if not dummy then
						return nil
					end
					local dummyHumanoid = getHumanoid(dummy)
					if not dummyHumanoid or dummyHumanoid.Health <= 0 then
						return nil
					end
					return dummy
				end
				local function findNextTarget(excludedTarget)
					local hunterTargets = {}
					local otherTargets = {}
					local function addTarget(target, bucket)
						local humanoid2 = getHumanoidOf(target)
						local root2 = getRootOf(target)
						if not humanoid2 or not root2 then
							return
						end
						if doneTargets[target] and tick() - doneTargets[target] < TARGET_RETRY_TIME then
							return
						end
						doneTargets[target] = nil
						local myRoot2 = getRootPart(getCharacter(localPlayer2))
						local distance = myRoot2 and (myRoot2.Position - root2.Position).Magnitude or 0
						table.insert(bucket, {
							target = target,
							score = humanoid2.Health + (distance * 0.01),
						})
					end
					if currentTarget and currentTarget ~= excludedTarget then
						local root = getRootOf(currentTarget)
						if not isTargetInvalid(currentTarget) and not isCounteringTarget(currentTarget) and root then
							addTarget(currentTarget, isHunterClass(currentTarget) and hunterTargets or otherTargets)
						end
					end
					for index2, player in pairs(getOtherPlayers()) do
						if player == excludedTarget then
							continue
						end
						local root = getRootOf(player)
						if not isTargetInvalid(player) and not isCounteringTarget(player) and root then
							if isHunterClass(player) then
								addTarget(player, hunterTargets)
							else
								addTarget(player, otherTargets)
							end
						end
					end
					if #hunterTargets > 0 then
						table.sort(hunterTargets, function(left, right)
							return left.score < right.score
						end)
						return hunterTargets[1].target
					end
					if #otherTargets > 0 then
						table.sort(otherTargets, function(left, right)
							return left.score < right.score
						end)
						return otherTargets[1].target
					end
					local dummy = findWeakestDummy()
					if dummy and dummy ~= excludedTarget then
						if doneTargets[dummy] and tick() - doneTargets[dummy] < TARGET_RETRY_TIME then
							return nil
						end
						doneTargets[dummy] = nil
						return dummy
					end
					return nil
				end
				local function restoreMyPosition()
					if not savedMyCFrame then
						return
					end
					local myChar2 = getCharacter(localPlayer2)
					local myRoot2 = myChar2 and getRootPart(myChar2)
					if myRoot2 then
						pcall(function()
							myRoot2.CFrame = savedMyCFrame
						end)
					end
				end
				local function restoreAutoRotate()
					local myChar2 = getCharacter(localPlayer2)
					local myHumanoid = myChar2 and getHumanoid(myChar2)
					if myHumanoid then
						pcall(function()
							myHumanoid.AutoRotate = true
						end)
					end
				end
				local function anyCounteringPlayer()
					for index2, player in pairs(getOtherPlayers()) do
						if doneTargets[player] then
							continue
						end
						if hasCounter(player) then
							return true
						end
					end
					return false
				end
				local cleanedUp = false
				local function endUlt()
					if cleanedUp then
						return
					end
					cleanedUp = true
					detachPhysics()
					restoreAutoRotate()
					if _ffWatchConn then
						pcall(function()
							_ffWatchConn:Disconnect()
						end)
					end
					if _dummyRespawnConn then
						pcall(function()
							_dummyRespawnConn:Disconnect()
						end)
					end
					if _currentTargetAnimConn then
						pcall(function()
							_currentTargetAnimConn:Disconnect()
						end)
						_currentTargetAnimConn = nil
					end
					ultActive = false
					detachPhysicsAll()
				end
				local targetAnimConn = nil
				local function setTarget(target)
					if targetAnimConn then
						pcall(function()
							targetAnimConn:Disconnect()
						end)
						targetAnimConn = nil
					end
					detachPhysics()
					currentTarget2 = target
					targetSince = tick()
					if target then
						local myChar2 = getCharacter(localPlayer2)
						local myRoot2 = myChar2 and getRootPart(myChar2)
						local targetRoot2 = getRootOf(target)
						if myRoot2 and targetRoot2 then
							attachPhysicsTo(myRoot2, targetRoot2)
							local targetHumanoid = getHumanoidOf(target)
							if targetHumanoid then
								local targetAnimator = targetHumanoid:FindFirstChildOfClass("Animator")
								local animPlayedSignal = targetAnimator and targetAnimator.AnimationPlayed
									or targetHumanoid.AnimationPlayed
								targetAnimConn = animPlayedSignal:Connect(function(track2)
									local animId2 = track2.Animation.AnimationId
									if animId2:match("18896222853") or animId2:match("137434257516014") then
										if not ultActive then
											return
										end
										local currentVictim = currentTarget2
										if not currentVictim then
											return
										end
										doneTargets[currentVictim] = tick()
										detachPhysics()
										local nextTarget = findNextTarget(currentVictim)
										if nextTarget then
											setTarget(nextTarget)
										else
											if anyCounteringPlayer() then
												detachPhysics()
												currentTarget2 = nil
											else
												detachPhysics()
												currentTarget2 = nil
											end
										end
									end
								end)
							end
						end
					end
				end
				local dummyAddedConn = workspace.Live.ChildAdded:Connect(function(newChild)
					if newChild.Name == "Weakest Dummy" then
						doneTargets[newChild] = nil
					end
				end)
				local respawnScanConn = runService.RenderStepped:Connect(function()
					for index2, player in pairs(getOtherPlayers()) do
						if not doneTargets[player] then
							continue
						end
						local char = getCharacter(player)
						local humanoid2 = char and getHumanoid(char)
						if char and humanoid2 and humanoid2.Health > 0 and not isInvulnerable(char) then
							doneTargets[player] = nil
							if not currentTarget2 then
								setTarget(player)
							end
						end
					end
				end)
				local ultEnded = false
				local firstTarget = findNextTarget(nil)
				if firstTarget then
					setTarget(firstTarget)
				end
				while track.IsPlaying and tick() < ultDeadline do
					if ultFinished then
						ultEnded = true
						endUlt()
						break
					end
					runService.Heartbeat:Wait()
					local now = tick()
					local needRetarget = false
					if not currentTarget2 then
						needRetarget = true
					else
						if isTargetInvalid(currentTarget2) then
							if not hasCounter(currentTarget2) then
								doneTargets[currentTarget2] = tick()
							end
							needRetarget = true
						elseif now - targetSince >= TARGET_HOLD_TIME then
							doneTargets[currentTarget2] = tick()
							needRetarget = true
						end
					end
					if needRetarget then
						local nextTarget = findNextTarget(currentTarget2)
						if not nextTarget then
							if anyCounteringPlayer() then
								detachPhysics()
								currentTarget2 = nil
							else
								detachPhysics()
								currentTarget2 = nil
							end
						else
							setTarget(nextTarget)
						end
					end
				end
				endUlt()
			end)
		end
	end)
end

task.spawn(function()
	local totalKillsVal = leaderstats:WaitForChild("Total Kills")
	local lastEmoteSpin = localPlayer2:GetAttribute("LastEmoteSpin")
	local initialTotalKills = totalKillsVal.Value
	killsSinceLoad = totalKillsVal.Value - savedCarriedKills
	while true do
		task.wait(0.25)
		totalKills = totalKillsVal.Value
		sessionKills = totalKills - initialTotalKills
		carriedKills = math.max(sessionKills, 0)
		local emoteSpinVal = localPlayer2:GetAttribute("LastEmoteSpin")
		if emoteSpinVal ~= lastEmoteSpin then
			savedEmotes = savedEmotes + 1
			lastEmoteSpin = emoteSpinVal
		end
		local elapsedHours = math.max(os.time() - sessionStartTime, 1) / 3600
		killsPerHour = math.floor(carriedKills / elapsedHours)
		killsValueLabel.Text = tostring(carriedKills)
		killsPerHourValueLabel.Text = tostring(killsPerHour)
		emotesValueLabel.Text = tostring(savedEmotes)
		totalValueLabel.Text = tostring(totalKills)
	end

end)
task.spawn(function()
	while true do
		if farmEnabled then
			getgenv().TimeFarmed += 1
		end
		local timeFarmed = getgenv().TimeFarmed
		local hours = math.floor(timeFarmed / 3600)
		local minutes = math.floor((timeFarmed % 3600) / 60)
		local seconds = timeFarmed % 60
		timeFarmedLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
		task.wait(1)
	end

end)
localPlayer2.CharacterAdded:Connect(setupCharacterHandlers)

if localPlayer2.Character then
	setupCharacterHandlers(localPlayer2.Character)
end

local serverQuery = {
	{
		QueryV2 = true,
		Page = 1,
		Filters = {
			Countries = {
				[farmSettings.country] = true,
			},
			Tags = {},
			HideFull = true,
			HideTagged = false,
			FriendsOnly = false,
			HidePassword = false,
		},
		limit = 60,
		Category = "Server List",
		Region = farmSettings.country,
		Sort = {
			Keys = {
				{
					By = "kills",
					Dir = "low",
				},
			},
		},
		Search = "",
		notFull = false,
	},
}



local function pickServer(serverData)
	local candidateIds = {}
	for idx, val in ipairs(serverData.servers) do
		local playerCount = val.players
		if playerCount and playerCount >= 10 and playerCount <= 13 and val.id ~= game.JobId then
			table.insert(candidateIds, val.id)
		end
	end
	if #candidateIds == 0 then
		return nil
	end
	local randomIndex = math.random(1, #candidateIds)
	return candidateIds[randomIndex]
end

local isHopping = false
local forceHop = false

function hopServer()
	if (not forceHop) and not farmEnabled then
		return
	end
	if isHopping then
		return
	end
	isHopping = true
	repeat
		task.wait()
	until (not isUlted) and not isTeleporting
	queueTeleportScript()
	task.spawn(function()
		while true do
			local serverList = game:GetService("ReplicatedStorage")
				:WaitForChild("Ranked")
				:WaitForChild("GetServerBrowserData")
				:InvokeServer(jsonEncode(serverQuery))
			local serverId = pickServer(serverList)
			if serverId then
				local teleportOk, teleportErr = pcall(function()
					teleportService:TeleportToPlaceInstance(game.PlaceId, serverId, localPlayer2)
				end)
				if not teleportOk then
					task.wait(2)
				else
					task.wait(5)
				end
			else
				task.wait(3)
			end
		end
	end)
end

hopServerButton.MouseButton1Click:Connect(function()
	warn("[Galaxy] Hop server manually...")
	forceHop = true
	hopServer()
end)

local blacklistIds = {
	422755031,
	198131804,
	681405668,
	3414432341,
	339633571,
	430966809,
	2039323684,
	117723419,
	1015595932,
	263944298,
	112905203,
	2284964418,
	1266437961,
	3120648134,
	1148139861,
	1633233654,
	3350014406,
	971193650,
	661273560,
	66105529,
	77342385,
	167343092,
	2055306963,
	141984224,
	438917845,
	1391134999,
	1796550069,
	255671730,
	3162123826,
	1059541187,
	1259898795,
	31070091,
	1041867508,
	994994173,
	1446694201,
	77525605,
	1001242712,
	2533866869,
	4983064295,
}

local function checkPlayerThreat(player)
	if player == localPlayer2 then
		return
	end
	local displayName = player.DisplayName
	local nameTag = displayName .. "(@" .. player.Name .. ")"
	local staffGroups = { "Staff", "Special People", "Friends with Staff" }
	local groupOk, isInGroup = pcall(function()
		return player:IsInGroup(
			(
				(
					((54 * (("g"):byte()) - 738396) + (22 * (("F"):byte()) + 1425080))
					+ ((442333 + 196920) + (-960142 + 442234))
				)
				+ (
					((35 * (("7"):byte()) - 622316) + (math.floor(1327254.6450)))
					+ ((97588 - 410936) + (math.ceil(10804360.3480)))
				)
			)
		)
	end)
	if groupOk and isInGroup then
		local roleOk, role = pcall(function()
			return player:GetRoleInGroup(
				(
					(
						((43 * #"VSSHreQRSqCgXAkiHpTecdffyl" - 392660) + (math.ceil(875422.2910)))
						+ ((42 * (("v"):byte()) + 810279) + (-653216 + 71653))
					)
					+ (
						((math.ceil(616649.5980)) + (443906 - 866208))
						+ ((48 * (("s"):byte()) - 400009) + (12242558 - 746963))
					)
				)
			)
		end)
		local isStaff = false
		local roleText = (roleOk and role) and role or "?"
		if roleOk and role then
			local roleLower = role:lower()
			isStaff = roleLower:find("moderator")
				or roleLower:find("developer")
				or roleLower:find("contributor")
				or roleLower:find("tester")
				or roleLower:find("owner")
				or roleLower:find("anomaly player")
		end
		if isStaff then
			setFarmState(false)
			forceHop = true
			hopServer()
			return
		end
	end
	for index2, blacklistId in ipairs(blacklistIds) do
		if player.UserId == blacklistId then
			setFarmState(false)
			forceHop = true
			hopServer()
			return
		end
	end
	local friendNames = {}
	for index3, friendId in ipairs(blacklistIds) do
		local friendsOk, isFriend = pcall(function()
			return player:IsFriendsWith(friendId)
		end)
		if friendsOk and isFriend then
			local nameOk, friendName = pcall(function()
				return playersService2:GetNameFromUserIdAsync(friendId)
			end)
			if nameOk then
				local displayName2 = friendName
				pcall(function()
					local userInfos = game:GetService("UserService"):GetUserInfosByUserIdsAsync({ friendId })
					if userInfos and userInfos[1] then
						displayName2 = userInfos[1].DisplayName
					end
				end)
				friendNames[#friendNames + 1] = displayName2 .. "(@" .. friendName .. ")"
			end
		end
	end
	if #friendNames > 0 then
		setFarmState(false)
		forceHop = true
		hopServer()
		return
	end
	local leaderstats2 = player:FindFirstChild("leaderstats")
	local totalKillsVal = nil
	if leaderstats2 then
		totalKillsVal = leaderstats2:FindFirstChild("Total Kills")
	else
		totalKillsVal = player:FindFirstChild("Total Kills")
	end
	if totalKillsVal and totalKillsVal.Value >= 10000 then
		hopServer()
		return true
	end
	if not totalKillsVal then
		local leaderstatsConn
		leaderstatsConn = player.ChildAdded:Connect(function(leaderstatsInstance)
			if leaderstatsInstance.Name == "leaderstats" then
				leaderstatsConn:Disconnect()
				local killsConn
				killsConn = leaderstatsInstance.ChildAdded:Connect(function(killsValue)
					if killsValue.Name == "Total Kills" then
						killsConn:Disconnect()
						if killsValue.Value >= 10000 then
							hopServer()
							return
						end
						local killsChangedConn
						killsChangedConn = killsValue:GetPropertyChangedSignal("Value"):Connect(function()
							if killsValue.Value >= 10000 then
								killsChangedConn:Disconnect()
								hopServer()
							end
						end)
					end
				end)
			end
		end)
		return
	end
	local killsChangedConn
	killsChangedConn = totalKillsVal:GetPropertyChangedSignal("Value"):Connect(function()
		if totalKillsVal.Value >= 10000 then
			killsChangedConn:Disconnect()
			hopServer()
		end
	end)
end

local playerAddedConn = playersService2.PlayerAdded:Connect(function(player)
	task.spawn(pcall, checkPlayerThreat, player)
end)

for index2, player in pairs(playersService2:GetPlayers()) do
	if player ~= localPlayer2 then
		task.spawn(pcall, checkPlayerThreat, player)
	end

end

local unusedFlag2 = true
deathCounterConns = {}
deathCounterDebounce = {}
hookedChars = {}
local watchPlayerCounters
local watchPlayerCombat
local combatConns
local counterHooks
local isReviving = false

local function getReviveTime()
	return 0
end

local function isCounterAccessory(instance)
	return instance:IsA("Accessory") and instance.Name == "Counter"
end

local counterHookEnabled = false
local reviveAnimConn = nil
local charAddedConn = nil

local function setRootCFrame(cframe)
	local value = localPlayer2.Character
	local rootPart = value and value:FindFirstChild("HumanoidRootPart")
	if not (value and rootPart) then
		return
	end
	task.spawn(function()
		runService.RenderStepped:Once(function()
			rootPart.Velocity = Vector3.new()
			runService.Heartbeat:Wait()
			rootPart.Velocity = Vector3.new()
		end)
		runService.Heartbeat:Once(function()
			rootPart.CFrame = cframe
		end)
	end)
end

local function resetCamera()
	local myChar = localPlayer2.Character
	local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
	if myChar and myHumanoid and workspace.CurrentCamera then
		local camCFrame = workspace.CurrentCamera.CFrame
		workspace.CurrentCamera:Destroy()
		local newCamera = Instance.new("Camera", workspace)
		newCamera.CameraType = Enum.CameraType.Custom
		newCamera.CameraSubject = myHumanoid
		newCamera.CFrame = camCFrame
		localPlayer2.CameraMode = Enum.CameraMode.Classic
		local head = myChar:FindFirstChild("Head")
		if head then
			head.Anchored = false
		end
	end

end

local function getDisplayName(player2)
	local displayOk, displayName = pcall(function()
		return player2.DisplayName
	end)
	if not displayOk or not displayName or displayName == "" then
		return player2.Name
	end
	for index3, otherPlayer in pairs(playersService2:GetPlayers()) do
		if otherPlayer ~= player2 and otherPlayer.DisplayName == displayName then
			return player2.Name
		end
	end
	return displayName
end

local function watchReviveAnim(humanoid)
	if reviveAnimConn then
		reviveAnimConn:Disconnect()
		reviveAnimConn = nil
	end
	if not humanoid then
		return
	end
	reviveAnimConn = humanoid.AnimationPlayed:Connect(function(track)
		if not track.Animation.AnimationId:match("11343250001") then
			return
		end
		isReviving = true
		task.spawn(function()
			task.wait(0.2)
			local reviveTime = getReviveTime()
			local stopped = reviveTime <= 0
			if reviveTime <= 0 then
				pcall(function()
					track:Stop()
				end)
			end
			task.spawn(resetCamera)
			local myChar = localPlayer2.Character
			myChar:WaitForChild("AbsoluteImmortal", 1)
			local myRoot = myChar:FindFirstChild("HumanoidRootPart")
			local savedCFrame = myRoot.CFrame
			local counterPlayer = nil
			for index3, player2 in pairs(playersService2:GetPlayers()) do
				if player2 ~= localPlayer2 then
					local char = player2.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					local humanoid2 = char and char:FindFirstChildOfClass("Humanoid")
					if char and root and humanoid2 then
						for index4, track2 in pairs(humanoid2:GetPlayingAnimationTracks()) do
							if
								track2.Animation.AnimationId:match("11343318134")
								and (myRoot.Position - root.Position).Magnitude <= 15
							then
								counterPlayer = player2
							end
						end
					end
				end
			end
			local counterHumanoid = nil
			local counterName = nil
			if counterPlayer then
				local counterChar = counterPlayer.Character
				counterHumanoid = counterChar and counterChar:FindFirstChildOfClass("Humanoid")
				counterName = getDisplayName(counterPlayer)
			else
				local dummyModel = Instance.new("Model")
				local dummyHumanoid = Instance.new("Humanoid", dummyModel)
				dummyHumanoid.Health = 100
				counterHumanoid = dummyHumanoid
				counterName = nil
				task.delay(
					reviveTime
						+ (
							(
								((358704 - 805113) + (math.ceil(15935.2020)))
								+ ((51 * (("L"):byte()) - 415533) + (1975737 - 951120))
							)
							+ (
								((44 * (("Y"):byte()) + 372062) + (math.floor(497613.2920)))
								+ ((1 * #"ygCJhavjXVJopLxpb" - 239896) + (-224387 - 591810))
							)
						),
					function()
						dummyHumanoid.Health = 0
					end
				)
			end
			if reviveTime > 0 then
				task.wait(reviveTime)
				myChar = localPlayer2.Character
				myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if not (myChar and myRoot) then
					return
				end
			end
			local oldSubject = workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject
			if workspace.CurrentCamera then
				workspace.CurrentCamera.CameraSubject = nil
			end
			local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
			local sinkCFrame = CFrame.new(0, -10000, 0) * CFrame.Angles(math.rad(90), 0, 0)
			local startTick = tick()
			repeat
				setRootCFrame(sinkCFrame)
				if reviveTime > 0 and not stopped then
					stopped = true
					pcall(function()
						track:Stop()
					end)
				end
				runService.RenderStepped:Wait()
			until (counterHumanoid and counterHumanoid.Health <= 0)
				or (myHumanoid and myHumanoid.Health <= 0)
				or tick() >= startTick + 10
			if workspace.CurrentCamera then
				workspace.CurrentCamera.CameraSubject = oldSubject
			end
			setRootCFrame(savedCFrame)
			task.wait(1)
			local myChar2 = localPlayer2.Character
			if myChar2 then
				local freeze = myChar2:FindFirstChild("Freeze")
				local noRotate = myChar2:FindFirstChild("NoRotate")
				if freeze then
					freeze:Destroy()
				end
				if noRotate then
					noRotate:Destroy()
				end
			end
			task.spawn(resetCamera)
			isReviving = false
		end)
	end)
end

local function hookCharacterRevive(character)
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		watchReviveAnim(humanoid)
	else
		task.spawn(function()
			local humanoid2 = character:WaitForChild("Humanoid", 5)
			if humanoid2 then
				watchReviveAnim(humanoid2)
			end
		end)
	end

end

hookCharacterRevive(localPlayer2.Character)
charAddedConn = localPlayer2.CharacterAdded:Connect(function(newCharacter)
	task.wait(0.1)
	hookCharacterRevive(newCharacter)
end)

local function hookCounterOnCharacter(char, player2)
	if not char or not player2 or player2 == localPlayer2 then
		return
	end
	if hookedChars[char] then
		return
	end
	hookedChars[char] = true
	for index3, child in pairs(char:GetChildren()) do
		if isCounterAccessory(child) then
			if counterHookEnabled and not deathCounterDebounce[player2] then
				deathCounterDebounce[player2] = true
			end
		end
	end
	local childAddedConn = char.ChildAdded:Connect(function(newChild)
		if not counterHookEnabled then
			return
		end
		if not isCounterAccessory(newChild) then
			return
		end
		if deathCounterDebounce[player2] then
			return
		end
		deathCounterDebounce[player2] = true
	end)
	table.insert(deathCounterConns, childAddedConn)
end

local function hookPlayerCounter(player2)
	if player2 == localPlayer2 then
		return
	end
	if player2.Character then
		task.spawn(hookCounterOnCharacter, player2.Character, player2)
	end
	local charAddedConn2 = player2.CharacterAdded:Connect(function(newChar)
		if not counterHookEnabled then
			return
		end
		task.wait(0.1)
		hookCounterOnCharacter(newChar, player2)
	end)
	table.insert(deathCounterConns, charAddedConn2)
end

for index3, conn in pairs(deathCounterConns) do
	pcall(conn.Disconnect, conn)
end

for index4, player2 in pairs(playersService2:GetPlayers()) do
	hookPlayerCounter(player2)
end

table.insert(
	deathCounterConns,
	playersService2.PlayerAdded:Connect(function(player3)
		if counterHookEnabled then
			hookPlayerCounter(player3)
		end
	end)
)
combatConns = {}
counterHooks = {}
local flag = false
local desyncResetConn = localPlayer2.CharacterAdded:Connect(function()
	getgenv().desync = nil
end)
isCountering = function(humanoid)
	if not humanoid then
		return false
	end
	local model = humanoid:FindFirstAncestorWhichIsA("Model")
	if model and model:FindFirstChild("Counter") then
		return true
	end
	for index5, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		local animId = track.Animation.AnimationId
		if animId:match("13726226905") or animId:match("13726235415") then
			return true
		end
	end
	return false
end

watchPlayerCombat = function(player3, char)
	if not char then
		return
	end
	if combatConns[player3] then
		pcall(function()
			combatConns[player3]:Disconnect()
		end)
		combatConns[player3] = nil
	end
	repeat
		task.wait()
	until not char.Parent
		or (char:FindFirstChild(("H" .. "umanoidRootPart"))
 and char:FindFirstChildOfClass("Humanoid"))
	if not char.Parent then
		return
	end
	local targetRoot = char:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = char:FindFirstChildOfClass("Humanoid")
	if not (targetRoot and targetHumanoid) then
		return
	end
	local function findTrackByAnimId(humanoid, animId)
		local idPattern = tostring(animId):match("%d+")
		for index5, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			if track.Animation.AnimationId:match(idPattern) then
				return track
			end
		end
		return nil
	end
	local animPlayedConn = targetHumanoid.AnimationPlayed:Connect(function(track)
		local animId = track.Animation.AnimationId
		local myChar = localPlayer2.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not (myChar and myRoot) then
			return
		end
		task.spawn(function()
			if track.WeightTarget == 0 or track.Speed == 0 then
				return
			end
			local desyncPos = CFrame.new(9e9, 9e9, 9e9)
			local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
			local function runDesync(stopCondition)
				pcall(function()
					repeat
						getgenv().desync = { CFrame = desyncPos }
						task.wait()
						local myChar2 = localPlayer2.Character
						local myRoot2 = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
						local myHumanoid2 = myChar2 and myChar2:FindFirstChildOfClass("Humanoid")
						if not (myChar2 and myRoot2 and myHumanoid2) then
							return
						end
						myRoot = myRoot2
						myHumanoid = myHumanoid2
					until stopCondition()
				end)
				getgenv().desync = nil
				if sethiddenproperty then
					local myRoot2 = localPlayer2.Character and localPlayer2.Character:FindFirstChild("HumanoidRootPart")
					if myRoot2 then
						pcall(function()
							sethiddenproperty(myRoot2, "PhysicsRepRootPart", nil)
						end)
					end
				end
			end
			local function isCountered(humanoid)
				if not humanoid then
					return false
				end
				local model = humanoid:FindFirstAncestorWhichIsA("Model")
				return model and model:FindFirstChild("Counter") and true or false
			end
			local function makeTouchProbe(probeSize)
				local probePart = Instance.new("Part", workspace)
				probePart.Anchored = true
				probePart.Size = probeSize
				probePart.CanCollide = false
				probePart.Transparency = 1
				local isTouched = false
				local touchedConn = probePart.Touched:Connect(function(otherPart)
					if otherPart == myRoot or otherPart == getgenv().InvisPart30 then
						isTouched = true
					end
				end)
				local touchEndedConn = probePart.TouchEnded:Connect(function(otherPart)
					if otherPart == myRoot or otherPart == getgenv().InvisPart30 then
						isTouched = false
					end
				end)
				return probePart,
					function()
						return isTouched
					end,
					function()
						pcall(function()
							probePart:Destroy()
						end)
						touchedConn:Disconnect()
						touchEndedConn:Disconnect()
					end
			end
			local function getCombatPos()
				local invisPart2 = getgenv().InvisPart30
				if getgenv().InvisActive and invisPart2 then
					return invisPart2.Position
				end
				return myRoot.Position
			end
			if animId:match("12983333733")
 and char:GetAttribute("Ulted") ~= nil then
				task.delay(
					(
						(
							((math.floor(51865.1240)) + (20 * (("I"):byte()) - 900478))
							+ ((11 * (("z"):byte()) + 653714) + (38 * (("k"):byte()) + 512843))
						)
						+ (
							((1770345 - 932208) + (math.ceil(142528.0460)))
							+ ((math.floor(284682.5050)) + (47 * #"mfZCqLIR" - 1590535))
						)
					),
					function()
						if char:FindFirstChild("AbsoluteImmortal", true) and char:FindFirstChild("Freeze") then
							task.wait(4.25)
							local startTick = tick()
							runDesync(function()
								return (getCombatPos() - targetRoot.Position).Magnitude > 150
 or tick() >= startTick + 2
 or not track.IsPlaying
							end)
						end
					end
				)
			end
			if animId:match("11365563255")
 and char:GetAttribute("Ulted") ~= nil then
				task.delay(
					(
						(
							((43 * (("p"):byte()) - 637418) + (-112592 + 586155))
							+ ((649517 - 598260) + (bit32.bxor(27709, 47697) + 219015))
						)
						+ (
							((-856097 - 94089) + (bit32.bxor(32106, 771414) + 844955))
							+ ((math.floor(983374.2500)) + (2 * #"oqqSMwNadSYgCfIffCRJ" - 1812367))
						)
					),
					function()
						if char:FindFirstChild("AbsoluteImmortal", true) and char:FindFirstChild("Freeze") then
							task.wait(3)
							local startTick = tick()
							runDesync(function()
								return tick() >= startTick + 2.5
							end)
						end
					end
				)
			end
			if animId:match("13927612951")
 and char:GetAttribute("Ulted") ~= nil then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 150
 or tick() >= startTick + 2.5
				end)
			end
			if animId:match("12342141464") then
				task.wait(3.5)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 125
 or tick() >= startTick + 1.25
				end)
			end
			if animId:match("12463072679") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 25
 or tick() >= startTick + 0.75
				end)
			end
			if animId:match("13603396939") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - (targetRoot.CFrame * CFrame.new(0, 0, -1)).Position).Magnitude > 7.5
 or isCountering(
						targetHumanoid
					)
 or tick() >= startTick + 2.5
				end)
			end
			if animId:match("12460977270") then
				local probePart1, isTouched1, cleanupProbe1 = makeTouchProbe(
					Vector3.new(
						12.5,
						(
							(
								((36 * #"HaHsNNotsDLfaCtHic" - 695117) + (6 * #"fZLQ" + 1147034))
								+ ((34 * (("I"):byte()) + 132643) + (bit32.bxor(17906, 89215) + 30526))
							)
							+ (
								((13 * #"DDtLGk" + 82403) + (-1627784 + 676021))
								+ ((-761984 + 215864) + (55 * #"vwHALNkgicrQrUAwJdaKm" + 723935))
							)
						),
						12.5
					)
				)
				local probeTick1 = tick()
				repeat
					probePart1.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -6.25)
					if isTouched1() and not isCountering(targetHumanoid) then
						getgenv().desync = { CFrame = desyncPos }
					else
						getgenv().desync = nil
					end
					runService.RenderStepped:Wait()
				until tick() >= probeTick1 + 1.85 or not track.IsPlaying
				getgenv().desync = nil
				cleanupProbe1()
			end
			if animId:match("14057231976") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 10
 or tick() >= startTick + 0.5
				end)
				task.wait(0.5)
				local startTick2 = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 10
 or isCountering(targetHumanoid)
 or tick() >= startTick2 + 1.25
				end)
			end
			if animId:match("13630786846") then
				local probePart2, isTouched2, cleanupProbe2 = makeTouchProbe(
					Vector3.new(
						(
							(
								((37 * (("C"):byte()) + 691759) + (2 * #"YcKqhgGGuExFmyyUozjqZa" - 298927))
								+ ((56 * (("q"):byte()) - 924025) + (39 * (("B"):byte()) - 12067))
							)
							+ (
								((25 * (("k"):byte()) + 610396) + (-1309775 - 50838))
								+ ((42 * (("W"):byte()) + 921824) + (bit32.bxor(55513, 226818) + 112553))
							)
						),
						(
							(
								((42 * (("T"):byte()) - 172092) + (-646404 + 411068))
								+ ((32011 + 91227) + (2 * (("M"):byte()) + 4680))
							)
							+ (
								((-607506 + 940001) + (-448832 - 478050))
								+ ((math.floor(114067.6730)) + (bit32.bxor(19802, 322393) + 451515))
							)
						),
						(
							(
								((44 * (("X"):byte()) - 395596) + (52 * (("2"):byte()) - 563530))
								+ ((58 * (("w"):byte()) - 31911) + (bit32.bxor(42690, 799400) + 375889))
							)
							+ (
								((12 * (("E"):byte()) - 834396) + (6 * (("d"):byte()) + 675328))
								+ ((694188 - 202524) + (14 * (("2"):byte()) - 557301))
							)
						)
					)
				)
				local probeTick2 = tick()
				repeat
					probePart2.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -37.5)
					if isTouched2() and not isCountering(targetHumanoid) then
						getgenv().desync = { CFrame = desyncPos }
					else
						getgenv().desync = nil
					end
					runService.RenderStepped:Wait()
				until tick() >= probeTick2 + 1.5 or not track.IsPlaying
				getgenv().desync = nil
				cleanupProbe2()
			end
			if animId:match("72451715583225") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 15
 or tick() >= startTick + 0.75
				end)
			end
			if animId:match("13813955149") then
				if (getCombatPos() - targetRoot.Position).Magnitude <= 25 then
					getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
					task.wait(0.75)
					getgenv().desync = nil
				end
				local holder = nil
				holder = workspace.Thrown.ChildAdded:Connect(function(arg)
					if arg:IsA("MeshPart") and arg.Name:lower() == "trash can" then
						holder:Disconnect()
						local startTick = tick()
						runDesync(function()
							return (getCombatPos() - arg.Position).Magnitude > 25
 or tick() >= startTick + 2
						end)
					end
				end)
			end
			if animId:match("15128849047") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 100
 or findTrackByAnimId(
						targetHumanoid,
						"15123665491"
					)
 or tick() >= startTick + 3
				end)
			end
			if animId:match("15391323441") then
				task.wait(5.5)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 125
 or tick() >= startTick + 1
				end)
			end
			if animId:match("16082123712") then
				task.wait(2.5)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or tick() >= startTick + 1.5
				end)
			end
			if animId:match("14719290328") then
				if (getCombatPos() - targetRoot.Position).Magnitude <= 50 then
					getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
				end
				task.wait(0.5)
				if track.IsPlaying then
					local startTick = tick()
					runDesync(function()
						return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or isCountered(myHumanoid)
 or tick() >= startTick + 3.5
 or not track.IsPlaying
					end)
				end
			end
			if animId:match("15520132233") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or isCountered(myHumanoid)
 or tick() >= startTick + 3.3
 or not track.IsPlaying
				end)
				repeat
					task.wait()
				until tick() >= startTick + 5.5
				local startTick2 = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 100
 or isCountered(myHumanoid)
 or tick() >= startTick2 + 1
 or not track.IsPlaying
				end)
			end
			if animId:match("15676072469") then
				local probePart3, isTouched3, cleanupProbe3 = makeTouchProbe(
					Vector3.new(
						(
							(
								((25 * #"OkMQbN" + 937922) + (56 * (("m"):byte()) - 180662))
								+ ((49 * #"cqyDjeKIsIprKWFWdi" - 227951) + (math.ceil(435001.7390)))
							)
							+ (
								((10 * (("O"):byte()) + 933793) + (-282252 - 397339))
								+ ((-919957 + 934034) + (12 * (("K"):byte()) - 1241366))
							)
						),
						(
							(
								((31 * (("2"):byte()) + 694401) + (-1751645 + 896622))
								+ ((bit32.bxor(20023, 247830) + 574965) + (32 * (("R"):byte()) - 1054622))
							)
							+ (
								((10 * (("U"):byte()) + 677700) + (248283 - 60033))
								+ ((math.ceil(231194.6900)) + (18 * #"lxEWKmbL" - 692969))
							)
						),
						(
							(
								((bit32.bxor(45816, 97507) + 285179) + (45 * #"nSrxXxjz" - 190659))
								+ ((9 * #"XARnxrvkcZrPGRd" - 863753) + (bit32.bxor(27712, 283122) + 120477))
							)
							+ (((824213 - 159094) + (-1631845 + 734011)) + ((-160307 - 159411) + (-93133 + 897740)))
						)
					)
				)
				local probeTick3 = tick()
				repeat
					probePart3.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -75)
					if isTouched3() and not isCountered(myHumanoid) then
						getgenv().desync = { CFrame = desyncPos }
					else
						getgenv().desync = nil
					end
					runService.RenderStepped:Wait()
				until tick() >= probeTick3 + 2 or not track.IsPlaying
				getgenv().desync = nil
				cleanupProbe3()
			end
			if animId:match("16057411888") then
				task.wait(4.25)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or tick() >= startTick + 2
				end)
			end
			if animId:match("18435535291") then
				task.wait(4.25)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 100
 or tick() >= startTick + 1.25
				end)
			end
			if animId:match("17857788598") then
				task.wait(0.65)
				if track.IsPlaying then
					local probePart = Instance.new("Part", workspace)
					probePart.Anchored = true
					probePart.Size = Vector3.new(35, 2048, 35)
					probePart.CanCollide = false
					probePart.Transparency = 1
					local isTouched = false
					local touchedConn = probePart.Touched:Connect(function(arg)
						if arg == myRoot or arg == getgenv().InvisPart30 then
							isTouched = true
						end
					end)
					local touchEndedConn = probePart.TouchEnded:Connect(function(arg)
						if arg == myRoot or arg == getgenv().InvisPart30 then
							isTouched = false
						end
					end)
					local probeTick = tick()
					repeat
						probePart.CFrame = targetRoot.CFrame
						if isTouched and not findTrackByAnimId(targetHumanoid, "15128849047") then
							getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
						else
							getgenv().desync = nil
						end
						runService.RenderStepped:Wait()
					until tick() >= probeTick + 0.85 or not track.IsPlaying
					getgenv().desync = nil
					touchedConn:Disconnect()
					touchEndedConn:Disconnect()
					pcall(function()
						probePart:Destroy()
					end)
				end
			end
			if animId:match("129651400898906") then
				task.wait(0.5)
				local value = targetRoot.CFrame
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 75
 or tick() >= startTick + 1.25
 or not track.IsPlaying
				end)
				task.wait(1)
				local startTick2 = tick()
				runDesync(function()
					return (getCombatPos() - value.Position).Magnitude > 75
 or tick() >= startTick2 + 1.75
				end)
			end
			if animId:match("18896229321") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 15
 or isCountering(targetHumanoid)
 or tick() >= startTick + 3.5
 or not track.IsPlaying
				end)
				task.wait(1)
				if track.IsPlaying then
					if (getCombatPos() - targetRoot.Position).Magnitude <= 25 then
						local startTick2 = tick()
						runDesync(function()
							return (getCombatPos() - targetRoot.Position).Magnitude > 25
 or tick() >= startTick2 + 2
 or not track.IsPlaying
						end)
					end
				end
			end
			if animId:match("18897119503") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or tick() >= startTick + 1.5
				end)
			end
			if animId:match("106755459092436") or animId:match("75502010126640") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or tick() >= startTick + 2
				end)
			end
			if animId:match("16515850153") then
				task.spawn(function()
					if (getCombatPos() - targetRoot.Position).Magnitude <= 15 then
						getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
					end
					local var = workspace.Thrown:WaitForChild("Dotted", 1)
					if var then
						local dotsPart = var:WaitForChild("Dots", 1)
						if not dotsPart then
							getgenv().desync = nil
							return
						end
						local startTick = tick()
						if (getCombatPos() - dotsPart.Position).Magnitude > 20 then
							getgenv().desync = nil
						end
						runDesync(function()
							return (getCombatPos() - var2.Position).Magnitude > 20
 or isCountered(myHumanoid)
 or tick() >= startTick + 4.25
						end)
					else
						getgenv().desync = nil
					end
				end)
			end
			if animId:match("16431491215") then
				local startTick = tick()
				repeat
					task.wait()
				until (getCombatPos() - (targetRoot.CFrame * CFrame.new(0, 0, -25)).Position).Magnitude <= 25
					or findTrackByAnimId(targetHumanoid, "15128849047")
					or tick() >= startTick + 0.75
				if not findTrackByAnimId(targetHumanoid, "15128849047") then
					runDesync(function()
						return (getCombatPos() - (targetRoot.CFrame * CFrame.new(0, 0, -20)).Position).Magnitude > 25
 or findTrackByAnimId(
							targetHumanoid,
							"15128849047"
						)
 or tick() >= startTick + 0.75
					end)
				end
			end
			if animId:match("16597912086") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 15
 or isCountering(targetHumanoid)
 or tick() >= startTick + 0.75
				end)
			end
			if animId:match("17275150809") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or tick() >= startTick + 1
				end)
			end
			if animId:match("17278415853")
 and char:GetAttribute("Character") == "Esper" then
				task.wait(11)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 100
 or tick() >= startTick + 6
				end)
			end
			if animId:match("16734584478") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 75
 or tick() >= startTick + 5.75
				end)
			end
			if animId:match("13376869471") then
				local probePart = Instance.new("Part", workspace)
				probePart.Anchored = true
				probePart.Size = Vector3.new(10, 7.5, 60)
				probePart.CanCollide = false
				probePart.Transparency = 1
				local isTouched = false
				local touchedConn = probePart.Touched:Connect(function(arg)
					if arg == myRoot or arg == getgenv().InvisPart30 then
						isTouched = true
					end
				end)
				local touchEndedConn = probePart.TouchEnded:Connect(function(arg)
					if arg == myRoot or arg == getgenv().InvisPart30 then
						isTouched = false
					end
				end)
				local probeTick = tick()
				repeat
					probePart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -probePart.Size.Z / 2)
					runService.RenderStepped:Wait()
				until isTouched or tick() >= probeTick + 3 or not track.IsPlaying
				if isTouched then
					local probeTick2 = tick()
					runDesync(function()
						return not isTouched or tick() >= probeTick2 + 1 or not track.IsPlaying
					end)
				end
				touchedConn:Disconnect()
				touchEndedConn:Disconnect()
				pcall(function()
					probePart:Destroy()
				end)
			end
			if animId:match("13294790250") then
				task.wait(0.5)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - (targetRoot.CFrame * CFrame.new(0, 0, -2.5)).Position).Magnitude > 10
 or isCountering(
						targetHumanoid
					)
 or tick() >= startTick + 0.75
				end)
			end
			if animId:match("13632347366") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 75
 or isCountered(myHumanoid)
 or tick() >= startTick + 1.75
 or not track.IsPlaying
				end)
			end
			if animId:match("13723174078") then
				task.wait(0.5)
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 50
 or tick() >= startTick + 2
 or not track.IsPlaying
				end)
			end
			if animId:match("13881335713") then
				task.wait(0.75)
				if track.IsPlaying then
					local probePart = Instance.new("Part", workspace)
					probePart.Anchored = true
					probePart.Size = Vector3.new(35, 5, 60)
					probePart.CanCollide = false
					probePart.Transparency = 1
					local isTouched = false
					local touchedConn = probePart.Touched:Connect(function(arg)
						if arg == myRoot or arg == getgenv().InvisPart30 then
							isTouched = true
						end
					end)
					local touchEndedConn = probePart.TouchEnded:Connect(function(arg)
						if arg == myRoot or arg == getgenv().InvisPart30 then
							isTouched = false
						end
					end)
					local probeTick = tick()
					repeat
						probePart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -probePart.Size.Z / 2)
						runService.RenderStepped:Wait()
					until isTouched or tick() >= probeTick + 3 or not track.IsPlaying
					if isTouched then
						local probeTick2 = tick()
						runDesync(function()
							return not isTouched or tick() >= probeTick2 + 1 or not track.IsPlaying
						end)
					end
					touchedConn:Disconnect()
					touchEndedConn:Disconnect()
					pcall(function()
						probePart:Destroy()
					end)
				end
			end
			if animId:match("14721837245") then
				local startTick = tick()
				runDesync(function()
					return (getCombatPos() - targetRoot.Position).Magnitude > 25
 or findTrackByAnimId(
						targetHumanoid,
						"15128849047"
					)
 or tick() >= startTick + 1.5
 or not track.IsPlaying
				end)
				if tick() >= startTick + 1.5 then
					task.wait(1)
					local startTick2 = tick()
					runDesync(function()
						return (getCombatPos() - targetRoot.Position).Magnitude > 100
 or tick() >= startTick2 + 1.5
 or not track.IsPlaying
					end)
				end
			end
			if animId:match("13083332742") then
				task.wait(1)
				local probePart = Instance.new("Part", workspace)
				probePart.Anchored = true
				probePart.Size = Vector3.new(12.5, 5, 1000)
				probePart.CanCollide = false
				probePart.Transparency = 1
				task.delay(0.25, function()
					probePart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -probePart.Size.Z / 2)
				end)
				local isTouched = false
				local touchedConn = probePart.Touched:Connect(function(arg)
					if arg == myRoot or arg == getgenv().InvisPart30 then
						isTouched = true
					end
				end)
				local touchEndedConn = probePart.TouchEnded:Connect(function(arg)
					if arg == myRoot or arg == getgenv().InvisPart30 then
						isTouched = false
					end
				end)
				local probeTick = tick()
				repeat
					if isTouched and not isCountered(myHumanoid) then
						getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
					else
						getgenv().desync = nil
					end
					runService.RenderStepped:Wait()
				until tick() >= probeTick + 4 or not track.IsPlaying
				getgenv().desync = nil
				touchedConn:Disconnect()
				touchEndedConn:Disconnect()
				pcall(function()
					probePart:Destroy()
				end)
			end
			if animId:match("13146710762") then
				task.wait(3.25)
				if track.IsPlaying then
					local probeParts = {}
					local offsets = {
						CFrame.new(50, 0, -200) * CFrame.Angles(0, math.rad(-15), 0),
						CFrame.new(-50, 0, -200) * CFrame.Angles(0, math.rad(15), 0),
						CFrame.new(0, 0, -200),
					}
					local isTouched = false
					local probeConns = {}
					for index5, offset in ipairs(offsets) do
						local probePart = Instance.new("Part", workspace)
						probePart.Anchored = true
						probePart.Size = Vector3.new(100, 75, 400)
						probePart.CanCollide = false
						probePart.Transparency = 1
						probePart.CFrame = targetRoot.CFrame * offset
						table.insert(probeParts, probePart)
						table.insert(
							probeConns,
							probePart.Touched:Connect(function(otherPart)
								if otherPart == myRoot or otherPart == getgenv().InvisPart30 then
									isTouched = true
								end
							end)
						)
						table.insert(
							probeConns,
							probePart.TouchEnded:Connect(function(otherPart)
								if otherPart == myRoot or otherPart == getgenv().InvisPart30 then
									isTouched = false
								end
							end)
						)
					end
					local probeTick = tick()
					repeat
						if isTouched and not isCountered(myHumanoid) then
							getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
						else
							getgenv().desync = nil
						end
						runService.RenderStepped:Wait()
					until tick() >= probeTick + 6 or not track.IsPlaying
					getgenv().desync = nil
					for index6, conn2 in ipairs(probeConns) do
						conn2:Disconnect()
					end
					for index7, part in ipairs(probeParts) do
						pcall(function()
							part:Destroy()
						end)
					end
				end
			end
			if animId:match("11343318134") then
				task.wait(7.5)
				if not track.IsPlaying then
					return
				end
				local probeParts = {}
				local offsets = {
					CFrame.new(60, 0, -250) * CFrame.Angles(0, math.rad(-15), 0),
					CFrame.new(-60, 0, -250) * CFrame.Angles(0, math.rad(15), 0),
					CFrame.new(0, 0, -250),
				}
				local touchedFlags = { false, false, false }
				local probeConns = {}
				for index5, offset in ipairs(offsets) do
					local probePart = Instance.new("Part", workspace)
					probePart.Anchored = true
					probePart.Size = Vector3.new(125, 5, 500)
					probePart.CanCollide = false
					probePart.Transparency = 1
					table.insert(probeParts, probePart)
					local flagIndex = index5
					table.insert(
						probeConns,
						probePart.Touched:Connect(function(otherPart)
							if otherPart == myRoot or otherPart == getgenv().InvisPart30 then
								touchedFlags[flagIndex] = true
							end
						end)
					)
					table.insert(
						probeConns,
						probePart.TouchEnded:Connect(function(otherPart)
							if otherPart == myRoot or otherPart == getgenv().InvisPart30 then
								touchedFlags[flagIndex] = false
							end
						end)
					)
				end
				local probeTick = tick()
				repeat
					for index6, part in ipairs(probeParts) do
						part.CFrame = targetRoot.CFrame * offsets[index6]
					end
					if touchedFlags[1] or touchedFlags[2] or touchedFlags[3] then
						getgenv().desync = { CFrame = CFrame.new(9e9, 9e9, 9e9) }
					else
						getgenv().desync = nil
					end
					runService.RenderStepped:Wait()
				until tick() >= probeTick + 2.5 or not track.IsPlaying
				getgenv().desync = nil
				for index6, conn2 in ipairs(probeConns) do
					conn2:Disconnect()
				end
				for index7, part in ipairs(probeParts) do
					pcall(function()
						part:Destroy()
					end)
				end
			end
		end)
	end)
	combatConns[player3] = animPlayedConn
end

watchPlayerCounters = function(player3)
	if player3 == localPlayer2 then
		return
	end
	if player3.Character then
		task.spawn(watchPlayerCombat, player3, player3.Character)
	end
	local charAddedConn2 = player3.CharacterAdded:Connect(function(newChar)
		task.spawn(watchPlayerCombat, player3, newChar)
	end)
	counterHooks[player3] = charAddedConn2
end

for index5, player3 in pairs(playersService2:GetPlayers()) do
	task.spawn(watchPlayerCounters, player3)
end

local playerAddedConn2 = playersService2.PlayerAdded:Connect(function(player4)
	if player4 == localPlayer2 then
		return
	end
	task.spawn(function()
		local startTick = tick()
		repeat
			runService.RenderStepped:Wait()
		until player4:GetAttribute("PreloadDone") or tick() >= startTick + 30
		if player4 and player4.Parent then
			if player4.Character then
				task.spawn(watchPlayerCombat, player4, player4.Character)
			end
			local charAddedConn2 = player4.CharacterAdded:Connect(function(newChar)
				task.spawn(watchPlayerCombat, player4, newChar)
			end)
			counterHooks[player4] = charAddedConn2
		end
	end)
end)
local playerRemovingConn = playersService2.PlayerRemoving:Connect(function(player4)
	if combatConns[player4] then
		pcall(function()
			combatConns[player4]:Disconnect()
		end)
		combatConns[player4] = nil
	end
	if counterHooks[player4] then
		pcall(function()
			counterHooks[player4]:Disconnect()
		end)
		counterHooks[player4] = nil
	end

end)

local function detachSelfPhysics()
	local myChar = localPlayer2.Character
	if sethiddenproperty then
		if myChar and myChar.Parent then
			pcall(function()
				sethiddenproperty(myChar, "PhysicsRepRootPart", nil)
			end)
		end
	end
	if myChar and myChar.Parent then
		pcall(function()
			myChar.HumanoidRootPart.CFrame = CFrame.new(myChar.HumanoidRootPart.Position)
		end)
		pcall(function()
			myChar.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		end)
		pcall(function()
			myChar.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
		end)
		pcall(function()
			myChar.HumanoidRootPart.Velocity = Vector3.zero
		end)
		pcall(function()
			myChar.HumanoidRootPart.RotVelocity = Vector3.zero
		end)
		local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
		if myHumanoid then
			pcall(function()
				myHumanoid.AutoRotate = true
			end)
		end
	end

end

local function setupCombatLoop()
	local unusedCount = 6
	local dashCooldown = 0
	local lastM1 = 0
	local lastSkills = 0
	local lastSpace = 0
	local lastUltInput = 0
	local M1_INTERVAL = 0.035
	local SKILL_INTERVAL = 0.055
	local DASH_INTERVAL = 0.2
	local SPACE_INTERVAL = 0.12
	local ULT_INTERVAL = 0.04
	local leftClickGoal = {
		Goal = "LeftClick",
		MousePos = CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
	}
	local releaseGoal = {
		Goal = "LeftClickRelease",
	}
	local mobileClickGoal = {
		Mobile = true,
		Goal = "LeftClick",
		MousePos = CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
	}
	local dashGoal = {
		Dash = Enum.KeyCode.W,
		Key = Enum.KeyCode.Q,
		Goal = "KeyPress",
		MousePos = CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
	}
	local backDashGoal = {
		Dash = Enum.KeyCode.S,
		Key = Enum.KeyCode.Q,
		Goal = "KeyPress",
	}
	local spaceGoal = {
		Goal = "KeyPress",
		Key = Enum.KeyCode.Space,
		MousePos = CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
	}
	local skillKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
	local attackAnimIds = {
		"17799224866",
		"17838006839",
		"17838619895",
		"17857788598",
		"17857880283",
		"18179181663",
		"18182425133",
		"18464351556",
		"18464356233",
		"18464372850",
		"18464362124",
		"136370737633649",
		"130301810149072",
		"17889290569",
		"10479335397",
		"18896229321",
	}
	local function isAttacking2(humanoid)
		if not humanoid then
			return false
		end
		for index6, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			local animId = track.Animation.AnimationId
			for index7, animId2 in ipairs(attackAnimIds) do
				if animId:match(animId2) then
					isAttacking = true
					return true
				end
			end
		end
		isAttacking = false
		return false
	end
	local function tapKey(keyCode)
		virtualInput:SendKeyEvent(true, keyCode, false, game)
		task.delay(0.01, function()
			virtualInput:SendKeyEvent(false, keyCode, false, game)
		end)
	end
	local function fireGoal(communicate, goal)
		pcall(communicate.FireServer, communicate, goal)
	end
	local function getHotbarSlot(slotName)
		local playerGui = localPlayer2:FindFirstChild("PlayerGui")
		local hotbar = playerGui and playerGui:FindFirstChild("Hotbar")
		local backpack = hotbar and hotbar:FindFirstChild("Backpack")
		local hotbarFrame = backpack and backpack:FindFirstChild("Hotbar")
		return hotbarFrame and hotbarFrame:FindFirstChild(slotName)
	end
	local function slotReady(slotName, threshold)
		local slot = getHotbarSlot(slotName)
		local slotBase = slot and slot:FindFirstChild("Base")
		local cooldown = slotBase and slotBase:FindFirstChild("Cooldown")
		if not cooldown then
			return true
		end
		return cooldown.Size.Y.Scale >= (threshold or -0.2)
	end
	runService.Heartbeat:Connect(function()
		if not farmEnabled then
			return
		end
		if getgenv().desync then
			return
		end
		local now = tick()
		if isUlted then
			if ultKeyReady then
				if now - lastUltInput >= ULT_INTERVAL then
					lastUltInput = now
					tapKey(Enum.KeyCode.One)
					local slotOne = getHotbarSlot("1")
					local slotBase = slotOne and slotOne:FindFirstChild("Base")
					local cooldown = slotBase and slotBase:FindFirstChild("Cooldown")
					if cooldown and cooldown.Size.Y.Scale <= -0.8 then
						ultKeyReady = false
					end
				end
			else
				if now - lastUltInput >= ULT_INTERVAL and slotReady("2", -0.2) then
					lastUltInput = now
					pcall(function()
						localPlayer2.Character.HumanoidRootPart.CFrame = CFrame.new(150, 441, 32)
					end)
					tapKey(Enum.KeyCode.Two)
				end
			end
		else
			if not currentTarget then
				return
			end
			local targetChar = currentTarget.Character
			local myChar = localPlayer2.Character
			if not targetChar or not myChar then
				return
			end
			if targetChar:FindFirstChildWhichIsA("ForceField") then
				return
			end
			if targetChar:FindFirstChild("AbsoluteImmortal") then
				return
			end
			if targetChar:FindFirstChild("BeingGrabbed") then
				return
			end
			if targetChar:FindFirstChild("HunterCounter") then
				return
			end
			if targetChar:FindFirstChild("AtomicCounter") then
				return
			end
			local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
			isAttacking2(myHumanoid)
			local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
			local targetTorso = targetChar:FindFirstChild("Torso")
			if not targetHumanoid or not targetTorso or targetTorso.Transparency == 1 then
				return
			end
			local communicate = myChar:FindFirstChild("Communicate")
			if not communicate then
				return
			end
			if not myChar:GetAttribute("HoldingSpace") and now - lastSpace >= SPACE_INTERVAL then
				lastSpace = now
				fireGoal(communicate, spaceGoal)
			end
			if myChar:FindFirstChild("Ragdoll") or myChar:FindFirstChild("RagdollSim") then
				fireGoal(communicate, backDashGoal)
			end
			if
				(targetChar:FindFirstChild("Ragdoll") or targetChar:FindFirstChild("RagdollSim"))
				or targetHumanoid.Health <= 15
			then
				if myChar:GetAttribute("HoldingM1") then
					fireGoal(communicate, releaseGoal)
				end
				if targetHumanoid.Health > 15 then
					if now - dashCooldown >= DASH_INTERVAL then
						fireGoal(communicate, dashGoal)
						dashCooldown = tick()
					end
				end
				if now - lastSkills >= SKILL_INTERVAL then
					lastSkills = now
					for index8, keyCode in ipairs(skillKeys) do
						tapKey(keyCode)
					end
				end
			else
				if now - lastM1 >= M1_INTERVAL then
					lastM1 = now
					if myChar:GetAttribute("mobile") then
						fireGoal(communicate, mobileClickGoal)
					else
						fireGoal(communicate, leftClickGoal)
					end
					task.delay(0.018, function()
						local latestChar = localPlayer2.Character
						local latestCommunicate = latestChar and latestChar:FindFirstChild("Communicate")
						if latestCommunicate then
							fireGoal(latestCommunicate, releaseGoal)
						end
					end)
				end
			end
		end
	end)
end

local function offsetCFrameBehind(targetRoot, heightOffset, forwardOffset)
	local targetCFrame2 = targetRoot.CFrame
	local rx, ry, rz = targetCFrame2:ToEulerAnglesYXZ()
	local yawCFrame = CFrame.fromEulerAnglesYXZ(0, ry, 0)
	local offsetCFrame = CFrame.new(targetCFrame2.Position) * yawCFrame * CFrame.new(0, heightOffset, forwardOffset)
	local offsetPos = offsetCFrame.Position
	return CFrame.new(offsetPos) * yawCFrame
end

local function setupAimLoop()
	local heartbeatConn = nil
	local unusedHolder2 = nil
	local immortalWait = nil
	currentTarget = findWeakestTarget()
	heartbeatConn = runService.Heartbeat:Connect(function()
		if not farmEnabled then
			if currentlyTargeting then
				currentlyTargeting = false
				detachSelfPhysics()
				currentTarget = findWeakestTarget()
			end
			return
		end
		if isReviving then
			return
		end
		if not currentTarget then
			currentlyTargeting = false
			detachSelfPhysics()
			currentTarget = findWeakestTarget()
			return
		end
		local targetChar = currentTarget.Character
		local myChar = localPlayer2.Character
		if not myChar then
			return
		end
		local magicHealthBar = localPlayer2.PlayerGui.Bar.MagicHealth.Health.Bar
		if magicHealthBar.Size.X == UDim.new(1, 0) and not gKeyBusy then
			gKeyBusy = true
			ultKeyReady = false
			task.spawn(function()
				task.wait(0.5)
				virtualInput:SendKeyEvent(true, Enum.KeyCode.G, false, game)
				task.wait(0.001)
				virtualInput:SendKeyEvent(false, Enum.KeyCode.G, false, game)
				gKeyBusy = false
			end)
		end
		if myChar:GetAttribute("Ulted") then
			isUlted = true
			currentlyTargeting = false
			return
		else
			isUlted = false
		end
		if isTeleporting then
			return
		end
		if not targetChar then
			if currentlyTargeting then
				currentlyTargeting = false
			end
			detachSelfPhysics()
			currentTarget = findWeakestTarget()
			return
		end
		if targetChar:GetAttribute("Ulted") or targetChar:FindFirstChild("Counter") then
			if currentlyTargeting then
				currentlyTargeting = false
			end
			detachSelfPhysics()
			currentTarget = findWeakestTarget()
			return
		end
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
		local myRoot = myChar:FindFirstChild("HumanoidRootPart")
		local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
		if not targetRoot or not targetHumanoid or not myRoot or not myHumanoid then
			if currentlyTargeting then
				currentlyTargeting = false
			end
			detachSelfPhysics()
			currentTarget = findWeakestTarget()
			return
		end
		if targetChar:FindFirstChild("AbsoluteImmortal") then
			if targetHumanoid.Health <= 20 then
				detachSelfPhysics()
				currentTarget = findWeakestTarget()
				return
			else
				if not immortalWait then
					immortalWait = tick()
				else
					if
						(tick() - immortalWait >= 5)
						or (targetChar:FindFirstChildOfClass("Humanoid") and targetChar.Humanoid.Health <= 10)
					then
						immortalWait = nil
						if currentlyTargeting then
							currentlyTargeting = false
						end
						detachSelfPhysics()
						currentTarget = findWeakestTarget()
						return
					end
				end
			end
		end
		if targetHumanoid.Health <= 0 then
			if currentlyTargeting then
				currentlyTargeting = false
			end
			detachSelfPhysics()
			currentTarget = findWeakestTarget()
			return
		end
		local targetTorso = targetChar:FindFirstChild("Torso")
		if not targetTorso or targetTorso.Transparency == 1 then
			if currentlyTargeting then
				currentlyTargeting = false
			end
			detachSelfPhysics()
			currentTarget = findWeakestTarget()
			return
		end
		if not currentlyTargeting then
			warn("[GalaxyHub] Targeting: " .. currentTarget.Name)
			currentlyTargeting = true
			myHumanoid.AutoRotate = false
		end
		myRoot.AssemblyLinearVelocity = Vector3.zero
		myRoot.AssemblyAngularVelocity = Vector3.zero
		if not getgenv().desync then
			myRoot.CFrame = offsetCFrameBehind(targetRoot, 0, 5)
			targetCFrame = myRoot.CFrame
		else
			targetCFrame = offsetCFrameBehind(targetRoot, 0, 5)
		end
		if sethiddenproperty then
			sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot)
		end
	end)
end

local function setupAntiAfk()
	local virtualUser = game:GetService("VirtualUser")
	localPlayer2.Idled:Connect(function()
		virtualUser:CaptureController()
		virtualUser:ClickButton2(Vector2.new())
	end)
end

task.spawn(function()
	while true do
		local myChar = localPlayer2.Character
		local className = myChar and myChar:GetAttribute("Character")
		local communicate = myChar and myChar:FindFirstChild("Communicate")
		if communicate and className ~= "Purple" then
			pcall(communicate.FireServer, communicate, {
				Goal = "Change Character",
				Character = "Purple",
			})
		end
		task.wait(1)
	end

end)
task.spawn(function()
	local thrownFolder = workspace:FindFirstChild("Thrown")
	if thrownFolder then
		for index6, part in pairs(thrownFolder:GetChildren()) do
			if part.Name:lower():find("debris") or part.Name:lower() == "part" then
				task.spawn(pcall, _deleteNew, part)
			end
		end
		thrownFolder.ChildAdded:Connect(function(newPart)
			if newPart.Name:lower():find("debris") or newPart.Name:lower() == "part" then
				task.spawn(pcall, _deleteNew, newPart)
			end
		end)
	end

end)
task.wait(1)
setupCombatLoop()
setupAimLoop()
setupAntiAfk()
task.spawn(function()
	task.wait(1)
	while true do
		if farmSettings.webhookUrl then
			pcall(sendWebhook)
			task.wait(30)
		end
	end

end)
task.spawn(function()
	local desyncTimer = nil
	while true do
		if getgenv().desync then
			desyncTimer = tick()
			repeat
				task.wait()
			until (tick() - desyncTimer >= 20) or not getgenv().desync
			desyncTimer = nil
			getgenv().desync = nil
		end
		runService.RenderStepped:Wait()
	end

end)
task.spawn(function()
	while task.wait(0.25) do
		local myChar = localPlayer2.Character
		local communicate = myChar and myChar:FindFirstChild("Communicate")
		if communicate then
			pcall(communicate.FireServer, communicate, { Goal = "Emote Spin" })
		end
	end

end)
local sawUlt = false
task.spawn(function()
	while true do
		if isUlted then
			sawUlt = true
		end
		local playerCount = #playersService2:GetPlayers()
		if
			((playerCount <= 7) or (sessionKills >= tonumber(farmSettings.hopOnCount)) or sawUlt)
			and ((not isUlted) and not isTeleporting)
		then
			hopServer()
		end
		task.wait(1)
	end

end)
