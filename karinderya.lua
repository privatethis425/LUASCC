-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
if not getfenv().LPH_NO_VIRTUALIZE then
	loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()
end

getfenv().PP_SCRAMBLE_NUM = getfenv().PP_SCRAMBLE_NUM or function(...)
	return ...
end
getfenv().PP_SCRAMBLE_STR = getfenv().PP_SCRAMBLE_STR or function(...)
	return ...
end
getfenv().PP_SCRAMBLE_RE_NUM = getfenv().PP_SCRAMBLE_RE_NUM or function(...)
	return ...
end

-- Keep one farm instance across repeated executions.
local Farm = {
	detached = false,
	enabled = false,
	runId = 0,
	groceryEnabled = false,
	groceryRunId = 0,
	shopEnabled = false,
	shopRunId = 0,
	selectedShopEnabled = false,
	selectedShopRunId = 0,
	selectedShopProducts = {},
	shopProductLookup = {},
	plot = nil,
	window = nil,
	toggle = nil,
	groceryToggle = nil,
	shopDropdowns = {},
	shopToggle = nil,
	selectedShopToggle = nil,
	ingredientConfig = nil,
	lastErrorAt = 0,
	lastRefillAt = 0,
	lastSeatAt = 0,
	lastSeatNpcId = nil,
	lastPanHits = setmetatable({}, { __mode = "k" }),
}

-- Constants.
local TARGET_PLACE_ID = 116497287371701
local RAYFIELD_URL = "https://sirius.menu/gen2"
local CONTROL_INTERVAL = 0.4
local ACTION_INTERVAL = 0.03
local SEAT_RETRY_DELAY = 1.5
local REFILL_INTERVAL = 8
local MIN_STAPLE_STOCK = 5
local STAPLE_BUY_AMOUNT = 10
local PAN_HIT_INTERVAL = 0.8
local WASH_HOLD_TIME = 6.25
local PROMPT_POSITION_DELAY = 0.04
local PROMPT_RESULT_TIMEOUT = 0.25
local PROMPT_POLL_INTERVAL = 0.01
local GROCERY_INTERVAL = 3
local GROCERY_PURCHASE_DELAY = 0.15
local SHOP_REFRESH_INTERVAL = 1
local SHOP_PURCHASE_DELAY = 0.05
local SHOP_CATEGORIES = {
	"Tables",
	"Chairs",
	"Stoves",
	"Paints",
	"Materials",
	"Tiles",
}

-- Services.
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspaceService = game:GetService("Workspace")

-- State.
local localPlayer = playersService.LocalPlayer
local remotes = replicatedStorage:WaitForChild("Remotes")
local counterRemotes = remotes:WaitForChild("CounterRemotes")
local npcRemotes = remotes:WaitForChild("NPCRemotes")
local shopRemotes = remotes:WaitForChild("ShopRemotes")
local assignNpcRemote = counterRemotes:WaitForChild("AssignNPC")
local getCounterInfoRemote = counterRemotes:WaitForChild("GetCounterInfo")
local getNpcStateRemote = npcRemotes:WaitForChild("GetNPCState")
local buyIngredientRemote = shopRemotes:WaitForChild("BuyIngredient")
local getShopInfoRemote = shopRemotes:WaitForChild("GetShopInfo")
local buyFurnitureRemote = shopRemotes:WaitForChild("BuyFurniture")
local hitRunawayRemote = remotes:WaitForChild("HitRunawayEvent")
local modules = replicatedStorage:WaitForChild("Modules")
local ingredientsConfigScript = modules:WaitForChild("IngredientsConfig")
local furnitureConfigScript = modules:WaitForChild("FurnitureConfig")
local paintConfigScript = modules:WaitForChild("PaintConfig")
local materialConfigScript = modules:WaitForChild("MaterialConfig")
local tileConfigScript = modules:WaitForChild("TileConfig")
local reloadState = getfenv().STATE

