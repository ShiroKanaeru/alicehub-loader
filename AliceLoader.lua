-- AliceHUB Legacy Loader Notice
-- Old GitHub loader -> directs users to the new personal script.

return function(_oldToken)
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local player = Players.LocalPlayer

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    if not player then
        warn("[AliceHUB] Open Discord > Script Panel > Get Script to get your new personal loader.")
        return
    end

    local function getRoot()
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if pg then return pg end

        local ok, found = pcall(function()
            return player:WaitForChild("PlayerGui", 5)
        end)
        if ok and found then return found end

        if type(gethui) == "function" then
            local okHui, hui = pcall(gethui)
            if okHui and hui then return hui end
        end

        return CoreGui
    end

    pcall(function()
        local root = getRoot()
        if not root then return end

        local old = root:FindFirstChild("AliceHUB_GetNewScript")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "AliceHUB_GetNewScript"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 2147483000
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = root

        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.Size = UDim2.fromOffset(380, 205)
        frame.BackgroundColor3 = Color3.fromRGB(17, 17, 19)
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(181, 48, 83)
        stroke.Thickness = 1.4
        stroke.Transparency = 0.1
        stroke.Parent = frame

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(18, 16)
        title.Size = UDim2.new(1, -36, 0, 30)
        title.Font = Enum.Font.GothamBold
        title.Text = "AliceHUB"
        title.TextColor3 = Color3.fromRGB(245, 245, 245)
        title.TextSize = 22
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = frame

        local status = Instance.new("TextLabel")
        status.BackgroundTransparency = 1
        status.Position = UDim2.fromOffset(18, 52)
        status.Size = UDim2.new(1, -36, 0, 24)
        status.Font = Enum.Font.GothamBold
        status.Text = "New Script Required"
        status.TextColor3 = Color3.fromRGB(255, 125, 145)
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = frame

        local info = Instance.new("TextLabel")
        info.BackgroundTransparency = 1
        info.Position = UDim2.fromOffset(18, 81)
        info.Size = UDim2.new(1, -36, 0, 62)
        info.Font = Enum.Font.Gotham
        info.Text = "This loader is no longer used.\nOpen AliceHUB Discord > Script Panel > Get Script\nto get your new personal loader."
        info.TextColor3 = Color3.fromRGB(220, 220, 220)
        info.TextSize = 13
        info.TextWrapped = true
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Parent = frame

        local copy = Instance.new("TextButton")
        copy.Position = UDim2.fromOffset(18, 155)
        copy.Size = UDim2.fromOffset(180, 34)
        copy.BackgroundColor3 = Color3.fromRGB(181, 48, 83)
        copy.BorderSizePixel = 0
        copy.Font = Enum.Font.GothamBold
        copy.Text = "Copy Discord"
        copy.TextColor3 = Color3.fromRGB(255, 255, 255)
        copy.TextSize = 13
        copy.Parent = frame

        local copyCorner = Instance.new("UICorner")
        copyCorner.CornerRadius = UDim.new(0, 8)
        copyCorner.Parent = copy

        local close = Instance.new("TextButton")
        close.AnchorPoint = Vector2.new(1, 0)
        close.Position = UDim2.new(1, -18, 0, 155)
        close.Size = UDim2.fromOffset(92, 34)
        close.BackgroundColor3 = Color3.fromRGB(35, 35, 39)
        close.BorderSizePixel = 0
        close.Font = Enum.Font.GothamBold
        close.Text = "Close"
        close.TextColor3 = Color3.fromRGB(240, 240, 240)
        close.TextSize = 13
        close.Parent = frame

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = close

        copy.MouseButton1Click:Connect(function()
            local link = "https://discord.gg/M9pFHsCHv"
            local copied = false

            if type(setclipboard) == "function" then
                copied = pcall(setclipboard, link)
            elseif type(toclipboard) == "function" then
                copied = pcall(toclipboard, link)
            end

            copy.Text = copied and "Discord Copied" or "discord.gg/M9pFHsCHv"
        end)

        close.MouseButton1Click:Connect(function()
            gui:Destroy()
        end)
    end)
end
