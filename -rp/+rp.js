/*********************************************************************************
The MIT License (MIT)

Copyright (c) 2014 RepeatPan
excluding parts that were written by Radiant Entertainment.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*********************************************************************************/

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

// We don't obey your rules.
var old_callv = radiant.callv.bind(radiant);

// Ember tells us not to create new global variables, because App is already one
// I say we should create TWO global variables just because!
rp = {
	// log(str1, str2, ...)
	// Logs any amount of variables into the server log (prefixed by [JS])
	log : function() { 
		var args = Array.prototype.slice.call(arguments);
		for (var i = 0; i < args.length; ++i)
		{
			var type = typeof(args[i]);
			
			if (type == 'function')
				args[i] = '(JS function)';
			else if (type == 'object')
			{
				if (args[i] instanceof jQuery)
					args[i] = '(jQuery object)';
				else
					args[i] = dump(args[i]);
			}
			else if (type == 'number')
				args[i] = args[i].toString(); // to deal with NaN and other weirdos; perhaps apply to all elses?
		}
		
		return old_callv('rp:log_server', args).deferred; 
	},
	
	// Call proxies: callName => redirectFunction
	_callProxies : {},
		
	// List of mods that have been registered, modName => modClass
	_mods : {},
	
	// Data for the start menu, if any
	_startMenuData : [],
	
	// dump(obj)
	// returns a (dumped) string that is obj.
	dump : dump,
	
	// setCallProxy(callName, func): redirects all radiant.call(callName) to func; allowing you to return different stuff or mess around altogether.
	setCallProxy : function(callName, func) { this._callProxies[callName] = func; },
	
	// registerMod(modName, modClass): registers said mod with RP for initialisation
	registerMod : function(modName, modClass) { this._mods[modName] = modClass; },
	
	// addToStartMenu(array data): Adds stuff to the start menu
	addToStartMenu : function(data)
	{
		if (!(data instanceof Array))
			throw "rp.addToStartMenu expects an array as first argument.";
		else if (rp._startMenuData == null)
			App.StonehearthStartMenu.rp_insertElements(data, true);
		else
			rp._startMenuData = rp._startMenuData.concat(data);
	}
}

// Now to some magic.
// Patch radiant.callv (which is used by radiant.call, so we get both!)
radiant.callv = function(fn, args)
{
	if (rp._callProxies[fn] != null)
	{
		return rp._callProxies[fn].apply(null, args);
	}
	
	return old_callv(fn, args);
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