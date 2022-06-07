--[[Dependencies]]--
getgenv().raw = loadstring(game:HttpGet("https://raw.githubusercontent.com/KitesBackup/Project-Rose/main/raw%20lib.lua"))() -- raw library
local Maid = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/a8a2d2c1ffcf6288ec8d66f65cea593061ba2cf0/Modules/Shared/Events/Maid.lua"))() -- maid system
local MainMaid = Maid.new()

local GetService = setmetatable({},
    {__index = function(self, Key)
        return getgenv().game:GetService(Key)
    end
})

local Workspace = GetService.Workspace
local Players = GetService.Players
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local ReplicatedFirst = GetService.ReplicatedFirst
local ReplicatedStorage = GetService.ReplicatedStorage

local ServerScriptService = GetService.ServerScriptService
local ServerStorage = GetService.ServerStorage

local StarterGui = GetService.StarterGui
local StarterPack = GetService.StarterPack
local StarterPlayer = GetService.StarterPlayer
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local StarterCharacterScripts = StarterPlayer:WaitForChild("StarterCharacterScripts")

local HttpService = GetService.HttpService
local RunService = GetService.RunService
local TweenService = GetService.TweenService
local UserInputService = GetService.UserInputService

local ContentProvider = GetService.ContentProvider
local Stats = GetService.Stats

local CurrentCamera = Workspace.CurrentCamera
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint
local IsDescendantOf = Instance.new("Part").IsDescendantOf
local FindFirstChildWhichIsA = Instance.new("Part").FindFirstChildWhichIsA
local FindFirstChild = Instance.new("Part").FindFirstChild
local Raycast = Workspace.Raycast

--[[Module]]--
if getgenv().ScriptExecuted then
    return coroutine.yield()
end
getgenv().ScriptExecuted = true

local CThread
do
    local wrap = coroutine.wrap
    CThread = function(_Function, ...)
        if (type(_Function) ~= 'function') then
            return nil
        end
        local Varag = ...
        return function()
            local Success, Ret = pcall(wrap(_Function, Varag))
            if (Success) then
                return Ret
            end
            if (Debug) then
                warn("[Error]: " .. debug.traceback(Ret))
            end
        end
    end
end

getgenv().thread = function(_Function)
    return spawn(function() 
        if syn and is_synapse_function then
            syn.set_thread_identity(7)
        end
        return _Function()
    end)
end

local Objects = setmetatable({}, {__mode = "kv"})
Objects.AddToTable = function(Table, Instance)
    return table.insert(Table, Instance)
end

Objects.RemoveFromTable = function(Table, Instance)
    return table.remove(Table, Instance)
end

