var dump = function(obj, level, rec, recStr)
{

	if (!level)
	{
		level = 1;
	}
	
	if (!rec)
	{
		rec = { objs: [], paths: [] } // O(n) :|
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
		rec.objs.push(obj);
		rec.paths.push(recStr);
		
		for (var key in obj)
		{
			var value = obj[key];
			text += ind + '[' + key + '] = ';
			
			// INCEPTION?
			if (typeof(value) == 'object')
			{
				// Already done?
				var recInd = rec.objs.indexOf(value); // O(n)ein. :(
				if (recInd >= 0)
				{
					text += '(reference to ' + rec.paths[recInd] + ')';
				}
				else
				{
					text += "\n";
					text += dump(value, level + 1, rec, (recStr == '' ? key : recStr + '.' + key));
				}
			}
			else if (typeof(value) == 'function')
			{
				text += '(function)';
			}
			else if (typeof(value) == 'string')
			{
				text += '"' + value.replace('\\', '\\\\').replace('"', '\"') + '"';
			}
			else
			{
				text += value;
			}
			
			text += "\n";
		}
	}
	else
	{
		text = obj;
	}
	
	return text;
}

// callName => proxyfunc.
var call_proxies = {};
	
// Ember tells us not to create new global variables, because App is already one
// I say we should create TWO global variables just because!
rp = {
	// log(str1, str2, ...)
	// Logs any amount of variables into the server log (prefixed by [JS])
	log : function() { 
		var args = Array.prototype.slice.call(arguments);
		for (var i = 0; i < args.length; ++i)
		{
			if (typeof(args[i]) == 'function')
				args[i] = '(JS function)';
		}
		radiant.callv('rp:log_server', args); 
	},
	
	// dump(obj)
	// returns a (dumped) string that is obj.
	dump : dump,
	
	// set_call_proxy(callName, func): redirects all radiant.call(callName) to func; allowing you to return different stuff or mess around altogether.
	set_call_proxy : function(callName, func) { call_proxies[callName] = func; }
}


// Initialize RP immediately, *without* audio feedback. Long live rp:log_server.
radiant.call('rp:init_server').done(function() { rp.log('RP JS Loader done.'); });

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
	errorMsg = errorMsg || '(unknown error message)';
	url = url || '(unknown url)';
	lineNumber = lineNumber || '(unknown line number)';
	
	rp.log('ERROR: ' + url + ':' + lineNumber + ': ' + errorMsg);

	if (typeof oldError != 'undefined')
		return oldError(errorMsg, url, lineNumber);
	
	return false;
}