---Return a response body from the executor's request API.
---@param url string
---@return string
local function requestSource(url)
	local response = request({
		Url = url,
		Method = "GET",
	})

	if type(response) == "string" then
		return response
	end

	if type(response) ~= "table" or response.Success == false then
		error("Failed to download Rayfield Gen2.")
	end

	return response.Body
end

---Return the current character and its root part.
---@return Model?, BasePart?
local function getCharacter()
	local character = localPlayer.Character
	if not character then
		return nil, nil
	end

	return character, character:FindFirstChild("HumanoidRootPart")
end

---Load one game config without exposing executor permissions.
---@param moduleScript ModuleScript
---@return table
local function requireGameModule(moduleScript)
	local originalIdentity = getthreadidentity()
	local ok, config = pcall(function()
		setthreadidentity(2)
		return getrenv().require(moduleScript)
	end)
	setthreadidentity(originalIdentity)

	if not ok or type(config) ~= "table" then
		error("Failed to load game configuration: " .. tostring(config))
	end

	return config
end

---Load the game's grocery limits once.
---@return table
local function getIngredientConfig()
	if Farm.ingredientConfig then
		return Farm.ingredientConfig
	end

	Farm.ingredientConfig = requireGameModule(ingredientsConfigScript)
	return Farm.ingredientConfig
end

---Return the direct Workspace plot containing an instance.
---@param instance Instance?
---@return Instance?
local function getPlotFromInstance(instance)
	local current = instance
	while current and current.Parent ~= workspaceService do
		current = current.Parent
	end

	if current and current.Name:match("^Karenderya") then
		return current
	end

	return nil
end

---Resolve the local restaurant from counter data.
---@param customer table?
---@param seats table?
---@return Instance?
local function resolvePlot(customer, seats)
	if Farm.plot and Farm.plot.Parent == workspaceService then
		return Farm.plot
	end

	if type(seats) == "table" and seats[1] and seats[1].Slot then
		Farm.plot = getPlotFromInstance(seats[1].Slot)
		if Farm.plot then
			return Farm.plot
		end
	end

	for _, candidate in ipairs(workspaceService:GetChildren()) do
		if candidate.Name:match("^Karenderya") and candidate:GetAttribute("Owner") == localPlayer.UserId then
			Farm.plot = candidate
			return Farm.plot
		end
	end

	if not customer then
		return nil
	end

	local npcId = customer.NpcId or customer.TemplateName
	local ok, states = pcall(function()
		return getNpcStateRemote:InvokeServer()
	end)
	if not ok or type(states) ~= "table" then
		return nil
	end

	for _, state in ipairs(states) do
		if state.NpcId == npcId and state.Plot then
			Farm.plot = state.Plot
			return Farm.plot
		end
	end

	return nil
end

---Return the food accessory currently held by the player.
---@return Accessory?
local function getHeldFood()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute("IsFood") then
			return child
		end
	end

	return nil
end

---Wait briefly for a server-confirmed state change without a fixed delay.
---@param predicate function
---@param timeout number
---@return boolean
local function waitForCondition(predicate, timeout)
	local deadline = os.clock() + timeout
	repeat
		if predicate() then
			return true
		end
		task.wait(PROMPT_POLL_INTERVAL)
	until os.clock() >= deadline

	return predicate()
end

---Run one callback while the character is beside a server-validated prompt.
---@param prompt ProximityPrompt
---@param callback function
---@param completed function?
---@return boolean
local function runBesidePrompt(prompt, callback, completed)
	local _, rootPart = getCharacter()
	local promptPart = prompt.Parent
	if not rootPart or not promptPart or not promptPart:IsA("BasePart") then
		return false
	end

	local originalCFrame = rootPart.CFrame
	local originalLinearVelocity = rootPart.AssemblyLinearVelocity
	local originalAngularVelocity = rootPart.AssemblyAngularVelocity
	local succeeded = false

	local ok = xpcall(function()
		rootPart.CFrame = promptPart.CFrame * CFrame.new(0, 3, 0)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		task.wait(PROMPT_POSITION_DELAY)
		callback()
		succeeded = not completed or waitForCondition(completed, PROMPT_RESULT_TIMEOUT)
	end, function(errorMessage)
		warn(errorMessage)
	end)

	if rootPart.Parent then
		rootPart.CFrame = originalCFrame
		rootPart.AssemblyLinearVelocity = originalLinearVelocity
		rootPart.AssemblyAngularVelocity = originalAngularVelocity
	end

	return ok and succeeded
