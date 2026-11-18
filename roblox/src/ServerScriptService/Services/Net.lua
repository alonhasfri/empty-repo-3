-- Net: one RemoteFunction for requests from players, one RemoteEvent to send to players.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"
folder.Parent = ReplicatedStorage

local request = Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = folder

local toClient = Instance.new("RemoteEvent")
toClient.Name = "ToClient"
toClient.Parent = folder

local handlers = {}
local rate = {} -- [player] = {count, windowStart}

function Net.on(action: string, handler)
	handlers[action] = handler
end

request.OnServerInvoke = function(player, action, data)
	if typeof(action) ~= "string" then
		return nil
	end
	-- simple rate limit: 25 requests per second
	local now = os.clock()
	local r = rate[player]
	if not r or now - r[2] > 1 then
		r = { 0, now }
		rate[player] = r
	end
	r[1] += 1
	if r[1] > 25 then
		return { ok = false, msg = "Slow down!" }
	end
	local handler = handlers[action]
	if not handler then
		return { ok = false, msg = "Unknown action" }
	end
	local ok, result = pcall(handler, player, typeof(data) == "table" and data or {})
	if not ok then
		warn("[Net] " .. action .. " failed: " .. tostring(result))
		return { ok = false, msg = "Something went wrong." }
	end
	return result
end

function Net.send(player: Player, kind: string, payload)
	toClient:FireClient(player, kind, payload)
end

function Net.broadcast(kind: string, payload)
	toClient:FireAllClients(kind, payload)
end

game:GetService("Players").PlayerRemoving:Connect(function(p)
	rate[p] = nil
end)

return Net