local Connections = setmetatable({}, {__mode = "v"})
local function GetParents(Instance)
	local Parent, Parents = Instance, {}
    repeat
        Parent = raw.get(Parent, "Parent")
        Parents[#Parents+1] = Parent
    until not Parent
    return Parents
end

local function SetParent(Instance, Destination)
    pcall(function()
        local Parents = {
            [Destination] = true
        }
        for _,Parent in pairs(GetParents(Destination)) do
            Parents[Parent] = true
        end
        for _,Parent in pairs(GetParents(Instance)) do
            Parents[Parent] = true
        end
        local Connections = {}
        for Parent,_ in pairs(Parents) do
            Connections[#Connections+1] = getconnections(raw.get(Parent, "DescendantAdded"))
            Connections[#Connections+1] = getconnections(raw.get(Parent, "ChildAdded"))
            Connections[#Connections+1] = getconnections(raw.get(Parent, "DescendantRemoving"))
            Connections[#Connections+1] = getconnections(raw.get(Parent, "ChildRemoved"))
        end
        local DisabledSignals = {}
        for _,Signals in pairs(Connections) do
            for _,Signal in pairs(Signals) do
                if Signal.Enabled == true and Signal.Function ~= nil and is_synapse_function(Signal.Function) == false then
                    DisabledSignals[#DisabledSignals+1] = Signal
                    Signal:Disable()
                end
            end
        end
        raw.set(Instance, "Parent", Destination)
        for _,Signal in pairs(DisabledSignals) do
            Signal:Enable()
        end
    end)
end

local WhitelistedLimbs = {
    All = {
        "Head",
        "HumanoidRootPart",
        "Torso",
        "Left Arm",
        "Right Arm",
        "Left Leg",
        "Right Leg"
    },
    Low = {
        "Head",
        "HumanoidRootPart",
        "Torso",
        "Left Arm",
        "Right Arm",
        "Left Leg"
    },
    High = {
        "Head",
        "HumanoidRootPart",
        "Torso",
        "Left Arm",
        "Right Arm"
    }
}

local VisualizerIndex = {}
VisualizerIndex.__index = VisualizerIndex

local Chroma
if Settings.Chroma ~= "Rainbow" then
    Chroma = Settings.Chroma
else
    Chroma = Color3.fromRGB(255, 255, 255)
end

VisualizerIndex.VisualizerProperties = {
    Name = HttpService:GenerateGUID(true),
    Size = Vector3.new(Settings.Size),
    Shape = Enum.PartType[Settings.Shape],
    Color = Chroma,
    Material = Enum.Material.ForceField,
    Transparency = -1.75,
    Massless = true,
    Anchored = false,
    CanCollide = false,
    CastShadow = false,
    TopSurface = Enum.SurfaceType.Smooth,
    BottomSurface = Enum.SurfaceType.Smooth
}

VisualizerIndex.WeldProperties = {
    Name = HttpService:GenerateGUID(true)
}

function VisualizerIndex:Create(Class, Properties)
    self._Instance = Class
    if type(Class) == "string" and typeof(Properties) == "table" then
        self._Instance = Instance.new(Class)
    end
    for Property, Value in next, Properties do
        self._Instance[Property] = Value
    end
    return self._Instance
end

function VisualizerIndex:Update(_Instance, Property, Value)
    self._Instance = _Instance
    if typeof(self._Instance) == "Instance" then
        if (Property ~= "Parent") then
            self._Instance[Property] = Value
        else
            coroutine.wrap(SetParent)(self._Instance, Value)
        end
    end
end

local Visualizer = VisualizerIndex:Create("Part", VisualizerIndex.VisualizerProperties)
local Weld = VisualizerIndex:Create("Weld", VisualizerIndex.WeldProperties)

local function IncrementRainbow(_Instance)
    local RainbowValue = 0
    local function Rainbow(x)
        return math.acos(math.cos(x * math.pi)) / math.pi
    end
    while wait() do
        _Instance.Color = Color3.fromHSV(Rainbow(RainbowValue), 1, 1)
        RainbowValue = RainbowValue + 0.01
    end
end

local Shapes = {"Block", "Ball", "Wall", "Cylinder"}
local CurrentShape = nil
local function IncrementShape()
    local NextShape = next(Shapes, CurrentShape)
    CurrentShape = NextShape
    if not NextShape then
        return IncrementShape()
    end
    if CurrentShape == 1 then
        Settings.Shape = "Block"
    elseif CurrentShape == 2 then
        Settings.Shape = "Ball"
    elseif CurrentShape == 3 then
        Settings.Shape = "Wall"
    elseif CurrentShape == 4 then
        Settings.Shape = "Cylinder"
    end
    return Shape
end

local FakeHandleProperties = {
    --Name = "Handle",--
    Name = "Right Arm",
    Size = Vector3.new(1, 2, 1)
}

local FakeHandle = VisualizerIndex:Create("Part", FakeHandleProperties)
pcall(function()
    if Objects then
        Objects.AddToTable(Objects, FakeHandle)
    end
end)
GHandle = Objects[FakeHandle]

local function GetCharacter(Player)
    local Living = {}
    if Player and Player.Character then
        local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart")
        if Humanoid then
            if Humanoid.Health > 0 and HumanoidRootPart and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                if Settings.HealthChecks then
                    if Humanoid.Health < 110 then
                        if Humanoid.WalkSpeed < 20 then
                            Living[Player.Character] = true
                        end
                    end
                else
                    Living[Player.Character] = true
                end
            elseif Humanoid.Health > 0 and not HumanoidRootPart then
                local Connection
                Connection = Player.Character.ChildAdded:Connect(function(Child)
                    if Child:IsA("Part") and Child.Name == "HumanoidRootPart" then
                        Living[Player.Character] = true
                        Connection:Disconnect()
                        Connection = nil
                    else
                        Living[Player.Character] = false
                    end
                end)
            end
        end
        for _,Limb in next, WhitelistedLimbs.All do
            if not Player.Character:FindFirstChild(Limb) then
                Living[Player.Character] = false
            end
        end
        if Living[Player.Character] then
            return (Player.Character)
        end
    end
end

local function GetClosestPlayer(Handle)
    local ClosestDistance, ClosestPlayer = math.huge
    for _,Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer then
            local Character = GetCharacter(Player)
            local LocalCharacter = GetCharacter(LocalPlayer)
            if Character and LocalCharacter then
                local Distance
                if Settings.Position == "Sword" then
                    Distance = (Handle.Position - Character:WaitForChild("HumanoidRootPart").Position).Magnitude
                elseif Settings.Position == "HumanoidRootPart" then
                    Distance = (LocalCharacter:WaitForChild("HumanoidRootPart").Position - Character:WaitForChild("HumanoidRootPart").Position).Magnitude
                end
                local MaxDistance = Settings.DamageAmpSettings.MaximumDamageDistance
                if Distance < ClosestDistance then
                    if Settings.DamageAmp then
                        if Distance < MaxDistance then
                            ClosestDistance = Distance
                            ClosestPlayer = Player
                        end
                    else
                        ClosestDistance = Distance
                        ClosestPlayer = Player
                    end
                end
            end
        end
    end
    return ClosestPlayer, ClosestDistance
end

local Task = 0
Connections[#Connections+1] = MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    local Sword = GetCharacter(LocalPlayer) and GetCharacter(LocalPlayer):FindFirstChildOfClass("Tool")
    if Sword then
        local Handle = Sword:FindFirstChild("Handle")
        if Handle and GetCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid").Health > 0 then
            if Settings.Visible and VisualizerIndex then
                if Task == 0 then
                    if Settings.Chroma == "Rainbow" and Visualizer then
                        coroutine.wrap(IncrementRainbow)(Visualizer)
                    end
                    Task += 1
                end
                MainMaid.VisualizerIndex = VisualizerIndex
                MainMaid.VisualizerIndex:Update(Weld, "Parent", Visualizer)
                MainMaid.VisualizerIndex:Update(Weld, "Part0", Visualizer)
                MainMaid.VisualizerIndex:Update(Visualizer, "Parent", Workspace.CurrentCamera)
                if Settings.Shape ~= "Wall" then
                    MainMaid.VisualizerIndex:Update(Visualizer, "Shape", Settings.Shape)
                else
                    MainMaid.VisualizerIndex:Update(Visualizer, "Shape", Enum.PartType.Block)
                end
                if Settings.Position == "Sword" then
                    MainMaid.VisualizerIndex:Update(Weld, "Part1", Handle)
                    MainMaid.VisualizerIndex:Update(Visualizer, "Position", Handle.Position)
                    MainMaid.VisualizerIndex:Update(Visualizer, "CFrame", Handle.CFrame)
                    MainMaid.VisualizerIndex:Update(Visualizer, "Orientation", Handle.Orientation)
                    if type(Settings.Size) == "number" then
                        if Settings.Shape == "Wall" then
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Vector3.new(Settings.Size, 0.8, Settings.Size))
                        else
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Vector3.new(Settings.Size, Settings.Size, Settings.Size))
                        end
                    elseif typeof(Settings.Size) == "Vector3" then
                        if Settings.Shape == "Wall" then
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Vector3.new(Settings.Size.X, 0.8, Settings.Size.Z))
                        else
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Settings.Size)
                        end
                    end
                elseif Settings.Position == "HumanoidRootPart" then
                    MainMaid.VisualizerIndex:Update(Weld, "Part1", GetCharacter(LocalPlayer):WaitForChild("HumanoidRootPart"))
                    MainMaid.VisualizerIndex:Update(Visualizer, "Position", GetCharacter(LocalPlayer):WaitForChild("HumanoidRootPart").Position)
                    MainMaid.VisualizerIndex:Update(Visualizer, "CFrame", GetCharacter(LocalPlayer):WaitForChild("HumanoidRootPart").CFrame)
                    MainMaid.VisualizerIndex:Update(Visualizer, "Orientation", GetCharacter(LocalPlayer):WaitForChild("HumanoidRootPart").Orientation)
                    if type(Settings.Size) == "number" then
                        if Settings.Shape == "Wall" then
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Vector3.new(0.8, Settings.Size, Settings.Size))
                        else
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Vector3.new(Settings.Size, Settings.Size, Settings.Size))
                        end
                    elseif typeof(Settings.Size) == "Vector3" then
                        if Settings.Shape == "Wall" then
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Vector3.new(0.8, Settings.Size.Y, Settings.Size.Z))
                        else
                            MainMaid.VisualizerIndex:Update(Visualizer, "Size", Settings.Size)
                        end
                    end
                end
            elseif not Settings.Visible and VisualizerIndex and Visualizer then
                Visualizer.Parent = nil
            end
        else
            if VisualizerIndex and Visualizer then
                Visualizer.Parent = nil
            end
        end
    else
        if VisualizerIndex and Visualizer then
            Visualizer.Parent = nil
        end
    end
