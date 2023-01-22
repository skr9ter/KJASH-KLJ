local GetService = game.GetService;
local Debris = game:GetService("Debris")
local Players, RunService, UserInputService = GetService(game, "Players"), GetService(game, "RunService"), GetService(game, "UserInputService");

local LocalPlayer, Camera = Players.LocalPlayer, workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Framework = {
    Enabled = false,
    Held = false,
    Target = "Head",
    Sensitivity = 1,
    Radius = 100,
    Distance = 100,
    Keybind = nil,
    ScanFromHead = false,
    Checks = {
        Team = false,
        Friend = false,
        Visible = false
    },
    Highlight = {
        Enabled = false,
        Outline = Color3.fromRGB(255, 255, 255),
        Fill = Color3.fromRGB(255, 112, 112),
    },
}; Framework.__index = Framework;

function Framework:Pass_Through(From, Target, RaycastParams_, Ignore_Table)
    RaycastParams_.FilterDescendantsInstances = Ignore_Table
    local Result = workspace:Raycast(From, (Target.Position - From).unit * 10000, RaycastParams_)
    if Result then
        local Instance_ = Result.Instance
        if Instance_:IsDescendantOf(Target.Parent) then
            Passed = true
            return true
        elseif Instance_.CanCollide == false or Instance_.Transparency == 1 then
            if Instance_.Name ~= "Head" and Instance_.Name ~= "HumanoidRootPart" then
                table.insert(Ignore_Table, Instance_)
                Pass_Through(Result.Position, Target, RaycastParams_, Ignore_Table)
            end
        end
    end
end

function Framework:IsVisible(Target, FromHead)
    local Character = LocalPlayer.Character
    if not Character then return false end
    local Head = Character:FindFirstChild("Head")
    if not Head then return false end
    local RaycastParams_ = RaycastParams.new();
    RaycastParams_.FilterType = Enum.RaycastFilterType.Blacklist;
    local Ignore_Table = { Camera, LocalPlayer.Character }
    RaycastParams_.FilterDescendantsInstances = Ignore_Table;
    RaycastParams_.IgnoreWater = true;
    local From = FromHead and Head.Position or Camera.CFrame.p
    local Result = workspace:Raycast(From, (Target.Position - From).unit * 10000, RaycastParams_)
    Passed = false
    if Result then
        local Instance_ = Result.Instance
        if Instance_:IsDescendantOf(Target.Parent) then
            return true
        elseif Framework.Checks.Visible and Instance_.CanCollide == false or Instance_.Transparency == 1 then
            if Instance_.Name ~= "Head" and Instance_.Name ~= "HumanoidRootPart" then
                table.insert(Ignore_Table, Instance_)
                Framework:Pass_Through(Result.Position, Target, RaycastParams_, Ignore_Table)
            end;
        end;
    end;
    return Passed;
end;

function Framework:IsTeammate(player)
    return player.Team == LocalPlayer.Team
end

local Connection, Target, Lock = nil, nil, false

function Framework:GetClosestToCursor()
    local target, min_distance = nil, math.huge;
    for _, player in next, Players:GetPlayers() do
        local character = player.Character;
        if player ~= LocalPlayer and character and character:FindFirstChild("Head") then
            local position, visible = Camera:WorldToScreenPoint(character.Head.Position)
            if visible then
                local distance = Vector2.new(position.x - Mouse.x, position.y - Mouse.y).magnitude
                if distance < min_distance then
                    min_distance = distance;
                    target = player
                end;
            end
        end
    end

    return target, min_distance;
end

Connection = RunService.RenderStepped:Connect(function()
    local Checks = Framework.Checks
    if Framework.Enabled and Framework.Held then
        local distance;
        Target, distance = Framework:GetClosestToCursor()
        if Target ~= nil then
            local Aimlock = Target.Character:FindFirstChild(Framework.Target) or Target.Character.Head
            local Position, Visible = Camera:WorldToScreenPoint(Aimlock.Position)

            if Visible then
                if Framework.Radius < distance then
                    return
                end

                if Checks.Friend and Target:IsFriendsWith(LocalPlayer.UserId) then
                    return;
                end

                if Checks.Team and Framework:IsTeammate(Target) then
                    return;
                end

                if Checks.Visible and not Framework:IsVisible(Target.Character.Head, Framework.ScanFromHead) then
                    return;
                end

                -- Highlight.Parent = Aimlock.Parent
                -- Highlight.Enabled = Framework.Highlight.Enabled
                -- Highlight.FillColor = Framework.Highlight.Fill
                -- Highlight.OutlineColor = Framework.Highlight.Outline

                mousemoverel((Position.X - Mouse.X) * Framework.Sensitivity, (Position.Y - Mouse.Y) * Framework.Sensitivity)
            end
        end
    end
end)

return Framework