end

---Buy low staple ingredients before the counter can stall.
local function refillStaples()
	if Farm.groceryEnabled then
		return
	end

	if os.clock() - Farm.lastRefillAt < REFILL_INTERVAL then
		return
	end

	Farm.lastRefillAt = os.clock()
	local ingredients = localPlayer:FindFirstChild("Ingredients")
	if not ingredients then
		return
	end

	for _, ingredientName in ipairs({ "Rice", "Condiments" }) do
		local ingredient = ingredients:FindFirstChild(ingredientName)
		if ingredient and ingredient.Value <= MIN_STAPLE_STOCK then
			pcall(function()
				buyIngredientRemote:InvokeServer(ingredientName, STAPLE_BUY_AMOUNT, "Cash")
			end)
			task.wait(0.15)
		end
	end
end

---Fill every available grocery item to its configured stock cap.
local function buyAllGroceries()
	local ingredients = localPlayer:FindFirstChild("Ingredients")
	local leaderstats = localPlayer:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if not ingredients or not cash or cash.Value <= 0 then
		return
	end

	local ingredientConfig = getIngredientConfig()
	local ingredientNames = {}
	for ingredientName in pairs(ingredientConfig) do
		if ingredients:FindFirstChild(ingredientName) then
			table.insert(ingredientNames, ingredientName)
		end
	end
	table.sort(ingredientNames)

	for _, ingredientName in ipairs(ingredientNames) do
		if not Farm.groceryEnabled or Farm.detached then
			return
		end

		local ingredient = ingredients:FindFirstChild(ingredientName)
		local config = ingredientConfig[ingredientName]
		local requiredExpansion = config.RequiresExpansion
		if requiredExpansion then
			local plot = resolvePlot(nil, nil)
			local expansion = plot and plot:FindFirstChild(requiredExpansion, true)
			if not expansion or expansion:GetAttribute("IsRepaired") ~= true then
				continue
			end
		end

		local maxStock = config.MaxStock or 100
		local yieldAmount = math.max(1, config.YieldAmount or 1)
		local cost = math.max(1, config.Cost or math.huge)
		local missingStock = maxStock - ingredient.Value
		if missingStock <= 0 then
			continue
		end

		local requiredPackages = math.ceil(missingStock / yieldAmount)
		local affordablePackages = math.floor(cash.Value / cost)
		local packageCount = math.min(requiredPackages, affordablePackages)
		if packageCount <= 0 then
			continue
		end

		pcall(function()
			buyIngredientRemote:InvokeServer(ingredientName, packageCount, "Cash")
		end)
		task.wait(GROCERY_PURCHASE_DELAY)
	end
end

---Return a readable fallback when a config has no product label.
---@param categoryName string
---@param productKey string
---@return string
local function humanizeProductKey(categoryName, productKey)
	local productName = productKey:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2")
	if productKey == "WoodPlank" and categoryName == "Tables" then
		return productName .. " Table"
	end
	if productKey == "WoodPlank" and categoryName == "Chairs" then
		return productName .. " Chair"
	end

	return productName
end

