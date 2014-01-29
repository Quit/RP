local Client = class()

function Client:set_input_disabled(session, response, status)
	rp.keyboard_input_disabled = status
	rp.mouse_input_disabled = status
	
	return true
end

return Client