-- AliceHUB Loader v2.2 · split payload routing
-- Personal token is injected by Discord Get Script.
-- Never hardcode a buyer token inside this public file.

local API = "https://alicehub-api.shirokanaerus.workers.dev"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function detectGame()
    local gameId = tonumber(game.GameId)

    if gameId == 10338952197 then
        return "chicken"
    elseif gameId == 10563114921 then
        return "sae"
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes
        and remotes:FindFirstChild("PetChicken")
        and remotes:FindFirstChild("HatchEgg") then
        return "chicken"
    end

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local data = ReplicatedStorage:FindFirstChild("Data")
    if shared and data
        and shared:FindFirstChild("Remotes")
        and shared:FindFirstChild("Save")
        and data:FindFirstChild("Areas")
        and data:FindFirstChild("Assets") then
        return "sae"
    end

    error(("AliceHUB: unsupported game (GameId %s / PlaceId %s)")
        :format(tostring(game.GameId), tostring(game.PlaceId)))
end

local TargetGame = detectGame()

local Player = Players.LocalPlayer
assert(Player, "AliceHUB: LocalPlayer not found")

local Token = getgenv().AliceClientToken
assert(type(Token) == "string" and #Token > 0, "AliceHUB: AliceClientToken missing")

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)

    assert(ok, "AliceHUB HTTP error: " .. tostring(result))
    return result
end

local sessionBody = httpGet(
    API
        .. "/client/session?token="
        .. HttpService:UrlEncode(Token)
        .. "&username="
        .. HttpService:UrlEncode(Player.Name)
        .. "&game="
        .. HttpService:UrlEncode(TargetGame)
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

-- Pass license/expiry data from Cloudflare to the AliceHUB UI.
local Env = getgenv()
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