---Return the display name associated with one server product key.
---@param categoryName string
---@param productKey string
---@param configs table
---@return string
local function getProductDisplayName(categoryName, productKey, configs)
	local productConfig
	if categoryName == "Tables" then
		productConfig = configs.furniture.Dining.Tables[productKey]
	elseif categoryName == "Chairs" then
		productConfig = configs.furniture.Dining.Chairs[productKey]
	elseif categoryName == "Stoves" then
		productConfig = configs.furniture.Kitchen.Stoves[productKey]
	elseif categoryName == "Paints" then
		productConfig = configs.paints[productKey]
	elseif categoryName == "Materials" then
		productConfig = configs.materials[productKey]
	elseif categoryName == "Tiles" then
		productConfig = configs.tiles[productKey]
	end

	if type(productConfig) == "table" and type(productConfig.Name) == "string" then
		return productConfig.Name
	end

	return humanizeProductKey(categoryName, productKey)
end

---Build friendly product lists while preserving exact server keys.
---@return table
local function buildShopProductCatalog()
	local ok, shopStock = pcall(function()
		return getShopInfoRemote:InvokeServer()
	end)
	if not ok or type(shopStock) ~= "table" then
		error("Failed to load shop products.")
	end

	local configs = {
		furniture = requireGameModule(furnitureConfigScript),
		paints = requireGameModule(paintConfigScript),
		materials = requireGameModule(materialConfigScript),
		tiles = requireGameModule(tileConfigScript),
	}
	local productOptions = {}

	for _, categoryName in ipairs(SHOP_CATEGORIES) do
		productOptions[categoryName] = {}
		Farm.selectedShopProducts[categoryName] = {}
		Farm.shopProductLookup[categoryName] = {}

		for _, item in ipairs(shopStock[categoryName] or {}) do
			local displayName = getProductDisplayName(categoryName, item.Key, configs)
			Farm.shopProductLookup[categoryName][displayName] = item.Key
			table.insert(productOptions[categoryName], displayName)
		end

		table.sort(productOptions[categoryName])
	end

	return productOptions
end

---Return whether at least one individual shop product is selected.
---@return boolean
local function hasSelectedShopProduct()
	for _, selectedProducts in pairs(Farm.selectedShopProducts) do
		if next(selectedProducts) then
			return true
		end
	end

	return false
end

---Return whether the requested shop mode is still active.
---@param selectedOnly boolean
---@return boolean
local function isShopModeEnabled(selectedOnly)
	if selectedOnly then
		return Farm.selectedShopEnabled
	end

	return Farm.shopEnabled
end

---Buy available shop stock, optionally limited to selected products.
---@param selectedOnly boolean
local function buyShopStock(selectedOnly)
	if selectedOnly and not hasSelectedShopProduct() then
		return
	end

	local ok, shopStock = pcall(function()
		return getShopInfoRemote:InvokeServer()
	end)
	if not ok or type(shopStock) ~= "table" then
		return
	end

	for _, categoryName in ipairs(SHOP_CATEGORIES) do
		local categoryStock = shopStock[categoryName]
		local selectedProducts = Farm.selectedShopProducts[categoryName]
		if type(categoryStock) ~= "table" then
			continue
		end

		for _, item in ipairs(categoryStock) do
			if selectedOnly and not selectedProducts[item.Key] then
				continue
			end

			for _ = 1, math.max(0, item.Stock or 0) do
				if not isShopModeEnabled(selectedOnly) or Farm.detached then
					return
				end

				local purchaseOk, purchased = pcall(function()
					return buyFurnitureRemote:InvokeServer(item.SystemType, item.Category, item.Key)
				end)
				if not purchaseOk or not purchased then
					break
				end

				task.wait(SHOP_PURCHASE_DELAY)
			end
		end
	end
end

---Buy all stock currently available in every shop category.
local function buyAllShopStock()
	buyShopStock(false)
end

---Buy available stock for every individually selected product.
local function buySelectedShopStock()
	buyShopStock(true)
end

