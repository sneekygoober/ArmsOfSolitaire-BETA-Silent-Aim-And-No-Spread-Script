if not game:IsLoaded() then game.Loaded:Wait(); end;

local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "Your executor";

if not (hookfunction and require and debug.getupvalues) then
    return error(executor .. " is missing " .. (not hookfunction and "hookfunction " or "") .. (not require and "require " or "") .. (not debug.getupvalues and "debug.getupvalues" or ""));
end;

local RF: ReplicatedFirst = cloneref(game:GetService("ReplicatedFirst"));
local Players = game:GetService("Players");

local plr = Players.LocalPlayer;
local cam = workspace.CurrentCamera;

local mouse = plr:GetMouse();

local s, r = pcall(require, RF.Scripts.GameplayManager.Classes.PlayerController.Classes.WeaponsController.Slots.GunController);
if not s then
    return warn(executor .. " returned an error while trying to require RF.Scripts.GameplayManager.Classes.PlayerController.Classes.WeaponsController.Slots.GunController:\n" .. r);
end;

local GunController = r;
for _, v in next, debug.getupvalues(GunController.new) do
    if type(v) == "table" and rawget(v, "Discharge_Bullet") and rawget(v, "GetSpread") then
        GunController = v;
        break;
    end;
end;

if GunController == r then
    return warn(executor .. " failed to find an upvalue");
end;

local isVisible = function(part: BasePart): (boolean, Instance?)
    local char = plr.Character;
    if not char then return false, nil; end;

    local rp = RaycastParams.new();
    rp.FilterType = Enum.RaycastFilterType.Exclude;
    rp.FilterDescendantsInstances = {char};
    rp.IgnoreWater = true;

    local origin = cam.CFrame.Position;

    local dir = part.Position - origin;
    local result: RaycastResult = workspace:Raycast(origin, dir, rp);
    if not result then return true, nil; end;

    if result.Instance:IsDescendantOf(part.Parent) then
        return true, result.Instance;
    end;

    return false, result.Instance;
end;

local getTarget = function()
    local cPart, cDistance = nil, math.huge;

    for _, player: Player in next, Players:GetChildren() do
        if player == plr or player.Team == plr.Team then continue; end;

        local char = player.Character;
        if not char or char:FindFirstChildOfClass("ForceField") or (char:FindFirstChild("Health") and char.Health.Value <= 0) then continue; end;

        local tPart: BasePart = char:FindFirstChild("Head") or char.PrimaryPart or char:FindFirstChild("Hitbox");
        if not tPart then continue; end;

        local pos, onScreen = cam:WorldToViewportPoint(tPart.Position);
        if not onScreen then continue; end;

        local v, nTPart = isVisible(tPart);
        if not v then
            v, nTPart = isVisible(char.PrimaryPart or char:FindFirstChild("Hitbox"));
            if not v then continue; end;
        end;

        if nTPart then tPart = nTPart; end;

        local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude;
        if distance < cDistance then
            cPart = tPart;
            cDistance = distance;
        end;
    end;

    return cPart;
end;

GunController.GetSpread = function() return 0; end;

local old; old = clonefunction(hookfunction(GunController.Discharge_Bullet, newcclosure(function(_, origin: Vector3, __)
    local c = getTarget();
    if c then
        return old(_, origin, (c.Position - origin).Unit);
    end;
    return old(_, origin, __);
end)));
