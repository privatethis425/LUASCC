-- TSB Ultra Baseplate Optimizer (smooth/event-driven edition) - camera/anim-safe fix
-- Performs the expensive cleanup once in small chunks, then handles only new objects.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local CONFIG = {
    -- Avatars (clothes, accessories, martial artist FX/streaks, camera anim)
    -- must stay untouched. Only the map/world gets optimized.
    deleteAccessories = false,
    deleteCharacterVfx = true,
    deleteTreesByShapeAndColor = true,
    deleteMapDecor = true,
    deleteTexturesAndMeshes = true,
    flattenRemainingMap = true,

    batchSize = 70,
    frameBudgetSeconds = 0.0015,

    -- Fallen-object sweep: catches dead ragdoll limbs, dropped tools, and
    -- knocked-off debris that pile up mid-match and don't get caught by the
    -- DescendantAdded queue alone. This is the main low-end lag source.
    sweepFallenDebris = true,
    fallenSweepInterval = 1.5,
    fallenSweepBatchSize = 40,
    fallenYThreshold = -25,
    unanchoredIdleSeconds = 4,
}

local environment = _G
pcall(function()
    if type(getgenv) == "function" then
        environment = getgenv()
    end
end)

local oldController = environment.__TSB_ULTRA_OPTIMIZER
if type(oldController) == "table" and type(oldController.stop) == "function" then
    pcall(oldController.stop)
end

local controller = {
    running = true,
    connections = {},
}
environment.__TSB_ULTRA_OPTIMIZER = controller

local counters = {
    deleted = 0,
    flattened = 0,
    disabled = 0,
    processed = 0,
}

local removed = setmetatable({}, { __mode = "k" })
local processed = setmetatable({}, { __mode = "k" })
local queued = setmetatable({}, { __mode = "k" })
local idleSince = setmetatable({}, { __mode = "k" })
local lastCFrame = setmetatable({}, { __mode = "k" })

local queue = {}
local queueHead = 1
local queueTail = 0

-- Never touch these: destroying/mutating them is what broke camera shake and
-- limb animation before (rig linkage + camera-attached FX rely on them).
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

local NAME_KILL_WORDS = {
    "tree", "leaf", "leaves", "branch", "bush", "grass", "plant", "foliage",
    "trunk", "wood", "log", "palm", "shrub", "vine",
    "effect", "effects", "vfx", "fx", "particle", "particles", "trail", "beam",
    "smoke", "dust", "debris", "rubble", "shockwave", "slash", "impact", "explosion",
    "aura", "spark", "ring", "wind", "afterimage", "hitfx",
    "rock", "crate", "barrel", "bench", "chair", "table", "lamp", "sign", "fence",
    "prop", "decor", "decoration", "detail", "garbage", "trash",
}