---Assign the current counter customer to the first free seat.
local function seatCustomer()
	local ok, customer, seats = pcall(function()
		return getCounterInfoRemote:InvokeServer()
	end)
	if not ok then
		return
	end

	resolvePlot(customer, seats)
	if not customer or type(seats) ~= "table" or not seats[1] then
		return
	end

	local npcId = customer.NpcId or customer.TemplateName or ""
	if Farm.lastSeatNpcId == npcId and os.clock() - Farm.lastSeatAt < SEAT_RETRY_DELAY then
		return
	end

	local seat = seats[1]
	Farm.lastSeatNpcId = npcId
	Farm.lastSeatAt = os.clock()
	assignNpcRemote:FireServer({
		Slot = seat.Slot,
		Seat = seat.Seat,
		NPCName = npcId,
		NpcId = npcId,
	})
end

---Hit each active runaway without flooding the server.
local function hitRunaways()
	local clientNpcs = workspaceService:FindFirstChild("ClientNPCs")
	if not clientNpcs then
		return
	end

	for _, model in ipairs(clientNpcs:QueryDescendants("Model[$IsRunaway]")) do
		if model:GetAttribute("IsRunaway") ~= true then
			continue
		end

		local lastHit = Farm.lastPanHits[model] or 0
		if os.clock() - lastHit < PAN_HIT_INTERVAL then
			continue
		end

		Farm.lastPanHits[model] = os.clock()
		hitRunawayRemote:FireServer(model.Name)
	end
end

---Return an enabled prompt with the requested table action.
---@param root Instance
---@param tableAction string
---@return ProximityPrompt?
local function findActionPrompt(root, tableAction)
	for _, prompt in ipairs(root:QueryDescendants("ProximityPrompt")) do
		if prompt.Enabled and prompt:GetAttribute("TableAction") == tableAction then
			return prompt
		end
	end

	return nil
end

---Return the table prompt that matches the held meal's order key.
---@param root Instance
---@param orderKey string?
---@return ProximityPrompt?
local function findServePrompt(root, orderKey)
	local fallback
	for _, prompt in ipairs(root:QueryDescendants("ProximityPrompt")) do
		if not prompt.Enabled or prompt:GetAttribute("TableAction") ~= "Serve" then
			continue
		end

		fallback = fallback or prompt
		if orderKey and prompt.ActionText:find(orderKey, 1, true) then
			return prompt
		end
	end

	if not orderKey then
		return fallback
	end

	return nil
end

---Serve the held meal at its matching table.
---@param plot Model
---@param food Accessory
---@return boolean
local function serveHeldFood(plot, food)
	local diningPlot = plot:FindFirstChild("DiningPlot1")
	if not diningPlot then
		return false
	end

	local orderKey = food:GetAttribute("OrderKey")
	local deadline = os.clock() + PROMPT_RESULT_TIMEOUT
	local servePrompt
	repeat
		servePrompt = findServePrompt(diningPlot, orderKey)
		if servePrompt then
			break
		end
		task.wait(0.1)
	until os.clock() >= deadline or not Farm.enabled

	if not servePrompt or not Farm.enabled then
		return false
	end

	return runBesidePrompt(servePrompt, function()
		fireproximityprompt(servePrompt)
	end, function()
		return food.Parent == nil
	end)
end

---Pick up the next cooked meal and serve it.
---@param plot Model
---@return boolean
local function pickupAndServe(plot)
	local serveFolder = plot:FindFirstChild("Serve")
	if not serveFolder then
		return false
	end

	local pickupPrompt = findActionPrompt(serveFolder, "GetFood")
	if not pickupPrompt then
		return false
	end

	fireproximityprompt(pickupPrompt)
	waitForCondition(function()
		return getHeldFood() ~= nil
	end, PROMPT_RESULT_TIMEOUT)

	local food = getHeldFood()
	if not food and pickupPrompt.Parent then
		runBesidePrompt(pickupPrompt, function()
			fireproximityprompt(pickupPrompt)
		end, function()
			return getHeldFood() ~= nil
		end)
		food = getHeldFood()
	end

	if not food or not Farm.enabled then
		return false
	end

	return serveHeldFood(plot, food)
end

