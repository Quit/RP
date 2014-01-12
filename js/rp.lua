local rps = class()

function rps:init_server()
	-- Init our server.
	return require('server_init') ~= nil
end

function rps:log_server(sess, response, ...)
	-- The bindings work too well.
	local t = { ... }

	local count = select('#', ...)	
	for i = 1, count do
		t[i] = tostring(t[i])
	end
	
	rp.log('[JS] ' .. table.concat(t, '\t'))
	
	response:resolve(true)
end

return rps