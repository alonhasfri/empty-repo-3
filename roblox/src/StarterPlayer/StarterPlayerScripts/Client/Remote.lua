-- Remote: talking to the server from the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("Request")
local toClient = remotes:WaitForChild("ToClient")

local Remote = {}
local listeners = {}

function Remote.call(action: string, data)
	local ok, result = pcall(function()
		return request:InvokeServer(action, data or {})
	end)
	if not ok then
		warn("[Remote] " .. action .. ": " .. tostring(result))
		return { ok = false, msg = "Connection problem. Try again." }
	end
	return result or { ok = false }
end

function Remote.on(kind: string, fn)
	listeners[kind] = listeners[kind] or {}
	table.insert(listeners[kind], fn)
end

toClient.OnClientEvent:Connect(function(kind, payload)
	local list = listeners[kind]
	if list then
		for _, fn in ipairs(list) do
			task.spawn(fn, payload or {})
		end
	end
end)

return Remote