end))

local Array = {
    Vector3.new(1, 1, 1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, -1, -1),
    Vector3.new(1, -1, -1)
}

local function GetCorners(CFrame, Size)
	return {
		CFrame:PointToWorldSpace(Vector3.new(-Size.x, Size.y, Size.z));
		CFrame:PointToWorldSpace(Vector3.new(-Size.x, -Size.y, Size.z));
		CFrame:PointToWorldSpace(Vector3.new(-Size.x, -Size.y, -Size.z));
		CFrame:PointToWorldSpace(Vector3.new(Size.x, -Size.y, -Size.z));
		CFrame:PointToWorldSpace(Vector3.new(Size.x, Size.y, -Size.z));
		CFrame:PointToWorldSpace(Vector3.new(Size.x, Size.y, Size.z));
		CFrame:PointToWorldSpace(Vector3.new(Size.x, -Size.y, Size.z));
		CFrame:PointToWorldSpace(Vector3.new(-Size.x, Size.y, -Size.z));
	}
end

local function VertShape(CFrame, Size)
    local output = {}
    for i = 1, #Array do
        output[i] = CFrame * (Array[i] * Size)
    end
    return output
end

local function WorldBoundingBox(CFrame, Size)
    local Set = VertShape(CFrame, Size)
    local x, y, z = {}, {}, {}
    for i = 1, #Set do 
        x[i], y[i], z[i] = Set[i].x, Set[i].y, Set[i].z 
    end
    local min = Vector3.new(math.min(unpack(x)), math.min(unpack(y)), math.min(unpack(z)))
    local max = Vector3.new(math.max(unpack(x)), math.max(unpack(y)), math.max(unpack(z)))
    return Region3.new(min, max)
