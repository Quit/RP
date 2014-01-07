//function rpf() { radiant.call('radiant:play_sound', 'stonehearth:sounds:ui:start_menu:popup'); }
//function rps() { radiant.call('radiant:play_sound', 'stonehearth:sounds:ui:promotion_menu:stamp'); }

var dump = function(obj, level, rec, recStr)
{
	if (!level)
	{
		level = 0;
	}
	
	if (!rec)
	{
		rec = {}
	}
	
	if (!recStr)
	{
		recStr = '';
	}
	
	var text = "";
	var ind = new Array(level).join("  ");
	
	if (typeof(obj) == 'object')
	{
		// Define us already
		rec[obj] = recStr;
		
		for (var key in obj)
		{
			var value = obj[key];
			
			text += ind + '[' + key + '] = ';
			
			// INCEPTION?
			if (typeof(value) == 'object')
			{
				// Already done?
				if (rec[value])
				{
					text += '(recursion in ' + rec[value] + ')';
				}
				else
				{
					text +='\n';
					text += dump(value, level + 1, rec, (recStr == '' ? key : recStr + '.' + key));
				}
			}
			else if (typeof(value) == 'function')
			{
				text += '(function)';
			}
			else
			{
				text += value;
			}
			
			text += '\n';
		}
	}
	else
	{
		text = obj;
	}
	
	return text;
}

// callName => proxyfunc.
// We can later do id stuff, for now this suffices.
var call_proxies = {};
	
rp = {
	// log(str1, str2, ...)
	// Logs any amount of variables into the server log (prefixed by [JS])
	log : function() { 
		var args = Array.prototype.slice.call(arguments);
		args.unshift('rp:log_server');
		radiant.call.apply(radiant, args); 
	},
	
	// dump(obj)
	// returns a (dumped) string that is obj.
	dump : dump,
		
	set_call_proxy : function(callName, func) { call_proxies[callName] = func; }
}


// Initialize RP immediately, give audio feedback
radiant.call('rp:init_server'); //.done(rps).fail(rpf);

// Now to some magic.
// Patch radiant.call
var oldCall = radiant.call;
radiant.call = function()
{
	var args = Array.prototype.slice.call(arguments);
	var event = args[0];
	var func = oldCall;
	
	if (event != 'rp:log_server')
	{
		if (typeof call_proxies[event] != 'undefined')
		{
			return call_proxies[event].apply(null, args);
		}
	}
	
	return oldCall.apply(radiant, args);
}

// Patch errors to the console
var oldError = window.onerror;

window.onerror = function(errorMsg, url, lineNumber)
{
	var ret = false;
	if (typeof oldError != 'undefined')
		ret = oldError(errorMsg, url, lineNumber);
	rp.log('ERROR: ' + url + ':' + lineNumber + ': ' + errorMsg);
	
	return ret;
}

rp.log('RP JS Loader done.');
//radiant.call('rp:init_client'); //.done(rps).fail(rpf); // client_init does a fine job