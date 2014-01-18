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

// Dr. Breen approves of this HAAAX
App.StonehearthStartMenuView = App.StonehearthStartMenuView.extend({
	// Keeps track of our last id.
	_rp_lastMenuId : 0,
	
	// The object that we will (ab)use
	_rp_cloneWarrior : null,
	
	// Creates a new <li>, properly formatted to contain a new item.
	_rp_createNewEntry : function(data)
	{
		// <li>
		var li = $('<li>');
		// <a> - our link
		var link = $('<a href="#">').attr('hotkey', data.hotkey);
		
		// If a click handler has been installed
		if (data.click != null)
		{
			var id = 'rpAction' + (++this._rp_lastMenuId);
			link.attr('menuId', id);
			
			// Is it a call-command-ish table?
			if (typeof(data.click) == 'object')
			{
				// Check its type.
				if (data.click.action == "call")
				{
					var func = data.click["function"]; // brr?
					var args = data.click.args;
					data.click = function() { radiant.callv(func, args); };
				}
				else if (data.click.action == "fire_event")
				{
					var event_name = data.click.event_name;
					var event_data = data.click.event_data;
					data.click = function() { $(top).trigger(event_name, event_data); };
				}
			}
			
			this.menuActions[id] = { click : data.click };
		}
		
		// If an icon has been set
		if (data.icon != null)
		{
			var img = $('<img>').attr('src', data.icon);
			link.append(img);
		}
		
		link.append(data.name);
		li.append(link);
		
		return li;
	},

	// Tries to merge `data`into `context`, which should be some sort of ul.
	_rp_insertElements : function(data, context)
	{
		// suddenly, lots of Radiant's code becomes more clear
		var self = this;
		
		// For each element in data...
		$.each(data, function(_, item) {
			// Try to find our matching item (if we are to add stuff to it)
			var entry = null;
			
			// Search in our current context
			context.children('li').each(function(i, li) {
				// Check if the first a is (conveniently) called that
				if ($(li).children('a').first().text() == item.name)
				{
					entry = $(li);
					return false;
				}
			});
				
			// Does not exist yet? Alright, add it.
			if (entry == null)
			{
				entry = self._rp_createNewEntry(item);
				context.append(entry);
			}
			else
			{
				// The entry does exist. Need to update it?
				var a = entry.children('a');
				if (item.hotkey)
					a.first().attr('hotkey', item.hotkey);
				if (item.icon)
				{
					var img = a.children('img');
					if (img.length > 0) // image exists
						img.attr('src', item.icon);
					else // image does not exist
						a.prepend($('<img>').attr('src', item.icon)); // my god I'm LAZY
				}
			}
			
			// After this point, "entry" exists and, in the best case, did something!
			// But it might... have laid eggs. And we're out of flamethrowers.
			if (item.elements != null)
			{
				// Hooray!! HAHAHA!
				// Does entry already have a dl-submenu?
				var subEntry = entry.children('ul.dl-submenu');
				
				// I guess "no"
				if (subEntry.length == 0)
				{
					subEntry = $('<ul class="dl-submenu">');
					entry.append(subEntry);
				}
				else
					subEntry = subEntry.first();
				
				// Rinse and repeat until the stack can't handle it anymore.
				self._rp_insertElements(item.elements, subEntry);
			}
			
			// TODO: In case elements was not set, should we allow overwriting of stuff?
			// ... probably not? Yes? No? We'll see? We'll see. Demand and supply!
		});
	},
	
	// A straight rip-off from the base class' 
	_rp_rebuildMenu : function()
	{
		$('#startMenu').dlmenu({
			animationClasses : { 
				classin : 'dl-animate-in-sh', 
				classout : 'dl-animate-out-sh' 
			},
			onLinkClick : function( el, ev ) { 
				var menuId = $(el).find("a").attr('menuId');
				self.onMenuClick(menuId)
			}
		});
	},
	
	// Can be called by external functions to add data to the start menu.
	// "refresh" specifies whether the menu is to be rebuilt immediately (""~costly"")
	rp_insertElements : function(data, refresh)
	{
		this._rp_insertElements(data, $('.dl-menu', this._rp_cloneWarrior));
		
		// TODO xxxx: Perform this after X seconds to avoid multiple
		// rebuilds within ~the same time?
		if (refresh)
		{
			$('#startMenu').replaceWith(this._rp_cloneWarrior.clone());
			this._rp_rebuildMenu();
		}
	},
	
	// good ol' pseudo ctor
	didInsertElement : function()
	{
		// Don't operate on a copy yet
		this._rp_cloneWarrior = $('#startMenu');
		
		// Merge the data we have collected so far into the menu
		this.rp_insertElements(rp._startMenuData, false);
	
		// Backup the DOM so we can operate (and replace) on it later again
		this._rp_cloneWarrior = this._rp_cloneWarrior.clone();
		
		// Make sure that further data is not cached but immediately added
		rp._startMenuData = null;
		
		// Now you can do whatever evil magic you do
		this._super();
		
		// I'm quite sure we're allowed to do this. Should do this. Why not?
		App.StonehearthStartMenu = this;
	}
});