end

local function CheckPartVisibility(Part, PartDescendant)
    local Character = LocalPlayer.Character or GetCharacter(LocalPlayer)
    local Origin = CurrentCamera.CFrame.Position
    local _,OnScreen = WorldToViewportPoint(CurrentCamera, Part.Position)
    if (OnScreen) then
        local RaycastParams = RaycastParams.new()
        RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        RaycastParams.FilterDescendantsInstances = {Character, CurrentCamera}
        local Result = Raycast(Workspace, Origin, Part.Position - Origin, RaycastParams)
        if (Result) then
            local PartHit = Result.Instance
            local Visible = (not PartHit or IsDescendantOf(PartHit, PartDescendant))
            return Visible
        end
    end
    return false
end

local function TeamCheck(PlayerA, PlayerB)
    if (PlayerA.Team ~= PlayerB.Team) then
        if (PlayerA.Team ~= PlayerB.Team and PlayerA.TeamColor ~= PlayerB.TeamColor) then
            return true
        end
    end
    return false
end

local TouchedObjects = {}
getgenv().firetouchinterest = firetouchinterest or firetouchinterest_f or fake_touch
getgenv().firetouch = firetouchinterest or function(Part1, Part2, Toggle)
    if (Part1 and Part2) then
        if (Toggle == 0) then
            TouchedObjects[1] = Part1.CFrame
            Part1.CFrame = Part2.CFrame
        else
            Part1.CFrame = TouchedObjects[1]
            TouchedObjects[1] = nil
        end
    end
end

getgenv().hookfunction = hookfunc or hookfunction or function(Function, newFunction, ApplyClosure)
    if (replaceclosure) then
        replaceclosure(Function, newFunction)
        return Function
    end
    Function = ApplyClosure and newcclosure or newFunction
    return Function
end

local function BetterClone(ToClone, Shallow)
    if (type(ToClone) == "function" and clonefunction) then
        return clonefunction(ToClone)
    end
    local Cloned = {}
    for k,v in pairs(ToClone) do
        if (type(v) == "table" and not Shallow) then
            v = BetterClone(v)
        end
        Cloned[k] = v
    end
    return Cloned
end

local GHandle = nil
local function CacheHandle(Handle)
    if syn.is_cached(Handle) == nil or syn.is_cached(Handle) == false then
        Objects[Part] = Clone(Handle)
        Objects[Part].CFrame = Handle.CFrame
        syn.cache_replace(Handle, Objects[Part])
    else
        syn.cache_invalidate(Handle)
    end
end

if LocalPlayer then
    Connections[#Connections+1] = MainMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
        GHandle = Objects[FakeHandle]
    end))
end

local returnGetTable = {
    Objects[FakeHandle]
}

