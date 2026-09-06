return function(Token)
    local API = "https://alicehub-api.shirokanaerus.workers.dev"

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")

    local Player = Players.LocalPlayer
    assert(Player, "AliceHUB: LocalPlayer not found")

    assert(type(Token) == "string" and #Token > 0, "AliceHUB: token missing")

    local function httpGet(url)
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)

        assert(ok, "AliceHUB HTTP error: " .. tostring(result))
        return result
    end
    
    local sessionBody = httpGet(
        API
            .. "/client/session?token=" .. HttpService:UrlEncode(Token)
            .. "&username=" .. HttpService:UrlEncode(Player.Name)
            .. "&gameId=" .. HttpService:UrlEncode(tostring(game.GameId))
            .. "&placeId=" .. HttpService:UrlEncode(tostring(game.PlaceId))
    )

    local decodeOk, sessionData = pcall(function()
        return HttpService:JSONDecode(sessionBody)
    end)

    assert(
        decodeOk and type(sessionData) == "table",
        "AliceHUB: invalid session response"
    )

    assert(
        sessionData.ok and type(sessionData.session) == "string",
        sessionData.error or "AliceHUB authorization failed"
    )

    local Env = (getgenv and getgenv()) or _G

    if type(sessionData.access) == "table" then
        Env.AliceHUBAccess = {
            status = sessionData.access.status or sessionData.access.plan or "Active",
            plan = sessionData.access.plan,
            expiresAt = sessionData.access.expiresAt,
            permanent = sessionData.access.permanent == true,
        }
    else
        Env.AliceHUBAccess = {
            status = "Active",
            permanent = false,
        }
    end

    local payload = httpGet(
        API
            .. "/script?session="
            .. HttpService:UrlEncode(sessionData.session)
    )

    local chunk, compileError = loadstring(payload)

    assert(
        type(chunk) == "function",
        "AliceHUB payload compile failed: " .. tostring(compileError)
    )

    return chunk()
end
