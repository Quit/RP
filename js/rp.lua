local rps = class()

function rps:init_server()
	-- Init our server.
	return require('server_init') ~= nil
end

function rps:log_server(sess, req, ...)
	-- The bindings work too well.
	local t = { ... }
	local count = #t
	
	for i = 1, count do
		t[i] = tostring(t[i])
	end
	
	rp.log('[JS] ' .. table.concat(t, '\t'))
end

--~ function rps:init_client()
--~ 	require('api')
--~ 	return true
--~ end

return rps