local TouchMethods = {
    "GetTouchingParts",
    "GetConnectedParts"
}

local TouchHook
TouchHook = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Args = {...}
    if not checkcaller() then
        for _,v in pairs(TouchMethods) do
            if getnamecallmethod() == tostring(v) then
                return returnGetTable
            end
        end
    end
    return TouchHook(...)
end))

local TouchHook2
TouchHook2 = hookmetamethod(game, "__index", function(...)
    local Args = table.pack(...)
    local self = Args[1]
    local index = Args[2]
    if tostring(self) == "Handle" and (tostring(index) == "GetTouchingParts") and not Experimental.LockdownMode then
        return returnGetTable
    elseif tostring(self) == "Handle" and (tostring(index) == "GetConnectedParts") and not Experimental.LockdownMode then
        return returnGetTable
    elseif tostring(self) == "GetTouchingParts" and (tostring(index) == "Handle") and not Experimental.LockdownMode then
        return returnGetTable
    elseif tostring(self) == "GetConnectedParts" and (tostring(index) == "Handle") and not Experimental.LockdownMode then
        return returnGetTable
    end
    return TouchHook2(table.unpack(Args))
end)

local TouchHook3
TouchHook3 = hookfunction(Instance.new("Part").GetTouchingParts, newcclosure(function(self)
    if not checkcaller() and not Experimental.LockdownMode then
        return returnTouchingTable
    end
    return TouchHook3(self)
end))

local TouchHook4
TouchHook4 = hookfunction(Instance.new("Part").GetConnectedParts, newcclosure(function(self)
    if not checkcaller() and not Experimental.LockdownMode then
        return returnConnectedTable
    end
    return TouchHook4(self)
end))

local GetPartsInPartHook
GetPartsInPartHook = hookfunction(Workspace.GetPartsInPart, newcclosure(function(self)
    if not checkcaller() and not Experimental.LockdownMode then
        return returnTouchingTable
    end
    return GetPartsInPartHook(self)
end))

local GetPartBoundsInBoxHook
GetPartBoundsInBoxHook = hookfunction(Workspace.GetPartBoundsInBox, newcclosure(function(self)
    if not checkcaller() and not Experimental.LockdownMode then
        return returnConnectedTable
    end
    return GetPartBoundsInBoxHook(self)
end))

local GetPartBoundsInRadiusHook
GetPartBoundsInRadiusHook = hookfunction(Workspace.GetPartBoundsInRadius, newcclosure(function(self)
    if not checkcaller() and not Experimental.LockdownMode then
        return returnConnectedTable
    end
    return GetPartBoundsInRadiusHook(self)
end))

local WaitHook
WaitHook = hookfunc(getrenv().wait, newcclosure(function(...)
    local Args = {...}
    if Args[1] == 1 and getcallingscript().Parent == nil and not Experimental.LockdownMode then
        return coroutine.yield()
    elseif Args[1] == 2 and getcallingscript().Parent == nil and not Experimental.LockdownMode then
        return coroutine.yield()
    elseif Args[1] == 3 and getcallingscript().Parent == nil and not Experimental.LockdownMode then
        return coroutine.yield()
    end
    return WaitHook(...)
end))

--[[Anti Disablers]]--
getgenv().LogAttempts = false
loadstring(game:HttpGet("https://pastebin.com/raw/fz12rqKN"))()
--[[]]--

local SynapseTracker = {}
local HandleDB = {}
local FakeHandleDB = {}
local LastDB = {}
local function CompareDT(Player)
    RunService.Heartbeat:Wait()
    local DT = math.abs(HandleDB[Player] - FakeHandleDB[Player])
	DT = math.floor(DT * 10) / 10
	if DT > 1 and (not LastDB[Player] or LastDB[Player] ~= DT) then
		LastDB[Player] = DT
		if DT >= 1000 then
			return false
		end
	end
    return DT
end