---Return whether the owned sink currently contains dirty dishes.
---@param sink Instance
---@param washPrompt ProximityPrompt
---@return boolean
local function hasDirtyDishes(sink, washPrompt)
	if washPrompt:GetAttribute("HasDishes") == true then
		return true
	end

	return sink:FindFirstChild("StackedDirty", true) ~= nil
end

---Hold the sink prompt long enough to clear one dish batch.
---@param plot Model
---@return boolean
local function washDishes(plot)
	if getHeldFood() then
		return false
	end

	local sink = plot:FindFirstChild("Sink")
	local sinkModel = sink and sink:FindFirstChild("Sink")
	local promptPart = sinkModel and sinkModel:FindFirstChild("PromptPart")
	local washPrompt = promptPart and promptPart:FindFirstChild("Wash")
	if not washPrompt or not washPrompt:IsA("ProximityPrompt") then
		return false
	end

	if not hasDirtyDishes(sinkModel, washPrompt) then
		return false
	end

	local _, rootPart = getCharacter()
	if not rootPart then
		return false
	end

	local originalCFrame = promptPart.CFrame
	local originalEnabled = washPrompt.Enabled
	local started = os.clock()
	local interrupted = false

	local ok = xpcall(function()
		promptPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
		washPrompt.Enabled = true
		task.wait()
		washPrompt:InputHoldBegin()

		while os.clock() - started < WASH_HOLD_TIME and Farm.enabled do
			local serveFolder = plot:FindFirstChild("Serve")
			if getHeldFood() or serveFolder and findActionPrompt(serveFolder, "GetFood") then
				interrupted = true
				break
			end
			task.wait(0.1)
		end

		washPrompt:InputHoldEnd()
	end, function(errorMessage)
		warn(errorMessage)
	end)

	pcall(function()
		washPrompt:InputHoldEnd()
		washPrompt.Enabled = originalEnabled
		promptPart.CFrame = originalCFrame
	end)

	return ok and not interrupted
end

---Report loop errors without flooding the console.
---@param errorMessage string
local function onFarmError(errorMessage)
	if os.clock() - Farm.lastErrorAt < 3 then
		return
	end

	Farm.lastErrorAt = os.clock()
	warn("Karinderya farm error:", errorMessage)
	warn(debug.traceback())
end

---Keep every grocery item stocked while its independent toggle is active.
---@param runId number
local function runGroceryLoop(runId)
	while Farm.groceryEnabled and not Farm.detached and Farm.groceryRunId == runId do
		xpcall(buyAllGroceries, onFarmError)
		task.wait(GROCERY_INTERVAL)
	end
end

---Watch the rotating shop stock and buy every available product.
---@param runId number
local function runShopLoop(runId)
	while Farm.shopEnabled and not Farm.detached and Farm.shopRunId == runId do
		xpcall(buyAllShopStock, onFarmError)
		task.wait(SHOP_REFRESH_INTERVAL)
	end
end

---Watch the rotating shop stock and buy only selected products.
---@param runId number
local function runSelectedShopLoop(runId)
	while Farm.selectedShopEnabled and not Farm.detached and Farm.selectedShopRunId == runId do
		xpcall(buySelectedShopStock, onFarmError)
		task.wait(SHOP_REFRESH_INTERVAL)
	end
end

---Run lightweight remote actions independently of held interactions.
---@param runId number
local function runControlLoop(runId)
	while Farm.enabled and not Farm.detached and Farm.runId == runId do
		xpcall(function()
			refillStaples()
			seatCustomer()
			hitRunaways()
		end, onFarmError)
		task.wait(CONTROL_INTERVAL)
	end
end

---Serialize serving and washing so they never fight over the character.
---@param runId number
local function runActionLoop(runId)
	while Farm.enabled and not Farm.detached and Farm.runId == runId do
		xpcall(function()
			local plot = Farm.plot
			if not plot or plot.Parent ~= workspaceService then
				return
			end

			local heldFood = getHeldFood()
			if heldFood then
				serveHeldFood(plot, heldFood)
				return
			end

			if pickupAndServe(plot) then
				return
			end

			washDishes(plot)
		end, onFarmError)
		task.wait(ACTION_INTERVAL)
	end
