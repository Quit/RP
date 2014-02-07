function debug.traceline(str)
	local info = debug.getinfo(2)
	rp.logf('[DEBUG] Trace %s:%d %s %s', info.source, info.currentline, str or '', info.name and '(in ' .. info.name .. ')' or '')
end