local function ObelusHit(Handle, Limb) -- Damage function
    local Humanoid = GetCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
    local Repeat = 1
    if Settings.DamageAmp then
        Repeat = Settings.DamageAmpSettings.ThreadAmount or coroutine.resume()
    end
    if Handle:IsA("BasePart") and Limb:IsA("BasePart") then
        local Region = WorldBoundingBox(Handle.CFrame, Handle.Size)
        local FindRegion = Workspace:FindPartsInRegion3(Region)
        Maid.FakeObject = nil
        Maid.FakeItem = nil
        for _,k in pairs(FindRegion) do -- make another region for fake limbs around everyone in game
            if k:IsA("BasePart") and k.ClassName == "Part" or k.ClassName == "MeshPart" and k ~= Handle then
                local TouchTransmitter = k:FindFirstChildOfClass("TouchTransmitter")
                local JointInstance = k:FindFirstChildOfClass("JointInstance")
                if TouchTransmitter or JointInstance and Humanoid and isnetworkowner(k) then
                    for _,v in pairs(WhitelistedLimbs.All) do
                        local FindLimb = Humanoid and Humanoid:GetLimb(GetCharacter(LocalPlayer):FindFirstChild(tostring(v)))
                        if FindLimb ~= Enum.Limb.Unknown and k ~= FindLimb then
                            Maid.FakeObject = k
                        end
                    end
                else
                    for _,v in pairs(k:GetConnectedParts()) do
                        if v ~= Handle then
                            Maid.FakeItem = v
                        end
                    end
                    for _,z in pairs(Limb:GetConnectedParts()) do
                        if z ~= Humanoid:GetLimb(GetCharacter(LocalPlayer):FindFirstChild(tostring(Limb))) then
                            Maid.FakeItem = z
                        end
                    end
                end
            end
        end
        if Settings.VisibleChecks then
            if CheckPartVisibility(Limb) == false then
                return
            end
        end
        HandleDB[LocalPlayer] = tick()
        FakeHandleDB[LocalPlayer] = tick()
        local DT = CompareDT(LocalPlayer)
        if DT >= 1 or DT == false then
            return
        end
        if not SynapseTracker[LocalPlayer.Name] or SynapseTracker[LocalPlayer.Name] < 0 then
            SynapseTracker[LocalPlayer.Name] = 0
        end
        SynapseTracker[LocalPlayer.Name] += 1
        task.delay(25, function() -- change the number back to 25 for the normal ublubble delay
            SynapseTracker[LocalPlayer.Name] -= 1
        end)
        if SynapseTracker[LocalPlayer.Name] >= 3 then
            return
        end
        if Maid.FakeObject and Maid.FakeItem and DT <= 0.9 and SynapseTracker[LocalPlayer.Name] <= 3 then
            for i = 1, Repeat do
                --task.spawn(firetouch, Handle, Limb, 0)--
                coroutine.wrap(firetouch)(Handle, Limb, 0)
                coroutine.wrap(firetouch)(Maid.FakeObject, Limb, 0)
                coroutine.wrap(firetouch)(Maid.FakeItem, Limb, 0)
                task.wait(Settings.HitDelay)
                coroutine.wrap(firetouch)(Handle, Limb, 1)
                coroutine.wrap(firetouch)(Maid.FakeObject, Limb, 1)
                coroutine.wrap(firetouch)(Maid.FakeItem, Limb, 1)
                LastDB[LocalPlayer] = nil
                SynapseTracker[LocalPlayer.Name] = 0
            end
        elseif Maid.FakeObject and not Maid.FakeItem and DT <= 0.9 and SynapseTracker[LocalPlayer.Name] <= 3 then
            for i = 1, Repeat do
                coroutine.wrap(firetouch)(Handle, Limb, 0)
                coroutine.wrap(firetouch)(Maid.FakeObject, Limb, 0)
                task.wait(Settings.HitDelay)
                coroutine.wrap(firetouch)(Handle, Limb, 1)
                coroutine.warp(firetouch)(Maid.FakeObject, Limb, 1)
                LastDB[LocalPlayer] = nil
                SynapseTracker[LocalPlayer.Name] = 0
            end
        elseif not Maid.FakeObject and Maid.FakeItem and DT <= 0.9 and SynapseTracker[LocalPlayer.Name] <= 3 then
            for i = 1, Repeat do
                coroutine.wrap(firetouch)(Handle, Limb, 0)
                coroutine.wrap(firetouch)(Maid.FakeItem, Limb, 0)
                task.wait(Settings.HitDelay)
                coroutine.wrap(firetouch)(Handle, Limb, 1)
                coroutine.wrap(firetouch)(Maid.FakeItem, Limb, 1)
                LastDB[LocalPlayer] = nil
                SynapseTracker[LocalPlayer.Name] = 0
            end
        elseif not Maid.FakeObject and not Maid.FakeItem then
            Repeat = 3
            for i = 1, Repeat do
                firetouch(Handle, Limb, 0)
                task.wait(Settings.HitDelay)
                firetouch(Handle, Limb, 1)
                LastDB[LocalPlayer] = nil
            end
        end
    end
end