end

---Start or stop every farm subsystem from one switch.
---@param enabled boolean
function Farm:setEnabled(enabled)
	if self.detached or self.enabled == enabled then
		return
	end

	self.enabled = enabled
	self.runId += 1
	if not enabled then
		return
	end

	local runId = self.runId
	task.spawn(runControlLoop, runId)
	task.spawn(runActionLoop, runId)
end

---Start or stop grocery restocking without changing the main farm.
---@param enabled boolean
function Farm:setGroceryEnabled(enabled)
	if self.detached or self.groceryEnabled == enabled then
		return
	end

	self.groceryEnabled = enabled
	self.groceryRunId += 1
	if not enabled then
		return
	end

	task.spawn(runGroceryLoop, self.groceryRunId)
end

---Replace one category's product set from its multi-selection.
---@param categoryName string
---@param selectedDisplayNames table
function Farm:setShopProducts(categoryName, selectedDisplayNames)
	local selectedProducts = self.selectedShopProducts[categoryName]
	local productLookup = self.shopProductLookup[categoryName]
	if not selectedProducts or not productLookup then
		return
	end

	table.clear(selectedProducts)
	for _, displayName in ipairs(selectedDisplayNames) do
		local productKey = productLookup[displayName]
		if productKey then
			selectedProducts[productKey] = true
		end
	end
end

---Start or stop buying every available shop product.
---@param enabled boolean
function Farm:setShopEnabled(enabled)
	if self.detached or self.shopEnabled == enabled then
		return
	end

	-- Keep the purchase workers exclusive so stock is never bought twice.
	if enabled and self.selectedShopEnabled then
		self.selectedShopEnabled = false
		self.selectedShopRunId += 1
		if self.selectedShopToggle then
			self.selectedShopToggle:Set(false, true)
		end
	end

	self.shopEnabled = enabled
	self.shopRunId += 1
	if not enabled then
		return
	end

	task.spawn(runShopLoop, self.shopRunId)
end

---Start or stop buying only individually selected shop products.
---@param enabled boolean
function Farm:setSelectedShopEnabled(enabled)
	if self.detached or self.selectedShopEnabled == enabled then
		return
	end

	-- Keep the purchase workers exclusive so stock is never bought twice.
	if enabled and self.shopEnabled then
		self.shopEnabled = false
		self.shopRunId += 1
		if self.shopToggle then
			self.shopToggle:Set(false, true)
		end
	end

	self.selectedShopEnabled = enabled
	self.selectedShopRunId += 1
	if not enabled then
		return
	end

	task.spawn(runSelectedShopLoop, self.selectedShopRunId)
end

---Stop loops and remove the old interface before a re-execution.
function Farm:detach()
	if self.detached then
		return
	end

	self.detached = true
	self.enabled = false
	self.runId += 1
	self.groceryEnabled = false
	self.groceryRunId += 1
	self.shopEnabled = false
	self.shopRunId += 1
	self.selectedShopEnabled = false
	self.selectedShopRunId += 1

	if self.toggle then
		pcall(function()
			self.toggle:Set(false, true)
		end)
	end

	if self.groceryToggle then
		pcall(function()
			self.groceryToggle:Set(false, true)
		end)
	end

	if self.shopToggle then
		pcall(function()
			self.shopToggle:Set(false, true)
		end)
	end

	if self.selectedShopToggle then
		pcall(function()
			self.selectedShopToggle:Set(false, true)
		end)
	end

	if self.window then
		pcall(function()
			if type(self.window.Destroy) == "function" then
				self.window:Destroy()
			elseif type(self.window.Unload) == "function" then
				self.window:Unload()
			end
		end)
	end
end

