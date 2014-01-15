App.StonehearthShellView = App.ContainerView.extend({
	init: function() {
		this._super();
		
    var self = this;
		
		this.addView(App.RPLoadingScreenView);
		App.gotoTitle = function() { self.gotoTitle(); }
	},
	 
	 
	 // Whatever was past "this._super" in the old view
	 _rp_oldInit : function() {
		var self = this;
		 
		var json = {
			views : [
				"StonehearthTitleScreenView"
			]
		};

		var views = json.views || [];
		$.each(views, function(i, name) {
			console.log(name);
			var ctor = App[name]
			if (ctor) {
				self.addView(ctor);
			}
		});
	},
	
	gotoTitle : function() {
		this._rp_oldInit();
		App.gotoTitle = null; // we don't want anyone to get crazy ideas
	}
});

App.RootView = App.RootView.extend({
	init : function()
	{
		this._super();
	},
	
	gotoShell : function()
	{
		rp.log('TODO xxxx: Redo this better. PROPERLY.');
		//~ this._super();
	}
});

App.gotoGame = function() {
}

App.gotoShell = function() {
}