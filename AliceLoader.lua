-- AliceHUB Loader v2.5.7
local API = "https://alicehub-api.shirokanaerus.workers.dev"
local FALLBACK_LOGO = "rbxassetid://71638246809611"

return function(token)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    local Player = Players.LocalPlayer

    assert(type(token) == "string" and #token > 0, "AliceHUB: token missing")
    if not game:IsLoaded() then game.Loaded:Wait() end
    assert(Player, "AliceHUB: LocalPlayer not found")

    local Env = (getgenv and getgenv()) or _G
    Env.AliceClientToken = token

    -- Small temporary boot/error UI.
    local bootGui, bootText
    local function bootRoot()
        local pg = Player:FindFirstChildOfClass("PlayerGui")
        if pg then return pg end
        local ok, found = pcall(function()
            return Player:WaitForChild("PlayerGui", 5)
        end)
        if ok and found then return found end
        if type(gethui) == "function" then
            local okHui, hui = pcall(gethui)
            if okHui and hui then return hui end
        end
        return CoreGui
    end

    local function makeBoot()
        pcall(function()
            local root = bootRoot()
            local old = root and root:FindFirstChild("AliceHUB_LoaderBoot")
            if old then old:Destroy() end

            local gui = Instance.new("ScreenGui")
            gui.Name = "AliceHUB_LoaderBoot"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 2147483000
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = root

            local frame = Instance.new("Frame")
            frame.AnchorPoint = Vector2.new(0.5, 0)
            frame.Position = UDim2.new(0.5, 0, 0, 18)
            frame.Size = UDim2.fromOffset(430, 82)
            frame.BackgroundColor3 = Color3.fromRGB(24, 15, 19)
            frame.BorderSizePixel = 0
            frame.Parent = gui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(181, 48, 83)
            stroke.Thickness = 1.5
            stroke.Transparency = 0.1
            stroke.Parent = frame

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(12, 7)
            title.Size = UDim2.new(1, -24, 0, 20)
            title.Font = Enum.Font.Code
            title.Text = "AliceHUB"
            title.TextColor3 = Color3.fromRGB(242, 236, 239)
            title.TextSize = 16
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = frame

            local status = Instance.new("TextLabel")
            status.BackgroundTransparency = 1
            status.Position = UDim2.fromOffset(12, 29)
            status.Size = UDim2.new(1, -24, 0, 44)
            status.Font = Enum.Font.Code
            status.Text = "Starting..."
            status.TextColor3 = Color3.fromRGB(190, 180, 185)
            status.TextSize = 12
            status.TextXAlignment = Enum.TextXAlignment.Left
            status.TextYAlignment = Enum.TextYAlignment.Top
            status.TextWrapped = true
            status.Parent = frame

            bootGui = gui
            bootText = status
        end)
    end

    local function setBoot(text)
        pcall(function()
            if bootText and bootText.Parent then
                bootText.Text = tostring(text or "")
            end
        end)
    end

    local function destroyBoot(delaySeconds)
        task.delay(delaySeconds or 0, function()
            pcall(function()
                if bootGui and bootGui.Parent then bootGui:Destroy() end
            end)
            bootGui, bootText = nil, nil
        end)
    end

    makeBoot()

    local function fail(message)
        local msg = tostring(message or "Unknown loader error")
        setBoot("Error: " .. msg)
        warn("[AliceHUB] " .. msg)
        task.delay(10, function()
            pcall(function()
                if bootGui and bootGui.Parent then bootGui:Destroy() end
            end)
        end)
        error("AliceHUB: " .. msg, 0)
    end

    -- Compatibility HTTP layer.
    -- Lite executors sometimes expose several HTTP functions, where one of them
    -- returns an HTML proxy page while another one returns the real API body.
    local function collectRequestTransports()
        local list, seen = {}, {}

        local function add(name, fn)
            if type(fn) ~= "function" or seen[fn] then return end
            seen[fn] = true
            list[#list + 1] = { name = name, fn = fn }
        end

        add("request", request)
        add("http_request", http_request)

        if type(http) == "table" then
            add("http.request", http.request)
        end
        if type(syn) == "table" then
            add("syn.request", syn.request)
        end
        if type(fluxus) == "table" then
            add("fluxus.request", fluxus.request)
        end
        if type(krnl) == "table" then
            add("krnl.request", krnl.request)
        end
        if type(arceus) == "table" then
            add("arceus.request", arceus.request)
        end

        return list
    end

    local function responseBody(response)
        if type(response) == "string" then
            return response
        end
        if type(response) ~= "table" then
            return nil
        end
        return response.Body
            or response.body
            or response.ResponseBody
            or response.responseBody
            or response.Data
            or response.data
    end

    local function responseCode(response)
        if type(response) ~= "table" then return nil end
        return tonumber(
            response.StatusCode
            or response.Status
            or response.status_code
            or response.status
            or response.Code
            or response.code
        )
    end

    local function callRequestTransport(entry, url)
        local browserHeaders = {
            ["Accept"] = "application/json,text/plain,*/*",
            ["Cache-Control"] = "no-cache",
            ["Pragma"] = "no-cache",
            ["User-Agent"] = "Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 Chrome/140.0 Mobile Safari/537.36"
        }

        local variants = {
            {
                Url = url,
                Method = "GET",
                Headers = browserHeaders
            },
            {
                URL = url,
                Method = "GET",
                Headers = browserHeaders
            },
            {
                url = url,
                method = "GET",
                headers = browserHeaders
            }
        }

        local lastError
        for _, options in ipairs(variants) do
            local ok, response = pcall(entry.fn, options)
            if ok then
                local body = responseBody(response)
                local code = responseCode(response)
                if type(body) == "string" and #body > 0 then
                    return body, code, nil
                end
                lastError = "body kosong"
            else
                lastError = tostring(response)
            end
        end

        return nil, nil, lastError or "request gagal"
    end

    local function rawHttpCandidates(url)
        local results = {}

        local function push(name, body, code, err)
            results[#results + 1] = {
                name = name,
                body = body,
                code = code,
                err = err
            }
        end

        -- Roblox HttpGet variants.
        do
            local ok, result = pcall(function()
                return game:HttpGet(url)
            end)
            if ok and type(result) == "string" and #result > 0 then
                push("game:HttpGet", result, 200, nil)
            else
                push("game:HttpGet", nil, nil, tostring(result))
            end
        end

        do
            local ok, result = pcall(function()
                return game.HttpGet(game, url)
            end)
            if ok and type(result) == "string" and #result > 0 then
                push("game.HttpGet", result, 200, nil)
            else
                push("game.HttpGet", nil, nil, tostring(result))
            end
        end

        do
            local ok, result = pcall(function()
                return game:HttpGet(url, true)
            end)
            if ok and type(result) == "string" and #result > 0 then
                push("HttpGet(cache)", result, 200, nil)
            else
                push("HttpGet(cache)", nil, nil, tostring(result))
            end
        end

        -- Try every request-like API instead of stopping at the first global.
        for _, entry in ipairs(collectRequestTransports()) do
            local body, code, err = callRequestTransport(entry, url)
            push(entry.name, body, code, err)
        end

        return results
    end

    local function responsePreview(value)
        local s = tostring(value or "")
        s = s:gsub("[%c]+", " "):gsub("%s+", " ")
        if #s > 145 then
            s = s:sub(1, 145) .. "..."
        end
        return s
    end

    local function decode(text)
        if type(text) ~= "string" then return nil end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(text)
        end)
        if ok and type(data) == "table" then
            return data
        end
        return nil
    end

    local function looksLikeAliceHubJson(data)
        if type(data) ~= "table" then return false end

        -- Public AliceHUB API responses always expose an explicit boolean `ok`.
        if type(data.ok) == "boolean" then
            return true
        end

        -- Fallback signatures used by AliceHUB endpoints.
        if data.session ~= nil or data.lease ~= nil or data.slotMode ~= nil then
            return true
        end
        if data.error ~= nil or data.code ~= nil then
            return true
        end
        if data.service == "AliceHUB API" then
            return true
        end

        return false
    end

    local function jsonSummary(data)
        if type(data) ~= "table" then return tostring(data) end

        local preferred = {
            "error", "message", "detail", "code", "status",
            "reason", "description", "service"
        }

        local parts = {}
        for _, key in ipairs(preferred) do
            local value = data[key]
            if value ~= nil and type(value) ~= "table" then
                parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
            end
        end

        if #parts == 0 then
            for key, value in pairs(data) do
                if type(value) ~= "table" then
                    parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
                    if #parts >= 5 then break end
                end
            end
        end

        local out = table.concat(parts, ", ")
        return responsePreview(out)
    end

    local function getJson(url)
        local candidates = rawHttpCandidates(url)
        local rejectedJson = {}
        local nonJson = {}
        local errors = {}

        for _, result in ipairs(candidates) do
            if type(result.body) == "string" and #result.body > 0 then
                local data = decode(result.body)
                if data then
                    if looksLikeAliceHubJson(data) then
                        Env.AliceHUBLastTransport = result.name
                        return data, nil, result.name
                    end

                    rejectedJson[#rejectedJson + 1] =
                        result.name .. ": " .. jsonSummary(data)
                else
                    local preview = responsePreview(result.body)
                    if preview ~= "" then
                        nonJson[#nonJson + 1] = result.name .. ": " .. preview
                    end
                end
            elseif result.err and result.err ~= "" then
                errors[#errors + 1] = result.name .. ": " .. responsePreview(result.err)
            end
        end

        local detail
        if #rejectedJson > 0 then
            detail = "JSON bukan AliceHUB • " .. rejectedJson[1]
        elseif #nonJson > 0 then
            detail = "non-JSON • " .. nonJson[1]
        elseif #errors > 0 then
            detail = errors[1]
        else
            detail = "tidak ada transport HTTP yang berhasil"
        end

        return nil, "API gagal • " .. detail, nil
    end

    local function httpGet(url)
        -- For raw payload/image bytes: accept the first non-empty successful body.
        local candidates = rawHttpCandidates(url)

        -- Prefer non-HTML bodies for scripts/images.
        for _, result in ipairs(candidates) do
            if type(result.body) == "string" and #result.body > 0 then
                local lower = result.body:sub(1, 300):lower()
                local looksHtml =
                    lower:find("<!doctype html", 1, true)
                    or lower:find("<html", 1, true)

                if not looksHtml then
                    Env.AliceHUBLastTransport = result.name
                    return result.body, nil, result.name
                end
            end
        end

        -- Last fallback, useful for legitimate textual responses.
        for _, result in ipairs(candidates) do
            if type(result.body) == "string" and #result.body > 0 then
                return result.body, nil, result.name
            end
        end

        return nil, "HTTP unavailable", nil
    end

    local function ensureFolder(path)
        if type(makefolder) ~= "function" then return end
        local exists = false
        if type(isfolder) == "function" then
            pcall(function() exists = isfolder(path) end)
        end
        if not exists then pcall(makefolder, path) end
    end

    local function validAssetReference(value)
        if type(value) ~= "string" or value == "" then
            return false
        end

        local clean = value:gsub("^%s+", ""):gsub("%s+$", "")
        if clean == "" or clean:match("^%d+$") then
            return false
        end

        if clean:find("://", 1, true) then
            return true
        end

        if clean:sub(1, 9) == "rbxasset:" or clean:sub(1, 11) == "rbxassetid:" then
            return true
        end

        return false
    end

    local function prepareLogo()
        Env.AliceHUBLogoAsset = FALLBACK_LOGO
        Env.AliceHUBBrandLogoAsset = FALLBACK_LOGO

        if type(writefile) ~= "function" then return end

        ensureFolder("AliceHUB")
        ensureFolder("AliceHUB/assets")

        local logoPath = "AliceHUB/BrandLogo.png"
        local assetPath = "AliceHUB/assets/BrandLogo.png"
        local versionPath = "AliceHUB/assets/BrandLogo.version"
        local wantedVersion = "2"

        local currentVersion
        if type(readfile) == "function" and type(isfile) == "function" then
            local exists = false
            pcall(function() exists = isfile(versionPath) end)
            if exists then
                pcall(function() currentVersion = tostring(readfile(versionPath) or "") end)
            end
        end

        local logoExists = false
        if type(isfile) == "function" then
            pcall(function() logoExists = isfile(logoPath) end)
        end

        if not logoExists or currentVersion ~= wantedVersion then
            local bytes = httpGet(
                API .. "/assets/logo?v=" .. HttpService:UrlEncode(wantedVersion)
                    .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
            )
            if type(bytes) == "string" and #bytes > 100 then
                pcall(writefile, logoPath, bytes)
                pcall(writefile, assetPath, bytes)
                pcall(writefile, versionPath, wantedVersion)
                logoExists = true
            end
        end

        local getAsset = getcustomasset or getsynasset
        if logoExists and type(getAsset) == "function" then
            local ok, asset = pcall(getAsset, logoPath)
            if ok and validAssetReference(asset) then
                Env.AliceHUBLogoAsset = asset
                Env.AliceHUBBrandLogoAsset = asset
                Env.AliceHUBLogoPath = logoPath
                Env.AliceHUBRejectedLogoAsset = nil
            elseif ok and asset ~= nil then
                Env.AliceHUBRejectedLogoAsset = tostring(asset)
                Env.AliceHUBLogoAsset = FALLBACK_LOGO
                Env.AliceHUBBrandLogoAsset = FALLBACK_LOGO
            end
        end
    end

    local function randomClientId()
        local ok, guid = pcall(function()
            return HttpService:GenerateGUID(false)
        end)
        if ok and type(guid) == "string" and #guid > 0 then
            return ("AHC_" .. guid):gsub("[^%w_-]", "")
        end
        return "AHC_" .. tostring(Player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    end

    local function getClientId()
        ensureFolder("AliceHUB")
        local path = "AliceHUB/client_instance.id"

        if type(isfile) == "function" and type(readfile) == "function" then
            local exists = false
            pcall(function() exists = isfile(path) end)
            if exists then
                local value
                pcall(function() value = tostring(readfile(path) or "") end)
                value = value and value:gsub("[^%w_-]", "") or ""
                if #value >= 8 and #value <= 96 then return value end
            end
        end

        local value = randomClientId()
        if type(writefile) == "function" then pcall(writefile, path, value) end
        return value
    end

    setBoot("Preparing...")
    pcall(prepareLogo)

    -- End previous lease only after the new execution has visibly started.
    if type(Env.AliceHUBReleaseSession) == "function" then
        pcall(Env.AliceHUBReleaseSession)
    end
    if Env.AliceHUBTeleportConnection then
        pcall(function() Env.AliceHUBTeleportConnection:Disconnect() end)
        Env.AliceHUBTeleportConnection = nil
    end

    Env.AliceHUBHeartbeatGeneration = (tonumber(Env.AliceHUBHeartbeatGeneration) or 0) + 1
    local generation = Env.AliceHUBHeartbeatGeneration
    local clientId = getClientId()

    local function acquire()
        setBoot("Connecting...")
        local url =
            API
            .. "/client/session?token=" .. HttpService:UrlEncode(token)
            .. "&username=" .. HttpService:UrlEncode(Player.Name)
            .. "&userId=" .. HttpService:UrlEncode(tostring(Player.UserId))
            .. "&clientId=" .. HttpService:UrlEncode(clientId)
            .. "&gameId=" .. HttpService:UrlEncode(tostring(game.GameId))
            .. "&placeId=" .. HttpService:UrlEncode(tostring(game.PlaceId))
            .. "&t=" .. HttpService:UrlEncode(tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999)))

        local data, err, method = getJson(url)
        if not data then
            return nil, tostring(err or "Response API tidak valid")
        end
        if data.ok ~= true then
            local reason =
                data.error
                or data.message
                or data.detail
                or data.reason
                or data.description
                or data.code
                or data.status
                or jsonSummary(data)
                or "Authorization gagal"
            return nil, tostring(reason)
        end
        Env.AliceHUBLastTransport = method
        if type(data.session) ~= "string" or type(data.lease) ~= "string" then
            return nil, "Session API tidak lengkap"
        end
        return data
    end

    local sessionData, sessionErr = acquire()
    if not sessionData then fail(sessionErr) end

    setBoot("Authorized • " .. tostring(sessionData.slots and sessionData.slots.used or "?")
        .. "/" .. tostring(sessionData.slots and sessionData.slots.max or "?"))

    local lease = sessionData.lease
    local heartbeatEvery = math.max(15, tonumber(sessionData.heartbeatEvery) or 30)
    local activeTtl = math.max(60, tonumber(sessionData.activeSessionTtl) or 150)

    local function apply(data)
        if type(data.access) == "table" then
            Env.AliceHUBAccess = {
                status = data.access.status or data.access.plan or "Active",
                plan = data.access.plan,
                expiresAt = data.access.expiresAt,
                permanent = data.access.permanent == true
            }
        end
        if type(data.slots) == "table" then
            Env.AliceHUBSlots = {
                used = tonumber(data.slots.used) or 0,
                max = tonumber(data.slots.max) or 0
            }
        end
        Env.AliceHUBActiveSession = {
            username = Player.Name,
            userId = Player.UserId,
            clientId = clientId,
            slotMode = "active_sessions",
            heartbeatEvery = heartbeatEvery,
            autoReleaseSeconds = activeTtl
        }
    end
    apply(sessionData)

    local function release()
        if generation ~= Env.AliceHUBHeartbeatGeneration then return false end
        local currentLease = lease
        if type(currentLease) ~= "string" or currentLease == "" then return false end
        lease = nil
        local body = httpGet(
            API .. "/client/release?lease=" .. HttpService:UrlEncode(currentLease)
                .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
        )
        return type(body) == "string"
    end

    Env.AliceHUBReleaseSession = release

    local okTeleport, teleportConnection = pcall(function()
        return Player.OnTeleport:Connect(function(state)
            if generation == Env.AliceHUBHeartbeatGeneration and state == Enum.TeleportState.Started then
                pcall(release)
            end
        end)
    end)
    if okTeleport then Env.AliceHUBTeleportConnection = teleportConnection end

    task.spawn(function()
        local failures = 0
        while generation == Env.AliceHUBHeartbeatGeneration do
            task.wait(heartbeatEvery)
            if generation ~= Env.AliceHUBHeartbeatGeneration then return end

            local heartbeatOk = false
            if type(lease) == "string" and lease ~= "" then
                local data = select(1, getJson(
                    API .. "/client/heartbeat?lease=" .. HttpService:UrlEncode(lease)
                        .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
                ))
                if data and data.ok == true then
                    heartbeatOk = true
                    failures = 0
                    heartbeatEvery = math.max(15, tonumber(data.heartbeatEvery) or heartbeatEvery)
                    activeTtl = math.max(60, tonumber(data.activeSessionTtl) or activeTtl)
                    if type(data.slots) == "table" then
                        Env.AliceHUBSlots = {
                            used = tonumber(data.slots.used) or 0,
                            max = tonumber(data.slots.max) or 0
                        }
                    end
                end
            end

            if not heartbeatOk then
                failures = failures + 1
                if failures >= 2 then
                    local fresh = acquire()
                    if fresh then
                        sessionData = fresh
                        lease = fresh.lease
                        heartbeatEvery = math.max(15, tonumber(fresh.heartbeatEvery) or heartbeatEvery)
                        activeTtl = math.max(60, tonumber(fresh.activeSessionTtl) or activeTtl)
                        failures = 0
                        apply(fresh)
                    end
                end
            end
        end
    end)

    setBoot("Loading " .. tostring(sessionData.game and sessionData.game.target or "payload") .. "...")

    local function payloadLooksHealthy(source)
        if type(source) ~= "string" or #source < 100 then
            return false, "payload kosong/terlalu pendek"
        end

        local head = source:sub(1, 400):lower()
        if head:find("<!doctype html", 1, true) or head:find("<html", 1, true) then
            return false, "HTML/proxy response"
        end

        -- Detect transport corruption around GetService("...").
        -- All AliceHUB payloads use normal Roblox service names here.
        for _, serviceName in source:gmatch("GetService%s*%(%s*([\"'])(.-)%1%s*%)") do
            if serviceName == "" or serviceName:find("[^%w_]") then
                return false, "GetService rusak: " .. tostring(serviceName)
            end
        end

        -- Reject obvious binary/control corruption while allowing normal tabs/newlines.
        local sample = source:sub(1, math.min(#source, 12000))
        for i = 1, #sample do
            local b = sample:byte(i)
            if b == 0 or (b < 9) or (b > 13 and b < 32) then
                return false, "payload mengandung byte kontrol"
            end
        end

        return true
    end

    local function compilePayloadCandidate(source)
        local healthy, reason = payloadLooksHealthy(source)
        if not healthy then
            return nil, reason
        end

        local chunk, compileError = loadstring(source)
        if type(chunk) ~= "function" then
            return nil, "compile: " .. tostring(compileError)
        end

        return chunk
    end

    local function fetchPayloadCompat(url)
        local attempts = {}
        local seenBodies = {}

        local function tryBody(name, body)
            if type(body) ~= "string" or body == "" then
                attempts[#attempts + 1] = name .. ": kosong"
                return nil
            end

            -- Avoid re-checking identical responses from aliased executor functions.
            local signature = tostring(#body) .. ":" .. body:sub(1, 96)
            if seenBodies[signature] then
                return nil
            end
            seenBodies[signature] = true

            local chunk, reason = compilePayloadCandidate(body)
            if chunk then
                Env.AliceHUBPayloadTransport = name
                return chunk
            end

            attempts[#attempts + 1] = name .. ": " .. tostring(reason)
            return nil
        end

        -- First priority = exact simple path used before Active Sessions migration.
        do
            local ok, body = pcall(function()
                return game:HttpGet(url)
            end)
            if ok then
                local chunk = tryBody("game:HttpGet", body)
                if chunk then return chunk end
            else
                attempts[#attempts + 1] = "game:HttpGet: " .. tostring(body)
            end
        end

        -- Try all alternate HTTP transports only if the old path is unusable.
        for _, result in ipairs(rawHttpCandidates(url)) do
            local chunk = tryBody(result.name, result.body)
            if chunk then return chunk end
            if not result.body and result.err then
                attempts[#attempts + 1] =
                    result.name .. ": " .. responsePreview(result.err)
            end
        end

        local summary = table.concat(attempts, " | ")
        if #summary > 420 then summary = summary:sub(1, 420) .. "..." end
        return nil, summary ~= "" and summary or "semua transport payload gagal"
    end

    local payloadUrl =
        API .. "/script?session=" .. HttpService:UrlEncode(sessionData.session)
        .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))

    local chunk, payloadErr = fetchPayloadCompat(payloadUrl)
    if type(chunk) ~= "function" then
        fail("Payload transport gagal: " .. tostring(payloadErr))
    end

    setBoot("Loaded")
    destroyBoot(1.2)

    local function payloadTraceback(err)
        local message = tostring(err)
        local dbg = debug
        if type(dbg) == "table" and type(dbg.traceback) == "function" then
            local okTrace, trace = pcall(dbg.traceback, message, 2)
            if okTrace and type(trace) == "string" and trace ~= "" then
                return trace
            end
        end
        return message
    end

    local okRun, runErr = xpcall(chunk, payloadTraceback)
    if not okRun then
        local compact = tostring(runErr or "unknown payload error")
            :gsub("[%c]+", " ")
            :gsub("%s+", " ")
        if #compact > 380 then
            compact = compact:sub(1, 380) .. "..."
        end
        local target = tostring(sessionData.game and sessionData.game.target or "?")
        local transport = tostring(Env.AliceHUBPayloadTransport or "?")
        fail("Payload error [" .. target .. " / " .. transport .. "]: " .. compact)
    end
end