local KEEP_WORDS = {
    "baseplate", "base", "floor", "ground", "road", "street", "sidewalk", "spawn",
    "arena", "platform", "plate", "safezone",
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

local ACCESSORY_CLASSES = {
    Accessory = true,
    Hat = true,
    Accoutrement = true,
    ShirtGraphic = true,
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(controller.connections, connection)
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

    if environment.__TSB_ULTRA_OPTIMIZER == controller then
        environment.__TSB_ULTRA_OPTIMIZER = nil
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

local function isCharacterModel(instance)
    return instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") ~= nil
end

local function characterOwner(instance)
    local model = instance:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return Players:GetPlayerFromCharacter(model), model
    end
    return nil, nil
end

local function isUnderCamera(instance)
    local camera = Workspace.CurrentCamera
    return camera ~= nil and instance:IsDescendantOf(camera)
end

local function isLocalPlayerCharacter(instance)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    if not character then
        return false
    end
    return instance == character or instance:IsDescendantOf(character)
end

local function isPlayerOwned(instance)
    for _, player in ipairs(Players:GetPlayers()) do
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

local function characterIsMartialArtist(character)
    if not character then
        return false
    end

    -- In this farm, TSB's Martial Artist is the "Purple" character.
    local classAttribute = character:GetAttribute("Character")
    if type(classAttribute) == "string" then
        local lowered = string.lower(classAttribute)
        if lowered == "purple" or lowered == "martial artist" or lowered == "martialartist" then
            return true
        end
    end

    local classValue = character:FindFirstChild("Class")
    if classValue and classValue:IsA("StringValue") then
        local lowered = string.lower(classValue.Value)
        if lowered == "martial artist" or lowered == "martialartist" then
            return true
        end
    end

    return string.find(string.lower(character.Name), "martial artist", 1, true) ~= nil
end

local LocalPlayer = Players.LocalPlayer

local function isLocalMartialArtistActive()
    local character = LocalPlayer and LocalPlayer.Character
    return character ~= nil and characterIsMartialArtist(character)
end

local function isDirectLocalMartialArtistObject(instance)
    local character = LocalPlayer and LocalPlayer.Character
    if not character or not characterIsMartialArtist(character) then
        return false
    end
    return instance == character or instance:IsDescendantOf(character)
end

local function hasLocalOwnerMetadata(instance)
    if not isLocalMartialArtistActive() then
        return false
    end

    local character = LocalPlayer.Character
    local cursor = instance
    local depth = 0
    while cursor and depth < 7 do
        depth += 1

        for _, attrName in ipairs({ "Owner", "Creator", "Player", "PlayerName" }) do
            local value = cursor:GetAttribute(attrName)
            if type(value) == "string" and value == LocalPlayer.Name then
                return true
            end
        end

        for _, attrName in ipairs({ "UserId", "OwnerUserId", "CreatorUserId" }) do
            local value = cursor:GetAttribute(attrName)
            if tonumber(value) == LocalPlayer.UserId then
                return true
            end
        end

        for _, valueName in ipairs({ "Owner", "Creator", "Player", "Character" }) do
            local valueObject = cursor:FindFirstChild(valueName)
            if valueObject and valueObject:IsA("ObjectValue") then
                if valueObject.Value == LocalPlayer or valueObject.Value == character then
                    return true
                end
            end
        end

        cursor = cursor.Parent
    end

    return false
end

local function isProtectedMartialArtistEffect(instance)
    return isDirectLocalMartialArtistObject(instance) or hasLocalOwnerMetadata(instance)
end

local ULT_KEEP_WORDS = {
    "ult", "ultimate", "dragon", "skill", "burst", "awaken", "transform",
    "unleash", "phoenix", "beast", "titan", "summon",
}

local function isStreakOrSkillRelated(instance)
    local name = string.lower(instance.Name)
    if string.find(name, "streak", 1, true) or string.find(name, "combo", 1, true) then
        return true
    end
    if instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("ScreenGui") then
        return true
    end
    -- Anything nested inside a BillboardGui/SurfaceGui/ScreenGui (the
    -- TextLabel/Frame/ImageLabel that actually renders the streak number)
    -- must be protected too - only checking the GUI root let its children
    -- slip through and get disabled/destroyed when the GUI wasn't parented
    -- directly under a character.
    if instance:FindFirstAncestorWhichIsA("BillboardGui")
        or instance:FindFirstAncestorWhichIsA("SurfaceGui")
        or instance:FindFirstAncestorWhichIsA("ScreenGui") then
        return true
    end
    -- TSB's killstreak counter lives as a standalone tree
    -- (Workspace.Cutscenes.Billboard.Killstreak) that isn't parented under
    -- any character, so isPlayerOwned never protects it. Walk every
    -- ancestor by name so the whole Cutscenes/Billboard/Killstreak chain,
    -- and anything nested inside it, is whitelisted regardless of depth.
    local ancestor = instance
    while ancestor do
        local ancestorName = string.lower(ancestor.Name)
        if string.find(ancestorName, "streak", 1, true)
            or string.find(ancestorName, "combo", 1, true)
            or ancestorName == "cutscenes" then
            return true
        end
        ancestor = ancestor.Parent
    end
    -- Ult/skill VFX (e.g. dragon summon models) often spawn as free-standing
    -- Workspace models, not parented to a character. Whitelist by name so
    -- they never get treated as map decor/trees and disabled or destroyed.
    if nameHas(instance, ULT_KEEP_WORDS) then
        return true
    end
    local parentModel = instance:FindFirstAncestorOfClass("Model")
    if parentModel and nameHas(parentModel, ULT_KEEP_WORDS) then
        return true
    end
    return false
end

local function isLocalPlayerCharacter(instance)
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return false
    end
    return instance == character or instance:IsDescendantOf(character)
end

local function isCoreCharacterPart(instance)
    -- Hard protections that fix the camera/animation breakage.
    if PROTECTED_CLASSES[instance.ClassName] then
        return true
    end
    if isUnderCamera(instance) then
        return true
    end
    if instance:FindFirstAncestorWhichIsA("Tool") then
        return true
    end
    -- Preserve every object/effect belonging to the LOCAL Martial Artist only.
    -- Other characters still keep their rig, joints and humanoid, but their VFX
    -- are allowed to fall through to the cleanup path.
    if isProtectedMartialArtistEffect(instance) then
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
    if not instance or removed[instance] or instance == Workspace.CurrentCamera then
        return false
    end

    if isProtectedMartialArtistEffect(instance) then
        return false
    end

    if isCoreCharacterPart(instance) then
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
    if isProtectedMartialArtistEffect(instance) then
        return false
    end
    if not VFX_CLASSES[instance.ClassName] then
        return false
    end

    -- Camera-attached lights/highlights (e.g. hit-flash, shake-linked effects)
    -- get disabled but NOT destroyed, so the camera script doesn't error
    -- reaching for a missing instance mid-animation.
    if isUnderCamera(instance) then
        pcall(function()
            if instance:IsA("ParticleEmitter")
                or instance:IsA("Trail")
                or instance:IsA("Beam")
                or instance:IsA("Smoke")
                or instance:IsA("Fire")
                or instance:IsA("Sparkles")
                or instance:IsA("PostEffect") then
                instance.Enabled = false
            elseif instance:IsA("Explosion") then
                instance.Visible = false
            end
        end)
        counters.disabled += 1
        return false
    end

    pcall(function()
        if instance:IsA("ParticleEmitter")
            or instance:IsA("Trail")
            or instance:IsA("Beam")
            or instance:IsA("Smoke")
            or instance:IsA("Fire")
            or instance:IsA("Sparkles")
            or instance:IsA("PostEffect") then
            instance.Enabled = false
        elseif instance:IsA("Explosion") then
            instance.Visible = false
        end
    end)

    counters.disabled += 1
    return safeDestroy(instance)
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
    local flatLargeSurface = size.Y <= 3 and size.X >= 18 and size.Z >= 18
    local lowGroundLayer = part.Position.Y <= 3 and size.X >= 8 and size.Z >= 8
    return flatLargeSurface or lowGroundLayer
end

local function setIfDifferent(instance, property, value)
    pcall(function()
        if instance[property] ~= value then
            instance[property] = value
        end
    end)
end

local function flattenMapPart(part)
    setIfDifferent(part, "Material", Enum.Material.SmoothPlastic)
    setIfDifferent(part, "Color", Color3.fromRGB(135, 135, 135))
    setIfDifferent(part, "Reflectance", 0)
    setIfDifferent(part, "CastShadow", false)
    counters.flattened += 1
end

local function stripMeshWeight(instance)
    if not CONFIG.deleteTexturesAndMeshes then
        return
    end
    if isUnderCamera(instance) then
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

local CHARACTER_EFFECT_WORDS = {
    "effect", "effects", "vfx", "fx", "particle", "particles", "trail", "beam",
    "aura", "spark", "shockwave", "slash", "impact", "explosion", "afterimage",
    "wind", "smoke", "dust", "debris", "rubble", "flash", "glow", "ring",
    "burst", "energy", "hitfx", "skillfx",
}

local function looksLikeCharacterEffect(item)
    if VFX_CLASSES[item.ClassName] then
        return true
    end

    if not (item:IsA("BasePart") or item:IsA("Model") or item:IsA("Folder")) then
        return false
    end

    local lowered = string.lower(item.Name)
    for _, word in ipairs(CHARACTER_EFFECT_WORDS) do
        if string.find(lowered, word, 1, true) then
            return true
        end
    end
    return false
end

local function cleanCharacterItem(item)
    -- Keep the local Martial Artist ("Purple") visually untouched.
    if isProtectedMartialArtistEffect(item) then
        return
    end

    -- Never damage a character rig. Only strip visuals/effect containers.
    if isCoreCharacterPart(item) then
        if item:IsA("BasePart") then
            setIfDifferent(item, "CastShadow", false)
        end
        return
    end

    if VFX_CLASSES[item.ClassName] then
        disableAndDestroyVisual(item)
        return
    end

    if looksLikeCharacterEffect(item) then
        safeDestroy(item)
        return
    end

    if item:IsA("BasePart") then
        setIfDifferent(item, "CastShadow", false)
    end
end

local function cleanLighting()
    setIfDifferent(Lighting, "GlobalShadows", false)
    setIfDifferent(Lighting, "EnvironmentDiffuseScale", 0)
    setIfDifferent(Lighting, "EnvironmentSpecularScale", 0)
    setIfDifferent(Lighting, "Brightness", 1)
    setIfDifferent(Lighting, "ClockTime", 14)
    setIfDifferent(Lighting, "FogStart", 100000)
    setIfDifferent(Lighting, "FogEnd", 100000)
    setIfDifferent(Lighting, "Ambient", Color3.fromRGB(180, 180, 180))
    setIfDifferent(Lighting, "OutdoorAmbient", Color3.fromRGB(180, 180, 180))

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
            safeDestroy(child)
        else
            disableAndDestroyVisual(child)
        end
    end
end

local function cleanTerrain()
    if not Terrain then
        return
    end

    setIfDifferent(Terrain, "Decoration", false)
    setIfDifferent(Terrain, "WaterReflectance", 0)
    setIfDifferent(Terrain, "WaterTransparency", 1)
    setIfDifferent(Terrain, "WaterWaveSize", 0)
    setIfDifferent(Terrain, "WaterWaveSpeed", 0)
end

local function shouldDeleteContainer(instance)
    if isCharacterModel(instance) then
        return false
    end

    if instance == Workspace or instance == Workspace.CurrentCamera then
        return false
    end

    if isUnderCamera(instance) then
        return false
    end

    if instance:FindFirstAncestorWhichIsA("Tool") then
        return false
    end

    if isProtectedMartialArtistEffect(instance) then
        return false
    end

    -- Killstreak/combo counter tree must never be deleted as "decor".
    if isStreakOrSkillRelated(instance) then
        return false
    end

    return CONFIG.deleteMapDecor and nameHas(instance, NAME_KILL_WORDS)
end

local function isFallenDebrisPart(part)
    if not part:IsA("BasePart") or part.Anchored then
        return false
    end
    if isCoreCharacterPart(part) or isProtectedMartialArtistEffect(part) then
        return false
    end
    if isUnderCamera(part) or part:FindFirstAncestorWhichIsA("Tool") then
        return false
    end
    if characterOwner(part) or isPlayerOwned(part) then
        return false
    end

    -- Fell below the map/kill-Y, or has sat unanchored and motionless long
    -- enough that it's clearly settled debris rather than active physics.
    local fellBelowMap = part.Position.Y < CONFIG.fallenYThreshold
    if fellBelowMap then
        return true
    end

    local cf = part.CFrame
    local prev = lastCFrame[part]
    lastCFrame[part] = cf

    if prev and (prev.Position - cf.Position).Magnitude < 0.05 then
        local since = idleSince[part]
        if not since then
            idleSince[part] = os.clock()
        elseif os.clock() - since >= CONFIG.unanchoredIdleSeconds then
            return true
        end
    else
        idleSince[part] = nil
    end

    return false
end

local fallenSweepIndex = 1

local function sweepFallenDebris()
    if not CONFIG.sweepFallenDebris then
        return
    end

    local descendants = Workspace:GetDescendants()
    local total = #descendants
    if total == 0 then
        return
    end

    if fallenSweepIndex > total then
        fallenSweepIndex = 1
    end

    local processedCount = 0
    while processedCount < CONFIG.fallenSweepBatchSize and fallenSweepIndex <= total do
        local part = descendants[fallenSweepIndex]
        fallenSweepIndex += 1
        processedCount += 1

        if part and part.Parent ~= nil and isFallenDebrisPart(part) then
            safeDestroy(part)
        end
    end
end

local function cleanInstance(instance)
    if not instance or removed[instance] or processed[instance] or instance.Parent == nil then
        return
    end

    -- Only the local Martial Artist is fully exempt from visual cleanup.
    if isProtectedMartialArtistEffect(instance) then
        return
    end

    processed[instance] = true
    counters.processed += 1

    -- Killstreak/combo GUIs must stay visible above every player, not just
    -- the local Martial Artist, so this check is unconditional.
    if isStreakOrSkillRelated(instance) then
        return
    end

    if isUnderCamera(instance) then
        -- Only disable visuals here; never destroy or restyle camera-owned
        -- instances, since scripts often assume they persist for the whole
        -- animation/shake lifecycle.
        disableAndDestroyVisual(instance)
        return
    end

    local _, character = characterOwner(instance)
    if character then
        cleanCharacterItem(instance)
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
    if isProtectedMartialArtistEffect(instance) then
        return
    end

    queued[instance] = true
    queueTail += 1
    queue[queueTail] = instance
end

local function enqueueTree(root)
    if not root then
        return
    end

    enqueue(root)
end

local function freeZoom()
    pcall(function()
        LocalPlayer.CameraMaxZoomDistance = 400
        LocalPlayer.CameraMinZoomDistance = 0.5
    end)
end

freeZoom()
connect(RunService.Heartbeat, freeZoom)

cleanLighting()
cleanTerrain()

-- Seed only the top level. Children are discovered gradually by the frame queue.
for _, instance in ipairs(Workspace:GetChildren()) do
    -- Skip queuing the camera tree entirely; it's handled passively via the
    -- isUnderCamera guard so nothing there is ever destroyed.
    if instance ~= Workspace.CurrentCamera then
        enqueue(instance)
    end
end

connect(Workspace.DescendantAdded, enqueue)

task.spawn(function()
    while controller.running do
        task.wait(CONFIG.fallenSweepInterval)
        if controller.running then
            sweepFallenDebris()
        end
    end
end)
connect(Lighting.DescendantAdded, function(instance)
    if instance:IsA("Sky") or instance:IsA("Atmosphere") or instance:IsA("Clouds") then
        safeDestroy(instance)
    else
        disableAndDestroyVisual(instance)
    end
end)

connect(Players.PlayerAdded, function(player)
    connect(player.CharacterAdded, enqueueTree)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        enqueueTree(player.Character)
    end
    connect(player.CharacterAdded, function(character)
        enqueueTree(character)
    end)
end

connect(RunService.Heartbeat, function()
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

print("[TSB Ultra Baseplate Optimizer] smooth mode active; non-Martial VFX stripped, local Purple preserved")