--[[local CloneHook
CloneHook = hookfunction(Instance.new("Part").Clone, newcclosure(function(self)
    if not self then
        return CloneHook(self)
    end
    if not checkcaller() then
        if Maid.FakeObject and Maid.FakeLimb then
            local Clone = CloneHook(self) or BetterClone(self)
            Maid.FakeObject = Clone
            Maid.FakeLimb = Clone
            return Clone
        end
    end
    return CloneHook(self)
end))--]]

local LastHit = os.clock()
Connections[#Connections+1] = MainMaid:GiveTask(RunService.RenderStepped:Connect(function() -- Damage connection
    local Sword = GetCharacter(LocalPlayer) and GetCharacter(LocalPlayer):FindFirstChildOfClass("Tool")
    if Sword then
        local Handle = Sword:FindFirstChild("Handle")
        if Handle then
            GHandle = GHandle or Handle
            if Experimental.FakeHandleChecks then
                coroutine.wrap(CacheHandle)(GHandle)
            end
            if Settings.Enabled then
                local ClosestPlayer, Distance = GetClosestPlayer(GHandle)
                local ClosestCharacter = GetCharacter(ClosestPlayer)
                if ClosestPlayer ~= LocalPlayer and ClosestCharacter ~= LocalPlayer.Character then
                    if type(Settings.Size) == "number" then
                        if ClosestPlayer and ClosestCharacter and Distance <= Settings.Size then
                            if Settings.ReachOnlyOnLunge and Sword.GripUp.Z == 0 then
                                if Settings.HitClock > 0 then
                                    for _,Limb in next, WhitelistedLimbs.Low do
                                        local Current = os.clock()
                                        if Current - LastHit >= Settings.HitClock + math.random() then
                                            if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            elseif not Settings.TeamChecks then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            end
                                        end
                                    end
                                else
                                    for _,Limb in next, WhitelistedLimbs.High do
                                        if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        elseif not Settings.TeamChecks then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        end
                                    end
                                end
                            elseif not Settings.ReachOnlyOnLunge then
                                if Settings.HitClock > 0 then
                                    for _,Limb in next, WhitelistedLimbs.Low do
                                        local Current = os.clock()
                                        if Current - LastHit >= Settings.HitClock + math.random() then
                                            if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            elseif not Settings.TeamChecks then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            end
                                        end
                                    end
                                else
                                    for _,Limb in next, WhitelistedLimbs.High do
                                        if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        elseif not Settings.TeamChecks then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        end
                                    end
                                end
                            end
                        end
                    elseif typeof(Settings.Size) == "Vector3" then
                        if ClosestPlayer and ClosestCharacter and Distance <= Settings.Size.Y then
                            if Settings.ReachOnlyOnLunge and Sword.GripUp.Z == 0 then
                                if Settings.HitClock > 0 then
                                    for _,Limb in next, WhitelistedLimbs.Low do
                                        local Current = os.clock()
                                        if Current - LastHit >= Settings.HitClock + math.random() then
                                            if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            elseif not Settings.TeamChecks then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            end
                                        end
                                    end
                                else
                                    for _,Limb in next, WhitelistedLimbs.High do
                                        if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        elseif not Settings.TeamChecks then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        end
                                    end
                                end
                            elseif not Settings.ReachOnlyOnLunge then
                                if Settings.HitClock > 0 then
                                    for _,Limb in next, WhitelistedLimbs.Low do
                                        local Current = os.clock()
                                        if Current - LastHit >= Settings.HitClock + math.random() then
                                            if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            elseif not Settings.TeamChecks then
                                                coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                                LastHit = Current
                                            end
                                        end
                                    end
                                else
                                    for _,Limb in next, WhitelistedLimbs.High do
                                        if Settings.TeamChecks and TeamCheck(LocalPlayer, ClosestPlayer) == false then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        elseif not Settings.TeamChecks then
                                            coroutine.wrap(ObelusHit)(GHandle, ClosestCharacter[Limb])
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end))

Connections[#Connections+1] = MainMaid:GiveTask(Players.PlayerRemoving:Connect(function(Player)
    pcall(function()
        if Player == LocalPlayer and Visualizer then
            Objects.RemoveFromTable(Objects, Visualizer)
            HandleDB[LocalPlayer] = nil
            FakeHandleDB[LocalPlayer] = nil
            MainMaid:DoCleaning()
        end
    end)
end))

local function SendNotification(Title, Text, Duration) -- Use roblox notifications like Radius X to make it look cool
    StarterGui:SetCore("SendNotification", {
        ["Title"] = Title,
        ["Text"] = Text,
        ["Duration"] = Duration
    })