---Initialize the singleton and its Rayfield Gen2 controls.
local function initializeScript()
	if game.PlaceId ~= TARGET_PLACE_ID then
		error("This script only supports Karinderya.")
	end

	if shared.PotentKarinderyaFarm then
		shared.PotentKarinderyaFarm:detach()
	end

	shared.PotentKarinderyaFarm = Farm

	local source = requestSource(RAYFIELD_URL)
	local chunk, compileError = loadstring(source, "RayfieldGen2")
	if not chunk then
		error(compileError)
	end

	local Rayfield = chunk()
	local window = Rayfield:CreateWindow({
		name = "Potent Karinderya",
		subtitle = "Auto Farm",
		sidebarLayout = false,
		fallbackFont = Enum.Font.Gotham,
	})
	local farmTab = window:CreateTab({
		name = "Farm",
	})
	local shopTab = window:CreateTab({
		name = "Shop",
		icon = "shopping-cart",
	})
	local shopProductOptions = buildShopProductCatalog()

	Farm.window = window
	Farm.toggle = farmTab:CreateToggle({
		name = "Auto Farm",
		description = "Seats, serves, washes dishes, and handles runaways.",
		value = false,
		flag = "PotentKarinderyaAutoFarm",
		forgetState = true,
		callback = function(value)
			Farm:setEnabled(value)
		end,
	})

	Farm.groceryToggle = farmTab:CreateToggle({
		name = "Auto Buy All Grocery",
		description = "Keeps every available ingredient filled to its stock limit.",
		value = false,
		flag = "AutoBuyAllGrocery",
		forgetState = true,
		callback = function(value)
			Farm:setGroceryEnabled(value)
		end,
	})

	for _, categoryName in ipairs(SHOP_CATEGORIES) do
		local currentCategory = categoryName
		Farm.shopDropdowns[currentCategory] = shopTab:CreateDropdown({
			name = currentCategory,
			description = "Select " .. currentCategory:lower() .. " to purchase.",
			options = shopProductOptions[currentCategory],
			value = {},
			multiSelect = true,
			forgetState = true,
			callback = function(selectedDisplayNames)
				Farm:setShopProducts(currentCategory, selectedDisplayNames)
			end,
		})
	end

	local shopToggleRow = shopTab:CreateGroup({
		direction = "row",
	})
	Farm.shopToggle = shopToggleRow:CreateToggle({
		name = "Auto Buy",
		value = false,
		forgetState = true,
		callback = function(value)
			Farm:setShopEnabled(value)
		end,
	})
	Farm.selectedShopToggle = shopToggleRow:CreateToggle({
		name = "Auto Buy Selected Product",
		value = false,
		forgetState = true,
		callback = function(value)
			Farm:setSelectedShopEnabled(value)
		end,
	})

	-- Cancel any state Rayfield retained from an earlier window.
	Farm.enabled = false
	Farm.runId += 1
	Farm.groceryEnabled = false
	Farm.groceryRunId += 1
	Farm.shopEnabled = false
	Farm.shopRunId += 1
	Farm.selectedShopEnabled = false
	Farm.selectedShopRunId += 1
	Farm.toggle:Set(false, true)
	Farm.groceryToggle:Set(false, true)
	for _, categoryName in ipairs(SHOP_CATEGORIES) do
		table.clear(Farm.selectedShopProducts[categoryName])
		Farm.shopDropdowns[categoryName]:Set({}, true)
	end
	Farm.shopToggle:Set(false, true)
	Farm.selectedShopToggle:Set(false, true)

	farmTab:CreateButton({
		name = "Stop Farm",
		callback = function()
			Farm.toggle:Set(false)
		end,
	})

	if reloadState and type(reloadState.onCleanup) == "function" then
		reloadState.onCleanup(function()
			Farm:detach()
		end)
	end
end

---This is called when initialization errors.
---@param errorMessage string
local function onInitializeError(errorMessage)
	warn("Failed to initialize Karinderya Auto Farm.")
	warn(errorMessage)
	warn(debug.traceback())
	Farm:detach()
end

-- Safely initialize the script and clean up if startup fails.
xpcall(initializeScript, onInitializeError)
