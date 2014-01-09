var menuExtraData = [];
	
// rp.add_to_start_menu([]):
/**
Example data:
[
	{
		name : "Bleigh",
		hotkey: "g",
		icon: "/stonehearth/ui/game/start_menu/images/chop_trees.png",
		
		elements :
		[
			{
				name : "Chop 1",
				hotkey : "1",
				icon : "/stonehearth/ui/game/start_menu/images/chop_trees.png",
				click: function() { rp.log("Bleigh/Chop 1 was pressed!"); }
			},
			
			{
				name : "Chop 2",
				hotkey: "2",
				icon: "/stonehearth/ui/game/start_menu/images/chop_trees.png",
				click: function() { rp.log("Bleigh/Chop 2 was pressed!"); }
			},
			
			{
				name : "Empty Chop. :(",
				hotkey: "3",
				click: function() { rp.log("Bleigh/Empty Chop was pressed!"); }
			},
			
			{
				name: "Lonely Chop",
				click: function() { rp.log("Bleigh/Loneley chop was pressed. :)"); }
			},
			
			{
				name : "Deeper",
				
				elements: [
					{
						name: "Welcome to limbo!",
						click: function() { rp.log("You can't get out."); return false; }
					}
				]
			}
		]
	},
	{
		name: "Build",
		elements : [
			{
				name : "Hellou!",
				hotkey: "h",
				click: function() { rp.log("hellou!"); }
			}
		],
	}
];
*/
rp.add_to_start_menu = function(data)
{
	if (menuExtraData == null)
		throw "Cannot add stuff to the menu; menu was already created.";
	else if (!(data instanceof Array))
		throw "rp.add_to_start_menu expects an array as first argument.";
	
	menuExtraData = menuExtraData.concat(data);
}

// If anyone has a better idea as to how to get this done after the function has been defined - ring me up.
radiant.call('rp:init_server').done(function()
{
	App.StonehearthStartMenuView = App.StonehearthStartMenuView.extend({
		// Keeps track of our last id.
		rp_lastMenuId : 0,

		// Creates a new <li>, properly formatted to contain a new item.
		rp_createNewEntry : function(data)
		{
			// <li>
			var li = $('<li>');
			// <a> - our link
			var link = $('<a href="#">').attr('hotkey', data.hotkey);
			
			//~ // If a hotkey was defined, do it
			//~ if (data.hotkey != null)
				//~ link.attr('hotkey', data.hotkey);
			
			// If a click handler has been installed
			if (data.click != null)
			{
				var id = 'rpAction' + (++this.rp_lastMenuId);
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
		rp_insertElements : function(data, context)
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
					entry = self.rp_createNewEntry(item);
					context.append(entry);
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
					self.rp_insertElements(item.elements, subEntry);
				}
				
				// TODO: In case elements was not set, should we allow overwriting of stuff?
				// ... probably not? Yes? No? We'll see? We'll see. Demand and supply!
			});
		},
		
		// good ol' pseudo ctor
		didInsertElement : function()
		{
			var dlMenu = $('#startMenu .dl-menu').first();
			
			// Merge the json into the menu
			this.rp_insertElements(menuExtraData, dlMenu);
		
			// Make sure that calls become futile
			menuExtraData = null;
			
			// Now you can do whatever evil magic you do
			this._super();
		}
	});
});