end

local function IncrementKeySystem()
    pcall(function()
        local UserInputConnections = {}
        UserInputConnections[#UserInputConnections+1] = getconnections(raw.get(UserInputService, "InputBegan"))
        UserInputConnections[#UserInputConnections+1] = getconnections(raw.get(UserInputService, "InputEnded"))
        local DisabledSignals = {}
        for _,Signals in pairs(UserInputConnections) do
            for _,Signal in pairs(Signals) do
                if Signal.Enabled == true and Signal.Function ~= nil and is_synapse_function(Signal.Function) == false then
                    DisabledSignals[#DisabledSignals+1] = Signal
                    Signal:Disable()
                end
            end
        end
        Connections[#Connections+1] = MainMaid:GiveTask(UserInputService.InputBegan:Connect(function(Key, Input)
            if not Input and Key.UserInputType == Enum.UserInputType.Keyboard then
                if Key.KeyCode == Enum.KeyCode[Keys.ToggleKey] then
                    Settings.Enabled = not Settings.Enabled
                    if Experimental.NotificationsEnabled then
                        if Settings.Enabled then
                            warn("[Obelus X]: Reach has been enabled.")
                            SendNotification("Obelus X", "Reach has been enabled.", 1)
                        else
                            warn("[Obelus X]: Reach has been disabled.")
                            SendNotification("Obelus X", "Reach has been disabled.", 1)
                        end
                    end
                elseif Key.KeyCode == Enum.KeyCode[Keys.VisibleKey] then
                    Settings.Visible = not Settings.Visible
                    if Experimental.NotificationsEnabled then
                        if Settings.Visible then
                            warn("[Obelus X]: Reach is now visible.")
                            SendNotification("Obelus X", "Reach is now visible.", 1)
                        else
                            warn("[Obelus X]: Reach is now invisible.")
                            SendNotification("Obelus X", "Reach is now invisible.", 1)
                        end
                    end
                elseif Key.KeyCode == Enum.KeyCode[Keys.IncreaseKey] then
                    if type(Settings.Size) == "number" then
                        Settings.Size += 0.5
                        if Experimental.NotificationsEnabled then
                            warn("[Obelus X]: Reach size is now (" .. Settings.Size .. ") .")
                            SendNotification("Obelus X", "Reach size is now (" .. Settings.Size .. ") .", 1)
                        end
                    elseif typeof(Settings.Size) == "Vector3" then
                        Settings.Size += Vector3.new(0.5, 0.5, 0.5)
                        if Experimental.NotificationsEnabled then
                            warn("[Obelus X]: Reach size is now Vector3.new(" .. Settings.Size.X .. ", " .. Settings.Size.Y .. ", " .. Settings.Size.Z .. ").")
                            SendNotification("Obelus X", "Reach size is now Vector3.new(" .. Settings.Size.X .. ", " .. Settings.Size.Y .. ", " .. Settings.Size.Z .. ").", 1)
                        end
                    end
                elseif Key.KeyCode == Enum.KeyCode[Keys.DecreaseKey] then
                    if type(Settings.Size) == "number" then
                        Settings.Size -= 0.5
                        if Experimental.NotificationsEnabled then
                            warn("[Obelus X]: Reach size is now (" .. Settings.Size .. ") .")
                            SendNotification("Obelus X", "Reach size is now (" .. Settings.Size .. ") .", 1)
                        end
                    elseif typeof(Settings.Size) == "Vector3" then
                        Settings.Size -= Vector3.new(0.5, 0.5, 0.5)
                        if Experimental.NotificationsEnabled then
                            warn("[Obelus X]: Reach size is now Vector3.new(" .. Settings.Size.X .. ", " .. Settings.Size.Y .. ", " .. Settings.Size.Z .. ").")
                            SendNotification("Obelus X", "Reach size is now Vector3.new(" .. Settings.Size.X .. ", " .. Settings.Size.Y .. ", " .. Settings.Size.Z .. ").", 1)
                        end
                    end
                elseif Key.KeyCode == Enum.KeyCode[Keys.ShapeCycleKey] then
                    IncrementShape()
                    if Experimental.NotificationsEnabled then
                        warn("[Obelus X]: Reach shape is now " .. Settings.Shape .. ".")
                        SendNotification("Obelus X", "Reach shape is now " .. Settings.Shape .. ".", 1)
                    end
                end
            end
        end))
        for _,Signal in pairs(DisabledSignals) do
            Signal:Enable()
        end
    end)
end

coroutine.wrap(IncrementKeySystem)()
